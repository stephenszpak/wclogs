defmodule WcLogs.Parser do
  @moduledoc """
  Parser for World of Warcraft combat logs.
  Handles parsing of MoP Classic combat log format.
  """

  alias WcLogs.Reports
  alias WcLogs.Reports.{Report, Encounter, Participant}

  @doc """
  Parses a combat log file and stores the data in the database.
  """
  def parse_file(file_path, filename, uploaded_by \\ "anonymous") do
    with {:ok, report} <- create_report(filename, uploaded_by),
         {:ok, parsed_data} <- parse_log_file(file_path),
         {:ok, _encounters} <- store_encounters(report, parsed_data) do
      {:ok, report}
    else
      error -> error
    end
  end

  defp create_report(filename, uploaded_by) do
    Reports.create_report(%{
      filename: filename,
      uploaded_by: uploaded_by
    })
  end

  defp parse_log_file(file_path) do
    encounters = %{}
    participants = %{}
    
    result = File.stream!(file_path)
    |> Stream.with_index()
    |> Enum.reduce({encounters, participants}, fn {line, _index}, {enc_acc, part_acc} ->
      parse_line(String.trim(line), enc_acc, part_acc)
    end)
    
    {:ok, result}
  rescue
    error -> {:error, "Failed to parse file: #{inspect(error)}"}
  end

  defp parse_line(line, encounters, participants) do
    case parse_combat_log_line(line) do
      {:encounter_start, data} ->
        {add_encounter_start(encounters, data), participants}
      
      {:encounter_end, data} ->
        {add_encounter_end(encounters, data), participants}
      
      {:combat_event, event_data} ->
        {encounters, process_combat_event(participants, event_data)}
      
      {:combatant_info, combatant_data} ->
        {encounters, add_combatant_info(participants, combatant_data)}
      
      :ignore ->
        {encounters, participants}
    end
  end

  defp parse_combat_log_line(line) do
    # Parse timestamp and event
    case Regex.run(~r/^(\d{1,2}\/\d{1,2}\/\d{4} \d{1,2}:\d{1,2}:\d{1,2}\.\d{3}) {2}(.+)$/, line) do
      [_, timestamp_str, event_data] ->
        timestamp = parse_timestamp(timestamp_str)
        parse_event(event_data, timestamp)
      
      _ ->
        :ignore
    end
  end

  defp parse_timestamp(timestamp_str) do
    # Parse MM/DD/YYYY HH:MM:SS.mmm format
    case Regex.run(~r/^(\d{1,2})\/(\d{1,2})\/(\d{4}) (\d{1,2}):(\d{1,2}):(\d{1,2})\.(\d{3})$/, timestamp_str) do
      [_, month, day, year, hour, minute, second, millisecond] ->
        {:ok, datetime} = NaiveDateTime.new(
          String.to_integer(year),
          String.to_integer(month),
          String.to_integer(day),
          String.to_integer(hour),
          String.to_integer(minute),
          String.to_integer(second),
          {String.to_integer(millisecond) * 1000, 3}
        )
        DateTime.from_naive!(datetime, "Etc/UTC")
      
      _ ->
        DateTime.utc_now()
    end
  end

  defp parse_event(event_data, timestamp) do
    # Split by comma but respect quoted strings
    fields = parse_csv_line(event_data)
    
    case List.first(fields) do
      "ENCOUNTER_START" ->
        parse_encounter_start(fields, timestamp)
      
      "ENCOUNTER_END" ->
        parse_encounter_end(fields, timestamp)
      
      "COMBATANT_INFO" ->
        parse_combatant_info(fields, timestamp)
      
      event_type when event_type in ["SPELL_DAMAGE", "SPELL_PERIODIC_DAMAGE", "RANGE_DAMAGE", "SWING_DAMAGE"] ->
        parse_damage_event(fields, timestamp, event_type)
      
      event_type when event_type in ["SPELL_HEAL", "SPELL_PERIODIC_HEAL"] ->
        parse_heal_event(fields, timestamp, event_type)
      
      "UNIT_DIED" ->
        parse_death_event(fields, timestamp)
      
      _ ->
        :ignore
    end
  end

  defp parse_csv_line(line) do
    # Simple CSV parser that handles quoted strings
    line
    |> String.split(",")
    |> Enum.map(&String.trim/1)
    |> Enum.map(fn field ->
      if String.starts_with?(field, "\"") and String.ends_with?(field, "\"") do
        String.slice(field, 1..-2)
      else
        field
      end
    end)
  end

  defp parse_encounter_start(fields, timestamp) do
    # ENCOUNTER_START,encounterID,encounterName,difficultyID,raidSize
    case fields do
      ["ENCOUNTER_START", encounter_id, encounter_name | _] ->
        {:encounter_start, %{
          encounter_id: String.to_integer(encounter_id),
          boss_name: encounter_name,
          start_time: timestamp
        }}
      _ ->
        :ignore
    end
  end

  defp parse_encounter_end(fields, timestamp) do
    # ENCOUNTER_END,encounterID,encounterName,difficultyID,raidSize,success
    case fields do
      ["ENCOUNTER_END", encounter_id, encounter_name, _difficulty, _raid_size, success | _] ->
        {:encounter_end, %{
          encounter_id: String.to_integer(encounter_id),
          boss_name: encounter_name,
          end_time: timestamp,
          success: success == "1"
        }}
      _ ->
        :ignore
    end
  end

  defp parse_combatant_info(fields, _timestamp) do
    # COMBATANT_INFO,playerGUID,faction,strength,agility,stamina,intellect,spirit,...
    case fields do
      ["COMBATANT_INFO", guid | stats] when length(stats) >= 1 ->
        # Extract class and spec info if available (usually in later fields)
        item_level = extract_item_level(stats)
        
        {:combatant_info, %{
          guid: guid,
          item_level: item_level
        }}
      _ ->
        :ignore
    end
  end

  defp extract_item_level(stats) do
    # Item level is typically near the end of COMBATANT_INFO
    # This is a simplified extraction - real logs have more complex structure
    Enum.find_value(stats, fn stat ->
      case Integer.parse(stat) do
        {ilvl, ""} when ilvl > 200 and ilvl < 1000 -> ilvl
        _ -> nil
      end
    end)
  end

  defp parse_damage_event(fields, _timestamp, _event_type) do
    # sourceGUID,sourceName,sourceFlags,sourceRaidFlags,destGUID,destName,destFlags,destRaidFlags,spellId,spellName,spellSchool,amount,overkill,school,resisted,blocked,absorbed,critical,glancing,crushing
    case fields do
      [_event, source_guid, source_name, _source_flags, _source_raid_flags, 
       dest_guid, dest_name, _dest_flags, _dest_raid_flags | damage_data] ->
        
        amount = extract_damage_amount(damage_data)
        
        {:combat_event, %{
          type: :damage,
          source_guid: source_guid,
          source_name: source_name,
          dest_guid: dest_guid,
          dest_name: dest_name,
          amount: amount
        }}
      _ ->
        :ignore
    end
  end

  defp parse_heal_event(fields, _timestamp, _event_type) do
    case fields do
      [_event, source_guid, source_name, _source_flags, _source_raid_flags,
       dest_guid, dest_name, _dest_flags, _dest_raid_flags | heal_data] ->
        
        amount = extract_heal_amount(heal_data)
        
        {:combat_event, %{
          type: :heal,
          source_guid: source_guid,
          source_name: source_name,
          dest_guid: dest_guid,
          dest_name: dest_name,
          amount: amount
        }}
      _ ->
        :ignore
    end
  end

  defp parse_death_event(fields, _timestamp) do
    case fields do
      [_event, _source_guid, _source_name, _source_flags, _source_raid_flags,
       dest_guid, dest_name | _] ->
        
        {:combat_event, %{
          type: :death,
          dest_guid: dest_guid,
          dest_name: dest_name
        }}
      _ ->
        :ignore
    end
  end

  defp extract_damage_amount(damage_data) do
    # Amount is typically the first numeric field after spell info
    case damage_data do
      [_spell_id, _spell_name, _spell_school, amount_str | _] ->
        case Integer.parse(amount_str) do
          {amount, _} -> amount
          _ -> 0
        end
      _ -> 0
    end
  end

  defp extract_heal_amount(heal_data) do
    case heal_data do
      [_spell_id, _spell_name, _spell_school, amount_str | _] ->
        case Integer.parse(amount_str) do
          {amount, _} -> amount
          _ -> 0
        end
      _ -> 0
    end
  end

  defp add_encounter_start(encounters, data) do
    encounter_id = data.encounter_id
    Map.put(encounters, encounter_id, data)
  end

  defp add_encounter_end(encounters, data) do
    encounter_id = data.encounter_id
    case Map.get(encounters, encounter_id) do
      nil -> encounters
      encounter_start ->
        duration_ms = DateTime.diff(data.end_time, encounter_start.start_time, :millisecond)
        updated_encounter = encounter_start
        |> Map.merge(data)
        |> Map.put(:duration_ms, duration_ms)
        
        Map.put(encounters, encounter_id, updated_encounter)
    end
  end

  defp process_combat_event(participants, event_data) do
    case event_data.type do
      :damage ->
        update_participant_damage(participants, event_data)
      :heal ->
        update_participant_healing(participants, event_data)
      :death ->
        update_participant_death(participants, event_data)
    end
  end

  defp update_participant_damage(participants, event_data) do
    source_key = {event_data.source_guid, event_data.source_name}
    dest_key = {event_data.dest_guid, event_data.dest_name}
    
    participants
    |> update_participant_stat(source_key, :total_damage_done, event_data.amount)
    |> update_participant_stat(dest_key, :total_damage_taken, event_data.amount)
  end

  defp update_participant_healing(participants, event_data) do
    source_key = {event_data.source_guid, event_data.source_name}
    
    update_participant_stat(participants, source_key, :total_healing_done, event_data.amount)
  end

  defp update_participant_death(participants, event_data) do
    dest_key = {event_data.dest_guid, event_data.dest_name}
    
    update_participant_stat(participants, dest_key, :deaths, 1)
  end

  defp update_participant_stat(participants, {guid, name}, stat, amount) do
    Map.update(participants, {guid, name}, %{
      guid: guid,
      name: name,
      stat => amount
    }, fn participant ->
      Map.update(participant, stat, amount, &(&1 + amount))
    end)
  end

  defp add_combatant_info(participants, combatant_data) do
    guid = combatant_data.guid
    
    # Find participant by GUID and update with combatant info
    Enum.reduce(participants, participants, fn {{p_guid, name}, participant}, acc ->
      if p_guid == guid do
        updated_participant = Map.merge(participant, combatant_data)
        Map.put(acc, {p_guid, name}, updated_participant)
      else
        acc
      end
    end)
  end

  defp store_encounters(report, {encounters, participants}) do
    Enum.reduce_while(encounters, {:ok, []}, fn {_id, encounter_data}, {:ok, acc} ->
      case create_encounter_with_participants(report, encounter_data, participants) do
        {:ok, encounter} -> {:cont, {:ok, [encounter | acc]}}
        error -> {:halt, error}
      end
    end)
  end

  defp create_encounter_with_participants(report, encounter_data, participants) do
    encounter_attrs = Map.put(encounter_data, :report_id, report.id)
    
    case Reports.create_encounter(encounter_attrs) do
      {:ok, encounter} ->
        participant_records = create_participant_records(encounter, participants, encounter_data)
        {:ok, encounter}
      
      error ->
        error
    end
  end

  defp create_participant_records(encounter, participants, encounter_data) do
    duration_seconds = if encounter_data[:duration_ms], do: encounter_data.duration_ms / 1000.0, else: 1.0
    
    participant_data = participants
    |> Enum.map(fn {{guid, name}, stats} ->
      dps = if duration_seconds > 0, do: (stats[:total_damage_done] || 0) / duration_seconds, else: 0.0
      hps = if duration_seconds > 0, do: (stats[:total_healing_done] || 0) / duration_seconds, else: 0.0
      
      %{
        encounter_id: encounter.id,
        guid: guid,
        name: name,
        total_damage_done: stats[:total_damage_done] || 0,
        total_healing_done: stats[:total_healing_done] || 0,
        total_damage_taken: stats[:total_damage_taken] || 0,
        dps: Float.round(dps, 2),
        hps: Float.round(hps, 2),
        deaths: stats[:deaths] || 0,
        item_level: stats[:item_level],
        inserted_at: DateTime.utc_now(),
        updated_at: DateTime.utc_now()
      }
    end)
    
    if length(participant_data) > 0 do
      Reports.create_participants(participant_data)
    else
      {:ok, []}
    end
  end
end