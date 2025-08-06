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
    require Logger
    Logger.info("Starting to parse file: #{filename}, size: #{File.stat!(file_path).size} bytes")
    
    with {:ok, report} <- create_report(filename, uploaded_by),
         {:ok, parsed_data} <- parse_log_file(file_path),
         {:ok, _encounters} <- store_encounters(report, parsed_data) do
      Logger.info("Successfully parsed file: #{filename}")
      {:ok, report}
    else
      error -> 
        Logger.error("Failed to parse file: #{filename}, error: #{inspect(error)}")
        error
    end
  end

  defp create_report(filename, uploaded_by) do
    Reports.create_report(%{
      filename: filename,
      uploaded_by: uploaded_by
    })
  end

  defp parse_log_file(file_path) do
    require Logger
    encounters = %{}
    participants = %{}
    line_count = 0
    encounter_lines = 0
    
    result = File.stream!(file_path)
    |> Stream.with_index()
    |> Enum.reduce({encounters, participants, line_count, encounter_lines}, fn {line, index}, {enc_acc, part_acc, lines, enc_lines} ->
      trimmed_line = String.trim(line)
      
      # Log first few lines and some sample lines for debugging
      if index < 5 do
        Logger.info("Sample line #{index}: #{String.slice(trimmed_line, 0, 200)}")
      end
      
      # Count encounter-related lines
      new_enc_lines = if String.contains?(trimmed_line, "ENCOUNTER") do
        enc_lines + 1
      else
        enc_lines
      end
      
      {new_enc, new_part} = parse_line(trimmed_line, enc_acc, part_acc)
      {new_enc, new_part, lines + 1, new_enc_lines}
    end)
    
    {encounters, participants, total_lines, encounter_line_count} = result
    Logger.info("Parsed #{total_lines} lines, found #{encounter_line_count} encounter-related lines")
    Logger.info("Found #{map_size(encounters)} encounters, #{map_size(participants)} participants")
    
    {:ok, {encounters, participants}}
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
    # Try multiple timestamp formats common in WoW logs
    cond do
      # Format: MM/DD/YYYY HH:MM:SS.mmm-TZ  EVENT_DATA (MoP Classic format)
      match = Regex.run(~r/^(\d{1,2}\/\d{1,2}\/\d{4} \d{1,2}:\d{1,2}:\d{1,2}\.\d{3}[-+]\d+) {1,}(.+)$/, line) ->
        [_, timestamp_str, event_data] = match
        timestamp = parse_timestamp_with_tz(timestamp_str)
        parse_event(event_data, timestamp)
      
      # Format: MM/DD/YYYY HH:MM:SS.mmm  EVENT_DATA (standard)
      match = Regex.run(~r/^(\d{1,2}\/\d{1,2}\/\d{4} \d{1,2}:\d{1,2}:\d{1,2}\.\d{3}) {2}(.+)$/, line) ->
        [_, timestamp_str, event_data] = match
        timestamp = parse_timestamp(timestamp_str)
        parse_event(event_data, timestamp)
      
      # Format: MM/DD YYYY HH:MM:SS.mmm  EVENT_DATA (alternative)
      match = Regex.run(~r/^(\d{1,2}\/\d{1,2} \d{4} \d{1,2}:\d{1,2}:\d{1,2}\.\d{3}) {1,}(.+)$/, line) ->
        [_, timestamp_str, event_data] = match
        timestamp = parse_timestamp_alt(timestamp_str)
        parse_event(event_data, timestamp)
      
      # Format: Just event data without timestamp (some logs)
      String.contains?(line, "ENCOUNTER_START") or String.contains?(line, "ENCOUNTER_END") ->
        parse_event(line, DateTime.utc_now())
      
      true ->
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

  defp parse_timestamp_alt(timestamp_str) do
    # Parse MM/DD YYYY HH:MM:SS.mmm format
    case Regex.run(~r/^(\d{1,2})\/(\d{1,2}) (\d{4}) (\d{1,2}):(\d{1,2}):(\d{1,2})\.(\d{3})$/, timestamp_str) do
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

  defp parse_timestamp_with_tz(timestamp_str) do
    # Parse MM/DD/YYYY HH:MM:SS.mmm-TZ format (e.g., "8/2/2025 19:53:15.877-5")
    case Regex.run(~r/^(\d{1,2})\/(\d{1,2})\/(\d{4}) (\d{1,2}):(\d{1,2}):(\d{1,2})\.(\d{3})[-+](\d+)$/, timestamp_str) do
      [_, month, day, year, hour, minute, second, millisecond, _tz] ->
        # For simplicity, we'll ignore timezone and parse as UTC
        # In production, you might want to handle timezone properly
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
    # Group pets/minions with their owners and separate players from bosses
    source_key = get_participant_key(event_data.source_guid, event_data.source_name)
    dest_key = get_participant_key(event_data.dest_guid, event_data.dest_name)
    
    participants = case source_key do
      {:player, key} -> update_participant_stat(participants, key, :total_damage_done, event_data.amount)
      {:boss, key} -> update_boss_stat(participants, key, :total_damage_done, event_data.amount)
      _ -> participants
    end
    
    case dest_key do
      {:player, key} -> update_participant_stat(participants, key, :total_damage_taken, event_data.amount)
      {:boss, key} -> update_boss_stat(participants, key, :total_damage_taken, event_data.amount)
      _ -> participants
    end
  end

  defp update_participant_healing(participants, event_data) do
    source_key = get_participant_key(event_data.source_guid, event_data.source_name)
    
    case source_key do
      {:player, key} -> update_participant_stat(participants, key, :total_healing_done, event_data.amount)
      {:boss, key} -> update_boss_stat(participants, key, :total_healing_done, event_data.amount)
      _ -> participants
    end
  end

  defp update_participant_death(participants, event_data) do
    dest_key = get_participant_key(event_data.dest_guid, event_data.dest_name)
    
    case dest_key do
      {:player, key} -> update_participant_stat(participants, key, :deaths, 1)
      {:boss, key} -> update_boss_stat(participants, key, :deaths, 1)
      _ -> participants
    end
  end

  # Determine if an entity is a player or boss and get the appropriate key
  defp get_participant_key(guid, name) do
    cond do
      is_player?(guid, name) -> {:player, get_player_key(guid, name)}
      is_boss?(guid, name) -> {:boss, {guid, name}}
      true -> :unknown
    end
  end
  
  # Identify players (including pets/minions) vs bosses
  defp is_player?(guid, name) do
    # Player GUIDs typically start with "Player-" or contain server names
    # Pets often have names like "Pet-X-Y" or contain the owner's name
    cond do
      String.starts_with?(guid, "Player-") -> true
      String.contains?(name, "-") && String.contains?(name, "US") -> true
      String.contains?(name, "-") && String.contains?(name, "EU") -> true
      is_pet_or_minion?(guid, name) -> true
      true -> false
    end
  end
  
  defp is_boss?(guid, name) do
    # Boss GUIDs typically start with "Creature-" and don't have server suffixes
    cond do
      String.starts_with?(guid, "Creature-") && !is_pet_or_minion?(guid, name) -> true
      String.starts_with?(guid, "Vehicle-") -> true
      true -> false
    end
  end
  
  defp is_pet_or_minion?(guid, name) do
    # Common pet/minion patterns in WoW logs
    String.contains?(guid, "Pet-") or
    String.contains?(name, " <") or  # Pet names often have brackets
    String.contains?(name, "Minion") or
    String.contains?(name, "Totem") or
    String.contains?(name, "Spirit") or
    String.contains?(name, "Elemental")
  end
  
  # Get the main player key, grouping pets with their owners
  defp get_player_key(guid, name) do
    if is_pet_or_minion?(guid, name) do
      # Try to extract owner name from pet name or use a generic grouping
      owner_name = extract_owner_name(name)
      {generate_owner_guid(owner_name), owner_name}
    else
      {guid, normalize_player_name(name)}
    end
  end
  
  defp extract_owner_name(pet_name) do
    # Extract owner name from pet names like "Spirit Wolf <PlayerName>"
    case Regex.run(~r/<(.+)>/, pet_name) do
      [_, owner] -> normalize_player_name(owner)
      _ -> 
        # If no brackets, try to guess from the first word
        case String.split(pet_name, " ") do
          [first_word | _] when byte_size(first_word) > 2 -> 
            normalize_player_name(first_word)
          _ -> "Unknown"
        end
    end
  end
  
  defp normalize_player_name(name) do
    # Ensure player names follow PlayerName-Server-Region format
    cond do
      String.contains?(name, "-") -> name
      true -> "#{name}-Unknown-US"  # Default format if no server info
    end
  end
  
  defp generate_owner_guid(owner_name) do
    "Player-Generated-#{owner_name}"
  end
  
  defp update_boss_stat(participants, {guid, name}, stat, amount) do
    # Store boss stats separately from players
    boss_key = {:boss, guid, name}
    initial_stats = %{
      guid: guid,
      name: name,
      type: :boss
    }
    |> Map.put(stat, amount)
    
    Map.update(participants, boss_key, initial_stats, fn participant ->
      Map.update(participant, stat, amount, &(&1 + amount))
    end)
  end

  defp update_participant_stat(participants, {guid, name}, stat, amount) do
    initial_stats = %{
      guid: guid,
      name: name,
      type: :player
    }
    |> Map.put(stat, amount)
    
    Map.update(participants, {guid, name}, initial_stats, fn participant ->
      Map.update(participant, stat, amount, &(&1 + amount))
    end)
  end

  defp add_combatant_info(participants, combatant_data) do
    guid = combatant_data.guid
    
    # Find participant by GUID and update with combatant info
    Enum.reduce(participants, participants, fn
      # Handle player participants
      {{p_guid, name}, participant}, acc ->
        if p_guid == guid do
          updated_participant = Map.merge(participant, combatant_data)
          Map.put(acc, {p_guid, name}, updated_participant)
        else
          acc
        end
      
      # Handle boss participants  
      {{:boss, p_guid, name}, participant}, acc ->
        if p_guid == guid do
          updated_participant = Map.merge(participant, combatant_data)
          Map.put(acc, {:boss, p_guid, name}, updated_participant)
        else
          acc
        end
      
      # Handle any other key format
      {_key, _participant}, acc ->
        acc
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
    
    # Separate players and bosses
    {players, bosses} = separate_participants(participants)
    
    # Create player records
    player_data = players
    |> Enum.map(fn {{guid, name}, stats} ->
      dps = if duration_seconds > 0, do: (stats[:total_damage_done] || 0) / duration_seconds, else: 0.0
      hps = if duration_seconds > 0, do: (stats[:total_healing_done] || 0) / duration_seconds, else: 0.0
      
      %{
        encounter_id: encounter.id,
        guid: guid,
        name: name,
        participant_type: "player",
        total_damage_done: stats[:total_damage_done] || 0,
        total_healing_done: stats[:total_healing_done] || 0,
        total_damage_taken: stats[:total_damage_taken] || 0,
        dps: Float.round(dps, 2),
        hps: Float.round(hps, 2),
        deaths: stats[:deaths] || 0,
        item_level: stats[:item_level],
        inserted_at: DateTime.utc_now() |> DateTime.truncate(:second),
        updated_at: DateTime.utc_now() |> DateTime.truncate(:second)
      }
    end)
    
    # Create boss records  
    boss_data = bosses
    |> Enum.map(fn {{:boss, guid, name}, stats} ->
      dps = if duration_seconds > 0, do: (stats[:total_damage_done] || 0) / duration_seconds, else: 0.0
      hps = if duration_seconds > 0, do: (stats[:total_healing_done] || 0) / duration_seconds, else: 0.0
      
      %{
        encounter_id: encounter.id,
        guid: guid,
        name: name,
        participant_type: "boss",
        total_damage_done: stats[:total_damage_done] || 0,
        total_healing_done: stats[:total_healing_done] || 0,
        total_damage_taken: stats[:total_damage_taken] || 0,
        dps: Float.round(dps, 2),
        hps: Float.round(hps, 2),
        deaths: stats[:deaths] || 0,
        item_level: nil,
        inserted_at: DateTime.utc_now() |> DateTime.truncate(:second),
        updated_at: DateTime.utc_now() |> DateTime.truncate(:second)
      }
    end)
    
    all_data = player_data ++ boss_data
    
    if length(all_data) > 0 do
      Reports.create_participants(all_data)
    else
      {:ok, []}
    end
  end
  
  defp separate_participants(participants) do
    Enum.split_with(participants, fn
      {{_guid, _name}, stats} -> Map.get(stats, :type) == :player
      {{:boss, _guid, _name}, _stats} -> false
      _ -> true
    end)
  end
end