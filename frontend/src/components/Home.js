import React, { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import { reportService } from '../services/api';
import FileUpload from './FileUpload';

const Home = () => {
  const [reports, setReports] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    loadReports();
  }, []);

  const loadReports = async () => {
    try {
      setLoading(true);
      const response = await reportService.getReports();
      setReports(response.data || []);
    } catch (err) {
      console.error('Error loading reports:', err);
      setError('Failed to load reports');
    } finally {
      setLoading(false);
    }
  };

  const handleUploadSuccess = (newReport) => {
    setReports(prevReports => [newReport.data, ...prevReports]);
  };

  const formatDate = (dateString) => {
    if (!dateString) return 'Unknown';
    return new Date(dateString).toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    });
  };

  const formatDuration = (startTime, endTime) => {
    if (!startTime || !endTime) return 'Unknown';
    const start = new Date(startTime);
    const end = new Date(endTime);
    const durationMs = end - start;
    const minutes = Math.floor(durationMs / 60000);
    const seconds = Math.floor((durationMs % 60000) / 1000);
    return `${minutes}m ${seconds}s`;
  };

  return (
    <div>
      <h2>Upload Combat Log</h2>
      <FileUpload onUploadSuccess={handleUploadSuccess} />
      
      <h2>Recent Reports</h2>
      {loading && <div className="loading">Loading reports...</div>}
      {error && <div className="error">{error}</div>}
      
      {!loading && !error && (
        <div className="reports-list">
          {reports.length === 0 ? (
            <p>No reports uploaded yet. Upload a combat log to get started!</p>
          ) : (
            reports.map(report => (
              <Link 
                key={report.id} 
                to={`/reports/${report.id}`} 
                style={{ textDecoration: 'none', color: 'inherit' }}
              >
                <div className="report-item">
                  <h3>{report.filename}</h3>
                  <div className="report-meta">
                    Uploaded by: {report.uploaded_by || 'anonymous'}
                  </div>
                  <div className="report-meta">
                    Date: {formatDate(report.start_time)}
                  </div>
                  {report.zone_name && (
                    <div className="report-meta">
                      Zone: {report.zone_name}
                    </div>
                  )}
                  {report.encounters && (
                    <div className="report-meta">
                      {report.encounters.length} encounter(s)
                    </div>
                  )}
                </div>
              </Link>
            ))
          )}
        </div>
      )}
    </div>
  );
};

export default Home;