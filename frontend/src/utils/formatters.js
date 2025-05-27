// src/utils/formatters.js

// Currency formatting
export const formatCurrency = (amount, currency = 'USD', decimals = 2) => {
  if (amount === null || amount === undefined) return '$0.00';
  
  const currencySymbols = {
    'USD': '$',
    'KWD': 'د.ك',
    'EUR': '€',
    'GBP': '£'
  };

  const symbol = currencySymbols[currency] || '$';
  const formattedAmount = Number(amount).toFixed(decimals);
  
  // Add thousand separators
  const parts = formattedAmount.split('.');
  parts[0] = parts[0].replace(/\B(?=(\d{3})+(?!\d))/g, ',');
  
  return `${symbol}${parts.join('.')}`;
};

// Percentage formatting
export const formatPercentage = (value, decimals = 2) => {
  if (value === null || value === undefined) return '0.00%';
  return `${Number(value).toFixed(decimals)}%`;
};

// Large number formatting (K, M, B)
export const formatLargeNumber = (num, decimals = 1) => {
  if (num === null || num === undefined) return '0';
  
  const absNum = Math.abs(num);
  
  if (absNum >= 1e9) {
    return (num / 1e9).toFixed(decimals) + 'B';
  } else if (absNum >= 1e6) {
    return (num / 1e6).toFixed(decimals) + 'M';
  } else if (absNum >= 1e3) {
    return (num / 1e3).toFixed(decimals) + 'K';
  } else {
    return num.toFixed(decimals);
  }
};

// Date formatting
export const formatDate = (dateString) => {
  if (!dateString) return '';
  
  const date = new Date(dateString);
  return date.toLocaleDateString('en-US', {
    year: 'numeric',
    month: 'short',
    day: 'numeric'
  });
};

// Relative date formatting
export const formatRelativeDate = (dateString) => {
  if (!dateString) return '';
  
  const date = new Date(dateString);
  const now = new Date();
  const diffInMs = now - date;
  const diffInDays = Math.floor(diffInMs / (1000 * 60 * 60 * 24));
  
  if (diffInDays === 0) {
    return 'Today';
  } else if (diffInDays === 1) {
    return 'Yesterday';
  } else if (diffInDays < 7) {
    return `${diffInDays} days ago`;
  } else if (diffInDays < 30) {
    const weeks = Math.floor(diffInDays / 7);
    return `${weeks} week${weeks > 1 ? 's' : ''} ago`;
  } else {
    return formatDate(dateString);
  }
};

// Color coding for gains/losses
export const getGainLossColor = (value) => {
  if (value > 0) return '#4caf50'; // Green
  if (value < 0) return '#f44336'; // Red
  return '#757575'; // Gray
};

// Format gain/loss with color and sign
export const formatGainLoss = (value, format = 'currency', decimals = 2) => {
  const color = getGainLossColor(value);
  const sign = value > 0 ? '+' : '';
  
  let formattedValue;
  if (format === 'percentage') {
    formattedValue = `${sign}${formatPercentage(value, decimals)}`;
  } else {
    formattedValue = `${sign}${formatCurrency(value, 'USD', decimals)}`;
  }
  
  return {
    value: formattedValue,
    color: color,
    isPositive: value > 0,
    isNegative: value < 0
  };
};

// Calculate allocation percentages
export const calculateAllocations = (items, valueKey = 'value') => {
  const total = items.reduce((sum, item) => sum + (item[valueKey] || 0), 0);
  
  return items.map(item => ({
    ...item,
    percentage: total > 0 ? ((item[valueKey] || 0) / total * 100).toFixed(1) : 0
  }));
};

// Generate chart colors
export const getChartColors = (count) => {
  const colors = [
    '#2196f3', '#4caf50', '#ff9800', '#f44336', '#9c27b0',
    '#00bcd4', '#8bc34a', '#ffc107', '#e91e63', '#673ab7',
    '#009688', '#cddc39', '#ff5722', '#3f51b5', '#795548'
  ];
  
  const result = [];
  for (let i = 0; i < count; i++) {
    result.push(colors[i % colors.length]);
  }
  
  return result;
};

// Security type icons/colors
export const getSecurityTypeInfo = (securityType) => {
  const typeMap = {
    'Stock': { color: '#2196f3', icon: 'TrendingUp' },
    'ETF': { color: '#4caf50', icon: 'PieChart' },
    'Bond': { color: '#ff9800', icon: 'AccountBalance' },
    'Mutual Fund': { color: '#9c27b0', icon: 'Group' },
    'Crypto': { color: '#ff5722', icon: 'CurrencyBitcoin' }
  };
  
  return typeMap[securityType] || { color: '#757575', icon: 'Help' };
};

// Asset class icons
export const getAssetClassIcon = (assetClass) => {
  const iconMap = {
    'Cash & Equivalents': 'AccountBalance',
    'Equities': 'TrendingUp',
    'Fixed Income': 'AccountBalance',
    'Real Estate': 'Home',
    'Commodities': 'Category',
    'Collectibles': 'Star',
    'Cryptocurrency': 'CurrencyBitcoin',
    'Alternative Investments': 'Explore',
    'Personal Property': 'DirectionsCar',
    'Business Interests': 'Business'
  };
  
  return iconMap[assetClass] || 'Help';
};