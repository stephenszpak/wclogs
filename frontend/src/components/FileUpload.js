import React, { useState, useRef } from 'react';
import { reportService } from '../services/api';

const FileUpload = ({ onUploadSuccess }) => {
  const [selectedFile, setSelectedFile] = useState(null);
  const [uploading, setUploading] = useState(false);
  const [error, setError] = useState(null);
  const [dragOver, setDragOver] = useState(false);
  const fileInputRef = useRef(null);

  const handleFileSelect = (file) => {
    if (file && (file.name.endsWith('.txt') || file.name.endsWith('.log'))) {
      setSelectedFile(file);
      setError(null);
    } else {
      setError('Please select a valid combat log file (.txt or .log)');
      setSelectedFile(null);
    }
  };

  const handleFileInputChange = (event) => {
    const file = event.target.files[0];
    handleFileSelect(file);
  };

  const handleDragOver = (event) => {
    event.preventDefault();
    setDragOver(true);
  };

  const handleDragLeave = (event) => {
    event.preventDefault();
    setDragOver(false);
  };

  const handleDrop = (event) => {
    event.preventDefault();
    setDragOver(false);
    
    const files = event.dataTransfer.files;
    if (files.length > 0) {
      handleFileSelect(files[0]);
    }
  };

  const handleUpload = async () => {
    if (!selectedFile) {
      setError('Please select a file first');
      return;
    }

    // Check file size (warn if > 100MB)
    const fileSizeMB = selectedFile.size / 1024 / 1024;
    if (fileSizeMB > 100) {
      if (!window.confirm(`This is a large file (${fileSizeMB.toFixed(1)}MB). Upload may take several minutes. Continue?`)) {
        return;
      }
    }

    try {
      setUploading(true);
      setError(null);
      
      const result = await reportService.uploadReport(selectedFile);
      
      // Reset form
      setSelectedFile(null);
      if (fileInputRef.current) {
        fileInputRef.current.value = '';
      }
      
      // Notify parent component
      if (onUploadSuccess) {
        onUploadSuccess(result);
      }
      
    } catch (err) {
      console.error('Upload error:', err);
      if (err.response) {
        if (err.response.status === 413) {
          setError('File is too large. Maximum size is 1GB.');
        } else if (err.response.data && err.response.data.error) {
          setError(err.response.data.error);
        } else {
          setError(`Upload failed (${err.response.status}). Please try again.`);
        }
      } else if (err.code === 'ECONNABORTED') {
        setError('Upload timed out. The file may be too large or your connection too slow.');
      } else {
        setError('Failed to upload file. Please check your connection and try again.');
      }
    } finally {
      setUploading(false);
    }
  };

  return (
    <div 
      className={`upload-container ${dragOver ? 'dragover' : ''}`}
      onDragOver={handleDragOver}
      onDragLeave={handleDragLeave}
      onDrop={handleDrop}
    >
      <div>
        <h3>Select Combat Log File</h3>
        <p>Drag and drop a .txt or .log file here, or click to select</p>
        
        <div className="file-input">
          <label htmlFor="file-upload">
            Choose File
          </label>
          <input
            id="file-upload"
            type="file"
            accept=".txt,.log"
            onChange={handleFileInputChange}
            ref={fileInputRef}
          />
        </div>
        
        {selectedFile && (
          <div>
            <p><strong>Selected file:</strong> {selectedFile.name}</p>
            <p><strong>Size:</strong> {(selectedFile.size / 1024 / 1024).toFixed(2)} MB</p>
          </div>
        )}
        
        {error && <div className="error">{error}</div>}
        
        {uploading && <div className="loading">Uploading and parsing log file...</div>}
        
        <button
          className="upload-button"
          onClick={handleUpload}
          disabled={!selectedFile || uploading}
        >
          {uploading ? 'Processing...' : 'Upload and Parse'}
        </button>
      </div>
    </div>
  );
};

export default FileUpload;