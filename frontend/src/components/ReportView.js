import React, { useState, useEffect } from 'react';
import { useParams, Link, useNavigate } from 'react-router-dom';
import { reportService } from '../services/api';

const ReportView = () => {
  const { reportId } = useParams();
  const navigate = useNavigate();
  const [report, setReport] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    loadReport();
  }, [reportId]);

  const loadReport = async () => {
    try {
      setLoading(true);
      const response = await reportService.getReport(reportId);
      setReport(response.data);
    } catch (err) {
      console.error('Error loading report:', err);
      setError('Failed to load report');
    } finally {
      setLoading(false);
    }
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

  if (loading) return <div className="loading">Loading report...</div>;
  if (error) return <div className="error">{error}</div>;
  if (!report) return <div className="error">Report not found</div>;

  return (
    <div>
      <button className="back-button" onClick={() => navigate('/')}>
        ← Back to Reports
      </button>
      
      <h2>{report.filename}</h2>
      
      <div className="report-meta">
        <p><strong>Uploaded by:</strong> {report.uploaded_by || 'anonymous'}</p>
        {report.start_time && <p><strong>Start Time:</strong> {formatDate(report.start_time)}</p>}
        {report.end_time && <p><strong>End Time:</strong> {formatDate(report.end_time)}</p>}
        {report.zone_name && <p><strong>Zone:</strong> {report.zone_name}</p>}
      </div>

      <h3>Encounters ({report.encounters ? report.encounters.length : 0})</h3>
      
      {!report.encounters || report.encounters.length === 0 ? (
        <p>No encounters found in this report.</p>
      ) : (
        <div className="encounters-list">
          {report.encounters.map(encounter => (
            <Link
              key={encounter.id}
              to={`/reports/${reportId}/encounters/${encounter.id}`}
              style={{ textDecoration: 'none', color: 'inherit' }}
            >
              <div className={`encounter-item ${encounter.success ? 'success' : 'wipe'}`}>
                <div className="encounter-header">
                  <div className="encounter-title">{encounter.boss_name}</div>
                  <div className={`encounter-status ${encounter.success ? 'success' : 'wipe'}`}>
                    {encounter.success ? '✅ Kill' : '❌ Wipe'}
                  </div>
                </div>
                <div className="encounter-meta">
                  <div>Start: {formatDate(encounter.start_time)}</div>
                  <div>Duration: {formatDuration(encounter.duration_ms)}</div>
                  {encounter.zone_name && <div>Zone: {encounter.zone_name}</div>}
                  {encounter.difficulty && <div>Difficulty: {encounter.difficulty}</div>}
                </div>
              </div>
            </Link>
          ))}
        </div>
      )}
    </div>
  );
};

export default ReportView;