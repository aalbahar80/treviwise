// src/services/api.js
import axios from 'axios';
import config, { getApiUrl, getAssetHistoryUrl } from '../config/config';

// Create axios instance with configuration from environment variables
const api = axios.create({
  baseURL: `${config.API_BASE_URL}/api`, // Note: keeping your existing structure with /api suffix
  timeout: 10000,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Request interceptor for logging (only in development)
api.interceptors.request.use(
  (config) => {
    if (process.env.NODE_ENV === 'development') {
      console.log(`API Request: ${config.method?.toUpperCase()} ${config.url}`);
    }
    return config;
  },
  (error) => {
    console.error('API Request Error:', error);
    return Promise.reject(error);
  }
);

// Response interceptor for error handling
api.interceptors.response.use(
  (response) => {
    if (process.env.NODE_ENV === 'development') {
      console.log(`API Response: ${response.status} ${response.config.url}`);
    }
    return response;
  },
  (error) => {
    console.error('API Response Error:', error.response?.data || error.message);
    return Promise.reject(error);
  }
);

// API service functions
export const apiService = {
  // Health check
  async healthCheck() {
    const response = await api.get('/health');
    return response.data;
  },

  // Portfolio data
  async getPortfolioSummary() {
    const response = await api.get('/portfolio/summary');
    return response.data;
  },

  async getPositions() {
    const response = await api.get('/positions');
    return response.data;
  },

  // Assets data
  async getAssets() {
    const response = await api.get('/assets');
    return response.data;
  },

  // Net worth data
  async getNetWorth() {
    const response = await api.get('/net-worth');
    return response.data;
  },

  // Dividends data
  async getDividends(limit = 20) {
    const response = await api.get(`/dividends?limit=${limit}`);
    return response.data;
  },

  // Market prices
  async getMarketPrices() {
    const response = await api.get('/market-prices');
    return response.data;
  },

  // Asset history - using the helper function for flexibility
  async getAssetHistory(assetId, days = 90) {
    // Using axios directly with the full URL from helper function
    // This maintains your existing API structure
    const response = await axios.get(getAssetHistoryUrl(assetId, days));
    return response.data;
  },

  // Refresh data
  async refreshData() {
    const response = await api.post('/refresh-data');
    return response.data;
  },
};

export default apiService;