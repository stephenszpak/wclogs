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
  const [sortConfig, setSortConfig] = useState({ key: 'total_damage_done', direction: 'desc' });
  const [filterText, setFilterText] = useState('');

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

  const getClassColor = (className) => {
    const classColors = {
      'Death Knight': '#C41E3A',
      'Demon Hunter': '#A330C9', 
      'Druid': '#FF7C0A',
      'Hunter': '#AAD372',
      'Mage': '#3FC7EB',
      'Monk': '#00FF98',
      'Paladin': '#F48CBA',
      'Priest': '#FFFFFF',
      'Rogue': '#FFF468',
      'Shaman': '#0070DD',
      'Warlock': '#8788EE',
      'Warrior': '#C69B6D'
    };
    
    return classColors[className] || '#6c757d';
  };

  const handleSort = (key) => {
    let direction = 'desc';
    if (sortConfig.key === key && sortConfig.direction === 'desc') {
      direction = 'asc';
    }
    setSortConfig({ key, direction });
  };

  const getFilteredAndSortedParticipants = (participants) => {
    // First apply filtering
    let filtered = participants;
    if (filterText.trim()) {
      const filter = filterText.toLowerCase().trim();
      filtered = participants.filter(participant => 
        participant.name?.toLowerCase().includes(filter) ||
        participant.class?.toLowerCase().includes(filter) ||
        participant.spec?.toLowerCase().includes(filter)
      );
    }
    
    // Then apply sorting
    if (!sortConfig.key) return filtered;
    
    return [...filtered].sort((a, b) => {
      let aValue = a[sortConfig.key];
      let bValue = b[sortConfig.key];
      
      // Handle different data types
      if (typeof aValue === 'string') {
        aValue = aValue.toLowerCase();
        bValue = bValue?.toLowerCase() || '';
      } else if (typeof aValue === 'number' || aValue === null || aValue === undefined) {
        aValue = aValue || 0;
        bValue = bValue || 0;
      }
      
      if (sortConfig.direction === 'asc') {
        return aValue < bValue ? -1 : aValue > bValue ? 1 : 0;
      } else {
        return aValue > bValue ? -1 : aValue < bValue ? 1 : 0;
      }
    });
  };

  const getSortIcon = (columnKey) => {
    if (sortConfig.key !== columnKey) {
      return <span className="sort-icon">↕</span>;
    }
    return sortConfig.direction === 'asc' ? 
      <span className="sort-icon active">↑</span> : 
      <span className="sort-icon active">↓</span>;
  };

  const renderParticipantsTable = (participants, type) => {
    if (!participants || participants.length === 0) {
      return <p>No data available.</p>;
    }

    const filteredAndSortedParticipants = getFilteredAndSortedParticipants(participants);
    const totalDamage = participants.reduce((sum, p) => sum + (p.total_damage_done || 0), 0);
    const totalHealing = participants.reduce((sum, p) => sum + (p.total_healing_done || 0), 0);

    return (
      <table className="participants-table">
        <thead>
          <tr>
            <th className="sortable" onClick={() => handleSort('name')}>
              Name {getSortIcon('name')}
            </th>
            <th className="sortable" onClick={() => handleSort('class')}>
              Class {getSortIcon('class')}
            </th>
            {type === 'damage' && (
              <>
                <th className="sortable" onClick={() => handleSort('total_damage_done')}>
                  Total Damage {getSortIcon('total_damage_done')}
                </th>
                <th className="sortable" onClick={() => handleSort('dps')}>
                  DPS {getSortIcon('dps')}
                </th>
                <th>% of Total</th>
              </>
            )}
            {type === 'healing' && (
              <>
                <th className="sortable" onClick={() => handleSort('total_healing_done')}>
                  Total Healing {getSortIcon('total_healing_done')}
                </th>
                <th className="sortable" onClick={() => handleSort('hps')}>
                  HPS {getSortIcon('hps')}
                </th>
                <th>% of Total</th>
              </>
            )}
            {type === 'overview' && (
              <>
                <th className="sortable" onClick={() => handleSort('total_damage_done')}>
                  Damage Done {getSortIcon('total_damage_done')}
                </th>
                <th className="sortable" onClick={() => handleSort('total_healing_done')}>
                  Healing Done {getSortIcon('total_healing_done')}
                </th>
                <th className="sortable" onClick={() => handleSort('total_damage_taken')}>
                  Damage Taken {getSortIcon('total_damage_taken')}
                </th>
                <th className="sortable" onClick={() => handleSort('deaths')}>
                  Deaths {getSortIcon('deaths')}
                </th>
              </>
            )}
            <th className="sortable" onClick={() => handleSort('item_level')}>
              Item Level {getSortIcon('item_level')}
            </th>
          </tr>
        </thead>
        <tbody>
          {filteredAndSortedParticipants.map((participant, index) => {
            const damagePercent = calculatePercentage(participant.total_damage_done, totalDamage);
            const healingPercent = calculatePercentage(participant.total_healing_done, totalHealing);
            
            return (
              <tr 
                key={participant.id || index}
                className="participant-row"
                style={{ borderLeft: `4px solid ${getClassColor(participant.class)}` }}
              >
                <td>
                  <div className="participant-name">{participant.name}</div>
                </td>
                <td>
                  <div 
                    className="participant-class" 
                    style={{ color: getClassColor(participant.class) }}
                  >
                    {participant.class || 'Unknown'}
                  </div>
                  {participant.spec && (
                    <div 
                      className="participant-spec"
                      style={{ color: getClassColor(participant.class), opacity: 0.8 }}
                    >
                      {participant.spec}
                    </div>
                  )}
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
                    <td>
                      <div className="number-small">{formatNumber(participant.total_damage_done)}</div>
                      <div className="damage-bar-mini">
                        <div 
                          className="damage-bar-fill" 
                          style={{ width: `${damagePercent}%` }}
                        />
                      </div>
                    </td>
                    <td>
                      <div className="number-small">{formatNumber(participant.total_healing_done)}</div>
                      <div className="damage-bar-mini">
                        <div 
                          className="heal-bar-fill" 
                          style={{ width: `${healingPercent}%` }}
                        />
                      </div>
                    </td>
                    <td className="number-small">{formatNumber(participant.total_damage_taken)}</td>
                    <td className="number-small">
                      <span className={`deaths-indicator ${participant.deaths > 0 ? 'has-deaths' : ''}`}>
                        {participant.deaths || 0}
                        {participant.deaths > 0 && ' 💀'}
                      </span>
                    </td>
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

  const participants = encounter.participants || { damage: [], healing: [], all: [], bosses: [] };

  return (
    <div>
      <button className="back-button" onClick={() => navigate(`/reports/${reportId}`)}>
        ← Back to Report
      </button>
      
      <div className="encounter-header">
        <div>
          <h2>{encounter.boss_name}</h2>
          <div className={`encounter-status ${encounter.success ? 'success' : 'wipe'}`}>
            {encounter.success ? '✅ Kill' : '❌ Wipe'}
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
        <div className="filter-section">
          <input
            type="text"
            placeholder="Filter by name, class, or spec..."
            value={filterText}
            onChange={(e) => setFilterText(e.target.value)}
            className="filter-input"
          />
          {filterText && (
            <button
              onClick={() => setFilterText('')}
              className="clear-filter"
            >
              ✕ Clear
            </button>
          )}
        </div>
        
        <div className="participants-tabs">
          <button
            className={`tab-button ${activeTab === 'damage' ? 'active' : ''}`}
            onClick={() => {
              setActiveTab('damage');
              setSortConfig({ key: 'total_damage_done', direction: 'desc' });
            }}
          >
            Damage Done ({participants.damage.length})
          </button>
          <button
            className={`tab-button ${activeTab === 'healing' ? 'active' : ''}`}
            onClick={() => {
              setActiveTab('healing');
              setSortConfig({ key: 'total_healing_done', direction: 'desc' });
            }}
          >
            Healing Done ({participants.healing.length})
          </button>
          <button
            className={`tab-button ${activeTab === 'overview' ? 'active' : ''}`}
            onClick={() => {
              setActiveTab('overview');
              setSortConfig({ key: 'total_damage_done', direction: 'desc' });
            }}
          >
            Overview ({participants.all.length})
          </button>
          <button
            className={`tab-button ${activeTab === 'bosses' ? 'active' : ''}`}
            onClick={() => {
              setActiveTab('bosses');
              setSortConfig({ key: 'total_damage_done', direction: 'desc' });
            }}
          >
            Boss Damage ({participants.bosses.length})
          </button>
        </div>

        <div className="tab-content">
          {activeTab === 'damage' && renderParticipantsTable(participants.damage, 'damage')}
          {activeTab === 'healing' && renderParticipantsTable(participants.healing, 'healing')}
          {activeTab === 'overview' && renderParticipantsTable(participants.all, 'overview')}
          {activeTab === 'bosses' && renderParticipantsTable(participants.bosses, 'damage')}
        </div>
      </div>
    </div>
  );
};

export default EncounterView;