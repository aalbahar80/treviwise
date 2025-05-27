// src/components/Charts/AllocationChart.js
import React from 'react';
import { PieChart, Pie, Cell, ResponsiveContainer, Legend, Tooltip } from 'recharts';
import { Box, Typography } from '@mui/material';
import { formatCurrency, formatPercentage } from '../../utils/formatters';

function AllocationChart({ data }) {
  console.log('AllocationChart received data:', data);

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
          No allocation data available
        </Typography>
      </Box>
    );
  }

  // Simple data preparation
  const chartData = data.map((item, index) => ({
    name: item.asset_class || 'Unknown',
    value: parseFloat(item.total_value) || 0,
    percentage: parseFloat(item.percentage) || 0,
    items: item.items || 0,
  })).filter(item => item.value > 0);

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

  // Simple color scheme
  const colors = ['#2196f3', '#4caf50', '#ff9800', '#f44336', '#9c27b0'];

  const CustomTooltip = ({ active, payload }) => {
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
            {data.name}
          </Typography>
          <Typography variant="body2">
            Value: {formatCurrency(data.value)}
          </Typography>
          <Typography variant="body2">
            Percentage: {formatPercentage(data.percentage)}
          </Typography>
          <Typography variant="body2">
            Items: {data.items}
          </Typography>
        </Box>
      );
    }
    return null;
  };

  return (
    <Box sx={{ width: '100%', height: '100%' }}>
      <ResponsiveContainer width="100%" height="100%">
        <PieChart>
          <Pie
            data={chartData}
            cx="50%"
            cy="50%"
            outerRadius="70%"
            fill="#8884d8"
            dataKey="value"
            label={({ percentage }) => `${percentage.toFixed(1)}%`}
          >
            {chartData.map((entry, index) => (
              <Cell 
                key={`cell-${index}`} 
                fill={colors[index % colors.length]} 
              />
            ))}
          </Pie>
          <Tooltip content={<CustomTooltip />} />
          <Legend 
            verticalAlign="bottom" 
            height={36}
            iconType="circle"
            formatter={(value) => (
              <span style={{ fontSize: '14px', fontWeight: 'bold' }}>
                {value}
              </span>
            )}
          />
        </PieChart>
      </ResponsiveContainer>
    </Box>
  );
}

export default AllocationChart;