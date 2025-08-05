import axios from 'axios';

const API_BASE_URL = process.env.REACT_APP_API_URL || 'http://localhost:4001/api';

const api = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
});

export const reportService = {
  uploadReport: async (file, uploadedBy = 'anonymous') => {
    const formData = new FormData();
    formData.append('file', file);
    formData.append('uploaded_by', uploadedBy);
    
    const response = await api.post('/reports', formData, {
      headers: {
        'Content-Type': 'multipart/form-data',
      },
    });
    
    return response.data;
  },

  getReports: async () => {
    const response = await api.get('/reports');
    return response.data;
  },

  getReport: async (reportId) => {
    const response = await api.get(`/reports/${reportId}`);
    return response.data;
  },

  getEncounter: async (reportId, encounterId) => {
    const response = await api.get(`/reports/${reportId}/encounters/${encounterId}`);
    return response.data;
  },
};

export default api;