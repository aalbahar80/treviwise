// src/App.js
import React, { useState, useEffect } from 'react';
import {
  ThemeProvider,
  CssBaseline,
  Container,
  AppBar,
  Toolbar,
  Typography,
  Box,
  Alert,
  Snackbar,
  CircularProgress,
  Fab,
  Tooltip,
} from '@mui/material';
import {
  Refresh as RefreshIcon,
  Dashboard as DashboardIcon,
} from '@mui/icons-material';

import theme from './theme/theme';
import apiService from './services/api';
import Dashboard from './components/Dashboard/Dashboard';

function App() {
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [data, setData] = useState({
    portfolio: null,
    positions: null,
    assets: null,
    netWorth: null,
    dividends: null,
  });
  const [refreshing, setRefreshing] = useState(false);
  const [snackbar, setSnackbar] = useState({ open: false, message: '', severity: 'info' });

  // Load all data on component mount
  useEffect(() => {
    loadAllData();
  }, []);

  const loadAllData = async () => {
    try {
      setLoading(true);
      setError(null);

      // Load all data in parallel
      const [portfolio, positions, assets, netWorth, dividends] = await Promise.all([
        apiService.getPortfolioSummary(),
        apiService.getPositions(),
        apiService.getAssets(),
        apiService.getNetWorth(),
        apiService.getDividends(20),
      ]);

      setData({
        portfolio,
        positions,
        assets,
        netWorth,
        dividends,
      });

      showSnackbar('Data loaded successfully', 'success');
    } catch (err) {
      console.error('Failed to load data:', err);
      setError(err.message || 'Failed to load data. Please check if the backend is running.');
      showSnackbar('Failed to load data', 'error');
    } finally {
      setLoading(false);
    }
  };

  const handleRefresh = async () => {
    try {
      setRefreshing(true);
      
      // Trigger backend data refresh
      await apiService.refreshData();
      
      // Reload all data
      await loadAllData();
      
      showSnackbar('Data refreshed successfully', 'success');
    } catch (err) {
      console.error('Failed to refresh data:', err);
      showSnackbar('Failed to refresh data', 'error');
    } finally {
      setRefreshing(false);
    }
  };

  const showSnackbar = (message, severity = 'info') => {
    setSnackbar({ open: true, message, severity });
  };

  const handleCloseSnackbar = () => {
    setSnackbar({ ...snackbar, open: false });
  };

  if (loading) {
    return (
      <ThemeProvider theme={theme}>
        <CssBaseline />
        <Box
          display="flex"
          justifyContent="center"
          alignItems="center"
          minHeight="100vh"
          flexDirection="column"
        >
          <CircularProgress size={60} />
          <Typography variant="h6" sx={{ mt: 2 }}>
            Loading your wealth data...
          </Typography>
        </Box>
      </ThemeProvider>
    );
  }

  if (error) {
    return (
      <ThemeProvider theme={theme}>
        <CssBaseline />
        <Container maxWidth="md" sx={{ mt: 4 }}>
          <Alert 
            severity="error" 
            action={
              <button onClick={loadAllData}>
                Retry
              </button>
            }
          >
            <Typography variant="h6">Connection Error</Typography>
            <Typography variant="body2">{error}</Typography>
            <Typography variant="caption" display="block" sx={{ mt: 1 }}>
              Make sure your FastAPI backend is running on http://localhost:8000
            </Typography>
          </Alert>
        </Container>
      </ThemeProvider>
    );
  }

  return (
    <ThemeProvider theme={theme}>
      <CssBaseline />
      
      {/* App Bar */}
      <AppBar position="static" elevation={0}>
        <Toolbar>
          <DashboardIcon sx={{ mr: 2 }} />
          <Typography variant="h6" component="div" sx={{ flexGrow: 1 }}>
            Wealth Tracker
          </Typography>
          <Typography variant="body2" sx={{ opacity: 0.8 }}>
            Last updated: {new Date().toLocaleTimeString()}
          </Typography>
        </Toolbar>
      </AppBar>

      {/* Main Content */}
      <Container maxWidth="xl" sx={{ mt: 3, mb: 3 }}>
        <Dashboard data={data} onRefresh={loadAllData} />
      </Container>

      {/* Floating Refresh Button */}
      <Tooltip title="Refresh market data">
        <Fab
          color="primary"
          onClick={handleRefresh}
          disabled={refreshing}
          sx={{
            position: 'fixed',
            bottom: 24,
            right: 24,
          }}
        >
          {refreshing ? <CircularProgress size={24} color="inherit" /> : <RefreshIcon />}
        </Fab>
      </Tooltip>

      {/* Snackbar for notifications */}
      <Snackbar
        open={snackbar.open}
        autoHideDuration={4000}
        onClose={handleCloseSnackbar}
        anchorOrigin={{ vertical: 'bottom', horizontal: 'left' }}
      >
        <Alert 
          onClose={handleCloseSnackbar} 
          severity={snackbar.severity}
          variant="filled"
        >
          {snackbar.message}
        </Alert>
      </Snackbar>
    </ThemeProvider>
  );
}

export default App;