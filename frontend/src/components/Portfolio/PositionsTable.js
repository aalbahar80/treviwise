// src/components/Portfolio/PositionsTable.js
import React from 'react';
import {
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Paper,
  Chip,
  Typography,
  Box,
} from '@mui/material';

import { formatCurrency, formatPercentage, formatGainLoss, getSecurityTypeInfo } from '../../utils/formatters';

function PositionsTable({ positions }) {
  if (!positions || positions.length === 0) {
    return (
      <Box textAlign="center" py={4}>
        <Typography variant="body1" color="text.secondary">
          No positions found
        </Typography>
      </Box>
    );
  }

  return (
    <TableContainer component={Paper} variant="outlined">
      <Table>
        <TableHead>
          <TableRow>
            <TableCell>Security</TableCell>
            <TableCell>Type</TableCell>
            <TableCell align="right">Quantity</TableCell>
            <TableCell align="right">Avg Cost</TableCell>
            <TableCell align="right">Current Price</TableCell>
            <TableCell align="right">Market Value</TableCell>
            <TableCell align="right">Gain/Loss</TableCell>
            <TableCell align="right">% Change</TableCell>
            <TableCell>Brokerage</TableCell>
          </TableRow>
        </TableHead>
        <TableBody>
          {positions.map((position, index) => {
            const gainLoss = formatGainLoss(position.unrealized_gain_loss);
            const gainLossPercent = formatGainLoss(position.unrealized_gain_loss_percent, 'percentage');
            const securityTypeInfo = getSecurityTypeInfo(position.security_type);

            return (
              <TableRow key={index} hover>
                <TableCell>
                  <Box>
                    <Typography variant="body1" fontWeight="500">
                      {position.symbol}
                    </Typography>
                    <Typography variant="caption" color="text.secondary">
                      {position.security_name}
                    </Typography>
                  </Box>
                </TableCell>
                <TableCell>
                  <Chip
                    label={position.security_type}
                    size="small"
                    sx={{
                      backgroundColor: securityTypeInfo.color,
                      color: 'white',
                      fontWeight: 'bold',
                    }}
                  />
                </TableCell>
                <TableCell align="right">
                  <Typography variant="body2">
                    {Number(position.quantity).toLocaleString()}
                  </Typography>
                </TableCell>
                <TableCell align="right">
                  <Typography variant="body2">
                    {formatCurrency(position.average_cost_basis)}
                  </Typography>
                </TableCell>
                <TableCell align="right">
                  <Typography variant="body2" fontWeight="500">
                    {formatCurrency(position.current_price)}
                  </Typography>
                </TableCell>
                <TableCell align="right">
                  <Typography variant="body1" fontWeight="bold">
                    {formatCurrency(position.market_value)}
                  </Typography>
                </TableCell>
                <TableCell align="right">
                  <Typography 
                    variant="body2" 
                    fontWeight="500"
                    sx={{ color: gainLoss.color }}
                  >
                    {gainLoss.value}
                  </Typography>
                </TableCell>
                <TableCell align="right">
                  <Chip
                    label={gainLossPercent.value}
                    size="small"
                    sx={{
                      backgroundColor: gainLossPercent.color,
                      color: 'white',
                      fontWeight: 'bold',
                    }}
                  />
                </TableCell>
                <TableCell>
                  <Typography variant="caption" color="text.secondary">
                    {position.brokerage}
                  </Typography>
                </TableCell>
              </TableRow>
            );
          })}
        </TableBody>
      </Table>
    </TableContainer>
  );
}

export default PositionsTable;