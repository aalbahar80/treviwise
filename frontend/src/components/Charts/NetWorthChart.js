// src/components/Charts/NetWorthChart.js
import React from 'react';
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts';
import { Box, Typography } from '@mui/material';
import { formatCurrency } from '../../utils/formatters';

function NetWorthChart({ data }) {
  console.log('NetWorthChart received data:', data);

  if (!data || data.length === 0) {
    return (
      <Box 
        display="flex" 
        alignItems="center" 
        justifyContent="center" 
        height="100%"
        sx={{ backgroundColor: '#f5f5f5', borderRadius: 2 }}
      >
        <Typography variant="h6" color="text.secondary">
          No net worth data available
        </Typography>
      </Box>
    );
  }

  // Group data by asset class
  const groupedData = data.reduce((acc, item) => {
    const assetClass = item.asset_class || 'Unknown';
    const value = parseFloat(item.value_usd) || 0;
    
    const existing = acc.find(x => x.name === assetClass);
    if (existing) {
      existing.value += value;
      existing.count += 1;
    } else {
      acc.push({
        name: assetClass,
        value: value,
        count: 1,
      });
    }
    return acc;
  }, []);

  // Filter and sort
  const chartData = groupedData
    .filter(item => item.value > 0)
    .sort((a, b) => b.value - a.value);

  console.log('Processed chart data:', chartData);

  if (chartData.length === 0) {
    return (
      <Box 
        display="flex" 
        alignItems="center" 
        justifyContent="center" 
        height="100%"
        sx={{ backgroundColor: '#f5f5f5', borderRadius: 2 }}
      >
        <Typography variant="h6" color="text.secondary">
          No valid data to display
        </Typography>
      </Box>
    );
  }

  const CustomTooltip = ({ active, payload, label }) => {
    if (active && payload && payload.length) {
      const data = payload[0].payload;
      return (
        <Box
          sx={{
            backgroundColor: 'white',
            border: '1px solid #ccc',
            borderRadius: 1,
            padding: 2,
            boxShadow: 3,
          }}
        >
          <Typography variant="subtitle2" fontWeight="bold">
            {label}
          </Typography>
          <Typography variant="body2">
            Value: {formatCurrency(data.value)}
          </Typography>
          <Typography variant="body2">
            Items: {data.count}
          </Typography>
        </Box>
      );
    }
    return null;
  };

  return (
    <Box sx={{ width: '100%', height: '100%' }}>
      <ResponsiveContainer width="100%" height="100%">
        <BarChart
          data={chartData}
          margin={{
            top: 20,
            right: 30,
            left: 20,
            bottom: 60,
          }}
        >
          <CartesianGrid strokeDasharray="3 3" />
          <XAxis 
            dataKey="name" 
            angle={-45}
            textAnchor="end"
            height={60}
            interval={0}
          />
          <YAxis 
            tickFormatter={(value) => `$${(value / 1000).toFixed(0)}K`}
          />
          <Tooltip content={<CustomTooltip />} />
          <Bar 
            dataKey="value" 
            fill="#2196f3"
            radius={[4, 4, 0, 0]}
          />
        </BarChart>
      </ResponsiveContainer>
    </Box>
  );
}

export default NetWorthChart;