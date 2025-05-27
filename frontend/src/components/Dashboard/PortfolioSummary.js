// src/components/Dashboard/PortfolioSummary.js
import React from 'react';
import {
  Card,
  CardContent,
  Typography,
  Grid,
  Box,
  Chip,
  Divider,
} from '@mui/material';
import {
  AccountBalance,
  TrendingUp,
} from '@mui/icons-material';

import { formatCurrency, formatPercentage } from '../../utils/formatters';

function PortfolioSummary({ data }) {
  if (!data) return null;

  const { accounts = [] } = data;

  return (
    <Card>
      <CardContent>
        <Typography variant="h6" gutterBottom>
          Account Breakdown
        </Typography>
        
        <Grid container spacing={3}>
          {accounts.map((account, index) => {
            const cashPercentage = account.total_account_value > 0 
              ? (account.cash_balance / account.total_account_value * 100).toFixed(1)
              : 0;
            const positionsPercentage = account.total_account_value > 0
              ? (account.positions_value / account.total_account_value * 100).toFixed(1)
              : 0;

            return (
              <Grid item xs={12} md={6} key={index}>
                <Card variant="outlined" sx={{ height: '100%' }}>
                  <CardContent>
                    <Box display="flex" alignItems="center" mb={2}>
                      <AccountBalance sx={{ mr: 1, color: 'primary.main' }} />
                      <Typography variant="h6" color="primary">
                        {account.institution_name}
                      </Typography>
                    </Box>

                    <Typography variant="h4" fontWeight="bold" gutterBottom>
                      {formatCurrency(account.total_account_value)}
                    </Typography>

                    <Divider sx={{ my: 2 }} />

                    {/* Cash Balance */}
                    <Box display="flex" justifyContent="space-between" alignItems="center" mb={1}>
                      <Box display="flex" alignItems="center">
                        <Typography variant="body1" color="text.secondary">
                          Cash Balance
                        </Typography>
                      </Box>
                      <Box textAlign="right">
                        <Typography variant="body1" fontWeight="500">
                          {formatCurrency(account.cash_balance)}
                        </Typography>
                        <Chip 
                          label={`${cashPercentage}%`}
                          size="small"
                          variant="outlined"
                          color="primary"
                        />
                      </Box>
                    </Box>

                    {/* Securities Value */}
                    <Box display="flex" justifyContent="space-between" alignItems="center">
                      <Box display="flex" alignItems="center">
                        <TrendingUp sx={{ mr: 0.5, fontSize: 16, color: 'text.secondary' }} />
                        <Typography variant="body1" color="text.secondary">
                          Securities Value
                        </Typography>
                      </Box>
                      <Box textAlign="right">
                        <Typography variant="body1" fontWeight="500">
                          {formatCurrency(account.positions_value)}
                        </Typography>
                        <Chip 
                          label={`${positionsPercentage}%`}
                          size="small"
                          variant="outlined"
                          color="secondary"
                        />
                      </Box>
                    </Box>
                  </CardContent>
                </Card>
              </Grid>
            );
          })}
        </Grid>
      </CardContent>
    </Card>
  );
}

export default PortfolioSummary;