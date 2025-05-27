// src/components/Portfolio/DividendsTable.js
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

import { formatCurrency, formatDate } from '../../utils/formatters';

function DividendsTable({ dividends }) {
  if (!dividends || dividends.length === 0) {
    return (
      <Box textAlign="center" py={4}>
        <Typography variant="body1" color="text.secondary">
          No dividend data found
        </Typography>
      </Box>
    );
  }

  const getFrequencyColor = (frequency) => {
    const colorMap = {
      'Monthly': 'success',
      'Quarterly': 'primary',
      'Semi-Annual': 'warning',
      'Annual': 'secondary',
    };
    return colorMap[frequency] || 'default';
  };

  return (
    <TableContainer component={Paper} variant="outlined">
      <Table>
        <TableHead>
          <TableRow>
            <TableCell>Security</TableCell>
            <TableCell>Ex-Dividend Date</TableCell>
            <TableCell>Payment Date</TableCell>
            <TableCell align="right">Dividend per Share</TableCell>
            <TableCell align="right">Total Received</TableCell>
            <TableCell>Frequency</TableCell>
          </TableRow>
        </TableHead>
        <TableBody>
          {dividends.map((dividend, index) => (
            <TableRow key={index} hover>
              <TableCell>
                <Box>
                  <Typography variant="body1" fontWeight="500">
                    {dividend.symbol}
                  </Typography>
                  <Typography variant="caption" color="text.secondary">
                    {dividend.security_name}
                  </Typography>
                </Box>
              </TableCell>
              <TableCell>
                <Typography variant="body2">
                  {formatDate(dividend.ex_dividend_date)}
                </Typography>
              </TableCell>
              <TableCell>
                <Typography variant="body2">
                  {dividend.payment_date ? formatDate(dividend.payment_date) : 'TBD'}
                </Typography>
              </TableCell>
              <TableCell align="right">
                <Typography variant="body2" fontWeight="500">
                  {formatCurrency(dividend.dividend_amount)}
                </Typography>
              </TableCell>
              <TableCell align="right">
                <Typography 
                  variant="body1" 
                  fontWeight="bold"
                  color={dividend.total_dividend_received > 0 ? 'success.main' : 'text.secondary'}
                >
                  {dividend.total_dividend_received > 0 
                    ? formatCurrency(dividend.total_dividend_received)
                    : 'Not owned'
                  }
                </Typography>
              </TableCell>
              <TableCell>
                {dividend.frequency && (
                  <Chip
                    label={dividend.frequency}
                    size="small"
                    color={getFrequencyColor(dividend.frequency)}
                    variant="outlined"
                  />
                )}
              </TableCell>
            </TableRow>
          ))}
        </TableBody>
      </Table>
    </TableContainer>
  );
}

export default DividendsTable;