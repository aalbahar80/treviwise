// src/components/Dashboard/Dashboard.js
import React, { useState } from 'react';
import {
  Grid,
  Card,
  CardContent,
  Typography,
  Box,
  Tabs,
  Tab,
  Chip,
  useTheme,
} from '@mui/material';
import {
  TrendingUp,
  AccountBalance,
  PieChart,
  Timeline,
} from '@mui/icons-material';

import { formatCurrency, formatPercentage, formatGainLoss } from '../../utils/formatters';
import PortfolioSummary from './PortfolioSummary';
import PositionsTable from '../Portfolio/PositionsTable';
import AssetsTable from '../Assets/AssetsTable';
import NetWorthChart from '../Charts/NetWorthChart';
import AllocationChart from '../Charts/AllocationChart';
import DividendsTable from '../Portfolio/DividendsTable';

function TabPanel({ children, value, index, ...other }) {
  return (
    <div
      role="tabpanel"
      hidden={value !== index}
      id={`dashboard-tabpanel-${index}`}
      aria-labelledby={`dashboard-tab-${index}`}
      {...other}
    >
      {value === index && <Box sx={{ py: 3 }}>{children}</Box>}
    </div>
  );
}

function Dashboard({ data, onRefresh }) {
  const theme = useTheme();
  const [activeTab, setActiveTab] = useState(0);

  const { portfolio, positions, assets, netWorth, dividends } = data;

  const handleTabChange = (event, newValue) => {
    setActiveTab(newValue);
  };

  // Calculate key metrics
  const portfolioTotals = portfolio?.portfolio_totals || {};
  const totalCostBasis = portfolioTotals.total_cost_basis || 0;
  const totalMarketValue = portfolioTotals.total_market_value || 0;
  const totalGainLoss = portfolioTotals.total_unrealized_gain_loss || 0;
  const gainLossPercent = totalCostBasis > 0 ? (totalGainLoss / totalCostBasis) * 100 : 0;

  const totalNetWorth = netWorth?.total_net_worth || 0;
  const assetClasses = netWorth?.summary_by_class || [];

  return (
    <Box>
      {/* Key Metrics Cards */}
      <Grid container spacing={3} sx={{ mb: 3 }}>
        {/* Total Net Worth */}
        <Grid item xs={12} sm={6} md={3}>
          <Card sx={{ height: '100%' }}>
            <CardContent>
              <Box display="flex" alignItems="center" mb={1}>
                <AccountBalance color="primary" sx={{ mr: 1 }} />
                <Typography variant="h6" color="primary">
                  Total Net Worth
                </Typography>
              </Box>
              <Typography variant="h4" fontWeight="bold">
                {formatCurrency(totalNetWorth)}
              </Typography>
              <Typography variant="body2" color="text.secondary">
                Across all asset classes
              </Typography>
            </CardContent>
          </Card>
        </Grid>

        {/* Portfolio Value */}
        <Grid item xs={12} sm={6} md={3}>
          <Card sx={{ height: '100%' }}>
            <CardContent>
              <Box display="flex" alignItems="center" mb={1}>
                <TrendingUp color="secondary" sx={{ mr: 1 }} />
                <Typography variant="h6" color="secondary">
                  Portfolio Value
                </Typography>
              </Box>
              <Typography variant="h4" fontWeight="bold">
                {formatCurrency(totalMarketValue)}
              </Typography>
              <Typography variant="body2" color="text.secondary">
                Securities only
              </Typography>
            </CardContent>
          </Card>
        </Grid>

        {/* Total Gain/Loss */}
        <Grid item xs={12} sm={6} md={3}>
          <Card sx={{ height: '100%' }}>
            <CardContent>
              <Box display="flex" alignItems="center" mb={1}>
                <Timeline sx={{ mr: 1, color: formatGainLoss(totalGainLoss).color }} />
                <Typography variant="h6" sx={{ color: formatGainLoss(totalGainLoss).color }}>
                  Total P&L
                </Typography>
              </Box>
              <Typography 
                variant="h4" 
                fontWeight="bold"
                sx={{ color: formatGainLoss(totalGainLoss).color }}
              >
                {formatGainLoss(totalGainLoss).value}
              </Typography>
              <Chip
                label={formatGainLoss(gainLossPercent, 'percentage').value}
                size="small"
                sx={{
                  backgroundColor: formatGainLoss(gainLossPercent).color,
                  color: 'white',
                  fontWeight: 'bold',
                }}
              />
            </CardContent>
          </Card>
        </Grid>

        {/* Number of Positions */}
        <Grid item xs={12} sm={6} md={3}>
          <Card sx={{ height: '100%' }}>
            <CardContent>
              <Box display="flex" alignItems="center" mb={1}>
                <PieChart color="info" sx={{ mr: 1 }} />
                <Typography variant="h6" color="info.main">
                  Positions
                </Typography>
              </Box>
              <Typography variant="h4" fontWeight="bold">
                {portfolioTotals.total_positions || 0}
              </Typography>
              <Typography variant="body2" color="text.secondary">
                Active securities
              </Typography>
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      {/* Portfolio Summary */}
      <PortfolioSummary data={portfolio} />

      {/* Tabbed Content */}
      <Card sx={{ mt: 3 }}>
        <Box sx={{ borderBottom: 1, borderColor: 'divider' }}>
          <Tabs value={activeTab} onChange={handleTabChange} variant="fullWidth">
            <Tab label="Positions" />
            <Tab label="All Assets" />
            <Tab label="Dividends" />
            <Tab label="Asset Allocation" />
            <Tab label="Net Worth Chart" />
          </Tabs>
        </Box>

        <TabPanel value={activeTab} index={0}>
          <PositionsTable positions={positions || []} />
        </TabPanel>

        <TabPanel value={activeTab} index={1}>
          <AssetsTable assets={assets || []} />
        </TabPanel>

        <TabPanel value={activeTab} index={2}>
          <DividendsTable dividends={dividends || []} />
        </TabPanel>

        <TabPanel value={activeTab} index={3}>
          <Box>
            <Typography variant="h5" gutterBottom sx={{ mb: 3 }}>
              Asset Allocation Analysis
            </Typography>
            <Grid container spacing={3}>
              <Grid item xs={12} lg={8}>
                <Card sx={{ p: 4 }}>
                  <Typography variant="h6" gutterBottom>
                    Asset Allocation Chart
                  </Typography>
                  <Box sx={{ height: 400, width: 400, minHeight: 400 }}>
                    <AllocationChart data={netWorth?.summary_by_class || []} />
                  </Box>
                </Card>
              </Grid>
              <Grid item xs={12} lg={4}>
                <Card sx={{ p: 3, height: 'fit-content' }}>
                  <Typography variant="h6" gutterBottom>
                    Allocation Summary
                  </Typography>
                  {assetClasses.map((assetClass, index) => (
                    <Box key={index} sx={{ mb: 3 }}>
                      <Box display="flex" justifyContent="space-between" alignItems="center" mb={1}>
                        <Typography variant="body1" fontWeight="600">
                          {assetClass.asset_class}
                        </Typography>
                        <Typography variant="body1" color="primary" fontWeight="bold">
                          {formatPercentage(assetClass.percentage)}
                        </Typography>
                      </Box>
                      <Box display="flex" justifyContent="space-between" alignItems="center" mb={1}>
                        <Typography variant="body2" color="text.secondary">
                          {formatCurrency(assetClass.total_value)}
                        </Typography>
                        <Typography variant="body2" color="text.secondary">
                          {assetClass.items} items
                        </Typography>
                      </Box>
                      <Box sx={{ width: '100%', height: 6, backgroundColor: 'grey.200', borderRadius: 3 }}>
                        <Box 
                          sx={{ 
                            width: `${assetClass.percentage}%`, 
                            height: '100%', 
                            backgroundColor: 'primary.main', 
                            borderRadius: 3 
                          }} 
                        />
                      </Box>
                    </Box>
                  ))}
                </Card>
              </Grid>
            </Grid>
          </Box>
        </TabPanel>

        <TabPanel value={activeTab} index={4}>
          <Box>
            <Typography variant="h5" gutterBottom sx={{ mb: 3 }}>
              Net Worth Breakdown by Asset Class
            </Typography>
            <Grid container spacing={3}>
              <Grid item xs={12}>
                <Card sx={{ p: 3 }}>
                  <Typography variant="h6" gutterBottom>
                    Net Worth Distribution
                  </Typography>
                  <Box sx={{ height: 350, width: 350, minHeight: 350 }}>
                    <NetWorthChart data={netWorth?.detailed_breakdown || []} />
                  </Box>
                </Card>
              </Grid>
              <Grid item xs={12}>
                <Card sx={{ p: 3 }}>
                  <Typography variant="h6" gutterBottom>
                    Asset Class Summary
                  </Typography>
                  <Grid container spacing={3}>
                    {assetClasses.map((assetClass, index) => (
                      <Grid item xs={12} sm={6} lg={4} key={index}>
                        <Box 
                          sx={{ 
                            p: 3, 
                            border: '2px solid', 
                            borderColor: 'primary.light', 
                            borderRadius: 3,
                            textAlign: 'center',
                            '&:hover': {
                              borderColor: 'primary.main',
                              boxShadow: 2
                            }
                          }}
                        >
                          <Typography variant="h6" fontWeight="bold" color="primary.main" gutterBottom>
                            {assetClass.asset_class}
                          </Typography>
                          <Typography variant="h4" fontWeight="bold" sx={{ my: 2 }}>
                            {formatCurrency(assetClass.total_value)}
                          </Typography>
                          <Chip 
                            label={`${formatPercentage(assetClass.percentage)} • ${assetClass.items} items`}
                            size="medium"
                            color="primary"
                            variant="outlined"
                            sx={{ fontWeight: 'bold' }}
                          />
                        </Box>
                      </Grid>
                    ))}
                  </Grid>
                </Card>
              </Grid>
            </Grid>
          </Box>
        </TabPanel>
      </Card>
    </Box>
  );
}

export default Dashboard;