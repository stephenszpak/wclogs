import React, { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { reportService } from '../services/api';

const EncounterView = () => {
  const { reportId, encounterId } = useParams();
  const navigate = useNavigate();
  const [encounter, setEncounter] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [activeTab, setActiveTab] = useState('damage');

  useEffect(() => {
    loadEncounter();
  }, [reportId, encounterId]);

  const loadEncounter = async () => {
    try {
      setLoading(true);
      const response = await reportService.getEncounter(reportId, encounterId);
      setEncounter(response.data);
    } catch (err) {
      console.error('Error loading encounter:', err);
      setError('Failed to load encounter');
    } finally {
      setLoading(false);
    }
  };

  const formatNumber = (num) => {
    if (!num) return '0';
    return num.toLocaleString();
  };

  const formatDate = (dateString) => {
    if (!dateString) return 'Unknown';
    return new Date(dateString).toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
      second: '2-digit'
    });
  };

  const formatDuration = (durationMs) => {
    if (!durationMs) return 'Unknown';
    const minutes = Math.floor(durationMs / 60000);
    const seconds = Math.floor((durationMs % 60000) / 1000);
    return `${minutes}m ${seconds}s`;
  };

  const calculatePercentage = (value, total) => {
    if (!total || total === 0) return 0;
    return Math.round((value / total) * 100);
  };

  const renderParticipantsTable = (participants, type) => {
    if (!participants || participants.length === 0) {
      return <p>No data available.</p>;
    }

    const totalDamage = participants.reduce((sum, p) => sum + (p.total_damage_done || 0), 0);
    const totalHealing = participants.reduce((sum, p) => sum + (p.total_healing_done || 0), 0);

    return (
      <table className="participants-table">
        <thead>
          <tr>
            <th>Name</th>
            <th>Class</th>
            {type === 'damage' && (
              <>
                <th>Total Damage</th>
                <th>DPS</th>
                <th>% of Total</th>
              </>
            )}
            {type === 'healing' && (
              <>
                <th>Total Healing</th>
                <th>HPS</th>
                <th>% of Total</th>
              </>
            )}
            {type === 'overview' && (
              <>
                <th>Damage Done</th>
                <th>Healing Done</th>
                <th>Damage Taken</th>
                <th>Deaths</th>
              </>
            )}
            <th>Item Level</th>
          </tr>
        </thead>
        <tbody>
          {participants.map((participant, index) => {
            const damagePercent = calculatePercentage(participant.total_damage_done, totalDamage);
            const healingPercent = calculatePercentage(participant.total_healing_done, totalHealing);
            
            return (
              <tr key={participant.id || index}>
                <td>
                  <div className="participant-name">{participant.name}</div>
                </td>
                <td>
                  <div className="participant-class">{participant.class || 'Unknown'}</div>
                  {participant.spec && <div className="participant-spec">{participant.spec}</div>}
                </td>
                {type === 'damage' && (
                  <>
                    <td>
                      <div className="number-large">{formatNumber(participant.total_damage_done)}</div>
                      <div className="damage-bar">
                        <div 
                          className="damage-bar-fill" 
                          style={{ width: `${damagePercent}%` }}
                        />
                      </div>
                    </td>
                    <td className="number-large">{formatNumber(Math.round(participant.dps || 0))}</td>
                    <td className="number-small">{damagePercent}%</td>
                  </>
                )}
                {type === 'healing' && (
                  <>
                    <td>
                      <div className="number-large">{formatNumber(participant.total_healing_done)}</div>
                      <div className="damage-bar">
                        <div 
                          className="damage-bar-fill heal-bar-fill" 
                          style={{ width: `${healingPercent}%` }}
                        />
                      </div>
                    </td>
                    <td className="number-large">{formatNumber(Math.round(participant.hps || 0))}</td>
                    <td className="number-small">{healingPercent}%</td>
                  </>
                )}
                {type === 'overview' && (
                  <>
                    <td className="number-small">{formatNumber(participant.total_damage_done)}</td>
                    <td className="number-small">{formatNumber(participant.total_healing_done)}</td>
                    <td className="number-small">{formatNumber(participant.total_damage_taken)}</td>
                    <td className="number-small">{participant.deaths || 0}</td>
                  </>
                )}
                <td className="number-small">{participant.item_level || 'N/A'}</td>
              </tr>
            );
          })}
        </tbody>
      </table>
    );
  };

  if (loading) return <div className="loading">Loading encounter...</div>;
  if (error) return <div className="error">{error}</div>;
  if (!encounter) return <div className="error">Encounter not found</div>;

  const participants = encounter.participants || { damage: [], healing: [], all: [] };

  return (
    <div>
      <button className="back-button" onClick={() => navigate(`/reports/${reportId}`)}>
        ← Back to Report
      </button>
      
      <div className="encounter-header">
        <div>
          <h2>{encounter.boss_name}</h2>
          <div className={`encounter-status ${encounter.success ? 'success' : 'wipe'}`}>
            {encounter.success ? 'Kill' : 'Wipe'}
          </div>
        </div>
      </div>
      
      <div className="encounter-meta">
        <p><strong>Start Time:</strong> {formatDate(encounter.start_time)}</p>
        <p><strong>Duration:</strong> {formatDuration(encounter.duration_ms)}</p>
        {encounter.zone_name && <p><strong>Zone:</strong> {encounter.zone_name}</p>}
        {encounter.difficulty && <p><strong>Difficulty:</strong> {encounter.difficulty}</p>}
      </div>

      <div className="participants-section">
        <div className="participants-tabs">
          <button
            className={`tab-button ${activeTab === 'damage' ? 'active' : ''}`}
            onClick={() => setActiveTab('damage')}
          >
            Damage Done ({participants.damage.length})
          </button>
          <button
            className={`tab-button ${activeTab === 'healing' ? 'active' : ''}`}
            onClick={() => setActiveTab('healing')}
          >
            Healing Done ({participants.healing.length})
          </button>
          <button
            className={`tab-button ${activeTab === 'overview' ? 'active' : ''}`}
            onClick={() => setActiveTab('overview')}
          >
            Overview ({participants.all.length})
          </button>
        </div>

        <div className="tab-content">
          {activeTab === 'damage' && renderParticipantsTable(participants.damage, 'damage')}
          {activeTab === 'healing' && renderParticipantsTable(participants.healing, 'healing')}
          {activeTab === 'overview' && renderParticipantsTable(participants.all, 'overview')}
        </div>
      </div>
    </div>
  );
};

export default EncounterView;