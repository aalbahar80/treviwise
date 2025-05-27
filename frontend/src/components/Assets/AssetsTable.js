// src/components/Assets/AssetsTable.js
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
  Icon,
} from '@mui/material';
import {
  AccountBalance,
  TrendingUp,
  Home,
  Category,
  Star,
  Business,
  DirectionsCar,
  Help,
} from '@mui/icons-material';

import { formatCurrency, formatRelativeDate, getAssetClassIcon } from '../../utils/formatters';

function AssetsTable({ assets }) {
  if (!assets || assets.length === 0) {
    return (
      <Box textAlign="center" py={4}>
        <Typography variant="body1" color="text.secondary">
          No assets found
        </Typography>
      </Box>
    );
  }

  const getAssetClassIconComponent = (assetClass) => {
    const iconComponents = {
      'AccountBalance': AccountBalance,
      'TrendingUp': TrendingUp,
      'Home': Home,
      'Category': Category,
      'Star': Star,
      'Business': Business,
      'DirectionsCar': DirectionsCar,
      'Help': Help,
    };
    
    const iconName = getAssetClassIcon(assetClass);
    const IconComponent = iconComponents[iconName] || Help;
    return <IconComponent />;
  };

  const getAssetTypeColor = (assetType) => {
    return assetType === 'Tangible' ? 'primary' : 'secondary';
  };

  return (
    <TableContainer component={Paper} variant="outlined">
      <Table>
        <TableHead>
          <TableRow>
            <TableCell>Asset Name</TableCell>
            <TableCell>Class</TableCell>
            <TableCell>Type</TableCell>
            <TableCell align="right">Value</TableCell>
            <TableCell>Currency</TableCell>
            <TableCell>Institution</TableCell>
            <TableCell>Location</TableCell>
            <TableCell>Last Updated</TableCell>
          </TableRow>
        </TableHead>
        <TableBody>
          {assets.map((asset, index) => (
            <TableRow key={asset.asset_id || index} hover>
              <TableCell>
                <Box>
                  <Typography variant="body1" fontWeight="500">
                    {asset.asset_name}
                  </Typography>
                  {asset.description && (
                    <Typography variant="caption" color="text.secondary">
                      {asset.description}
                    </Typography>
                  )}
                </Box>
              </TableCell>
              <TableCell>
                <Box display="flex" alignItems="center">
                  {getAssetClassIconComponent(asset.asset_class)}
                  <Typography variant="body2" sx={{ ml: 1 }}>
                    {asset.asset_class}
                  </Typography>
                </Box>
              </TableCell>
              <TableCell>
                <Chip
                  label={asset.asset_type}
                  size="small"
                  color={getAssetTypeColor(asset.asset_type)}
                  variant="outlined"
                />
              </TableCell>
              <TableCell align="right">
                <Typography variant="body1" fontWeight="bold">
                  {formatCurrency(asset.current_value_original, asset.base_currency)}
                </Typography>
                {asset.base_currency !== 'USD' && (
                  <Typography variant="caption" color="text.secondary" display="block">
                    {formatCurrency(asset.current_value_usd, 'USD')}
                  </Typography>
                )}
              </TableCell>
              <TableCell>
                <Chip
                  label={asset.base_currency}
                  size="small"
                  variant="outlined"
                />
              </TableCell>
              <TableCell>
                <Typography variant="body2">
                  {asset.institution_name}
                </Typography>
              </TableCell>
              <TableCell>
                <Typography variant="body2" color="text.secondary">
                  {asset.location}
                </Typography>
              </TableCell>
              <TableCell>
                <Typography variant="caption" color="text.secondary">
                  {formatRelativeDate(asset.last_manual_update || asset.last_api_update)}
                </Typography>
              </TableCell>
            </TableRow>
          ))}
        </TableBody>
      </Table>
    </TableContainer>
  );
}

export default AssetsTable;