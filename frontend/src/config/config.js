// src/config/config.js
/**
 * Configuration file for Treviwise Frontend
 * Uses environment variables with fallback defaults
 */

const config = {
  // API Configuration
  API_BASE_URL: process.env.REACT_APP_API_URL || 'http://localhost:8000',
  
  // Application Settings
  APP_NAME: process.env.REACT_APP_NAME || 'Treviwise',
  APP_TAGLINE: process.env.REACT_APP_TAGLINE || 'Personal Wealth Management Platform',
  
  // Feature Flags
  FEATURES: {
    DEMO_MODE: process.env.REACT_APP_ENABLE_DEMO_MODE === 'true',
    ADVANCED_CHARTS: process.env.REACT_APP_ENABLE_ADVANCED_CHARTS === 'true',
    EXPORT_FEATURES: process.env.REACT_APP_ENABLE_EXPORT_FEATURES === 'true',
  },
  
  // Development Settings
  IS_DEVELOPMENT: process.env.NODE_ENV === 'development',
  IS_PRODUCTION: process.env.NODE_ENV === 'production',
  
  // Analytics & Monitoring (for future use)
  ANALYTICS: {
    GOOGLE_ANALYTICS_ID: process.env.REACT_APP_GOOGLE_ANALYTICS_ID,
    SENTRY_DSN: process.env.REACT_APP_SENTRY_DSN,
  },
  
  // External Integrations (for future use)
  INTEGRATIONS: {
    STRIPE_PUBLIC_KEY: process.env.REACT_APP_STRIPE_PUBLIC_KEY,
  },
  
  // API Endpoints (relative paths that will be combined with API_BASE_URL)
  API_ENDPOINTS: {
    HEALTH: '/api/health',
    PORTFOLIO_SUMMARY: '/api/portfolio/summary',
    POSITIONS: '/api/positions',
    ASSETS: '/api/assets',
    DIVIDENDS: '/api/dividends',
    NET_WORTH: '/api/net-worth',
    MARKET_PRICES: '/api/market-prices',
    ASSET_HISTORY: '/api/asset', // Will be used as `/api/asset/{id}/history`
    REFRESH_DATA: '/api/refresh-data',
  },
};

// Helper function to get full API URL
export const getApiUrl = (endpoint) => {
  return `${config.API_BASE_URL}${endpoint}`;
};

// Helper function to check if feature is enabled
export const isFeatureEnabled = (featureName) => {
  return config.FEATURES[featureName] || false;
};

// Helper function to build asset history URL
export const getAssetHistoryUrl = (assetId, days = 90) => {
  return `${config.API_BASE_URL}${config.API_ENDPOINTS.ASSET_HISTORY}/${assetId}/history?days=${days}`;
};

// Export default config
export default config;