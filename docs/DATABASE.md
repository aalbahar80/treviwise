# Treviwise Database Guide

Complete guide to database schema, data management, and advanced operations.

## 📊 Database Overview

Treviwise uses PostgreSQL as its primary database, designed for personal wealth tracking with support for multiple asset types, currencies, and automated market data integration.

### Key Features
- **Multi-currency support** with automatic conversion
- **Real-time market data integration** via APIs
- **Historical value tracking** for all assets
- **Automated calculations** for gains/losses and portfolio metrics
- **Materialized views** for optimized performance

---

## 🏗️ Database Architecture

### File Structure
```
database/
├── 01_schema.sql              # Core tables, indexes, constraints
├── 02_schema_enhancements.sql # Functions, views, triggers
├── sample_data.sql           # Demo data for testing
└── migrations/               # Future schema changes
    ├── 001_add_feature.sql
    └── 002_update_schema.sql
```

### Setup Order
1. **Core Schema** → Tables and relationships
2. **Enhancements** → Functions, views, and triggers
3. **Sample Data** → Optional demo data

---

## 📋 Database Schema

### Core Tables

#### **institutions**
Financial institutions (banks, brokerages, etc.)
```sql
CREATE TABLE institutions (
    institution_id SERIAL PRIMARY KEY,
    institution_name VARCHAR(255) NOT NULL,
    institution_type VARCHAR(50),  -- 'Bank', 'Brokerage', 'Credit Union'
    website VARCHAR(255),
    contact_phone VARCHAR(20),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

#### **asset_classes**
Asset classification system
```sql
CREATE TABLE asset_classes (
    class_id SERIAL PRIMARY KEY,
    class_name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    parent_class_id INTEGER REFERENCES asset_classes(class_id)
);
```

#### **assets**
All trackable assets (accounts, properties, vehicles, etc.)
```sql
CREATE TABLE assets (
    asset_id SERIAL PRIMARY KEY,
    asset_name VARCHAR(255) NOT NULL,
    asset_type VARCHAR(100) NOT NULL,  -- 'Bank Account', 'Real Estate', etc.
    class_id INTEGER REFERENCES asset_classes(class_id),
    institution_id INTEGER REFERENCES institutions(institution_id),
    current_value_original NUMERIC(15,4),
    current_value_usd NUMERIC(15,4),
    base_currency VARCHAR(3) DEFAULT 'USD',
    location VARCHAR(255),
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    last_manual_update TIMESTAMP,
    last_api_update TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

#### **investment_accounts**
Investment/trading accounts linked to assets
```sql
CREATE TABLE investment_accounts (
    account_id SERIAL PRIMARY KEY,
    asset_id INTEGER REFERENCES assets(asset_id),
    institution_id INTEGER REFERENCES institutions(institution_id),
    account_name VARCHAR(255),
    account_type VARCHAR(50),  -- 'Brokerage', 'IRA', '401k'
    account_number_encrypted VARCHAR(255),
    base_currency VARCHAR(3) DEFAULT 'USD',
    cash_balance NUMERIC(15,4) DEFAULT 0,
    cash_balance_last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE,
    last_sync TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

#### **securities_master**
Securities reference data (stocks, ETFs, bonds)
```sql
CREATE TABLE securities_master (
    symbol VARCHAR(20) PRIMARY KEY,
    security_name VARCHAR(255) NOT NULL,
    security_type VARCHAR(50),  -- 'Stock', 'ETF', 'Bond'
    exchange VARCHAR(50),
    sector VARCHAR(100),
    industry VARCHAR(100),
    currency VARCHAR(3) DEFAULT 'USD',
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

#### **positions**
Investment positions (holdings in securities)
```sql
CREATE TABLE positions (
    position_id SERIAL PRIMARY KEY,
    account_id INTEGER REFERENCES investment_accounts(account_id),
    symbol VARCHAR(20) REFERENCES securities_master(symbol),
    quantity NUMERIC(15,6) NOT NULL,
    average_cost_basis NUMERIC(12,4),
    current_price NUMERIC(12,4),
    market_value NUMERIC(15,4),
    unrealized_gain_loss NUMERIC(15,4),
    unrealized_gain_loss_percent NUMERIC(8,4),
    currency VARCHAR(3) DEFAULT 'USD',
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### Supporting Tables

#### **market_prices**
Current and historical market prices
```sql
CREATE TABLE market_prices (
    symbol VARCHAR(20) REFERENCES securities_master(symbol),
    price NUMERIC(12,4) NOT NULL,
    price_date DATE NOT NULL,
    currency VARCHAR(3) DEFAULT 'USD',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (symbol, price_date)
);
```

#### **exchange_rates**
Currency exchange rates
```sql
CREATE TABLE exchange_rates (
    from_currency VARCHAR(3),
    to_currency VARCHAR(3),
    rate NUMERIC(12,6) NOT NULL,
    rate_date DATE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (from_currency, to_currency, rate_date)
);
```

#### **asset_valuations**
Historical asset value tracking
```sql
CREATE TABLE asset_valuations (
    valuation_id SERIAL PRIMARY KEY,
    asset_id INTEGER REFERENCES assets(asset_id),
    valuation_date DATE NOT NULL,
    value_original_currency NUMERIC(15,4),
    value_usd NUMERIC(15,4),
    valuation_method VARCHAR(30),  -- 'Manual', 'API', 'System'
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

---

## 🔧 Functions and Views

### Core Functions

#### **refresh_net_worth_view()**
Refreshes the main materialized view
```sql
CREATE OR REPLACE FUNCTION refresh_net_worth_view()
RETURNS VOID AS $$
BEGIN
    REFRESH MATERIALIZED VIEW current_net_worth_detailed;
END;
$$ LANGUAGE plpgsql;
```

#### **get_asset_value_history()**
Retrieves historical values for charting
```sql
SELECT * FROM get_asset_value_history(asset_id, start_date, end_date);
```

### Key Views

#### **current_net_worth_detailed** (Materialized View)
Consolidated view of all wealth sources
- Direct assets (real estate, vehicles, etc.)
- Investment account cash balances
- Investment positions (stocks, ETFs, bonds)

#### **account_total_values** (Regular View)
Summary of account values (cash + positions)

### Automated Triggers

#### **track_asset_value_changes()**
Automatically creates history records when asset values change

---

## 💾 Data Management

### Database Setup Commands

#### Automated Setup (Recommended)
```bash
# Interactive setup with sample data
./scripts/setup_database.sh

# Empty database only
./scripts/setup_database.sh --no-sample-data

# Custom database name
./scripts/setup_database.sh --database my_treviwise
```

#### Manual Setup
```bash
# Create database
createdb -U postgres treviwise

# Load core schema
psql -U postgres -d treviwise -f database/01_schema.sql

# Load enhancements (functions, views, triggers)
psql -U postgres -d treviwise -f database/02_schema_enhancements.sql

# Load sample data (optional)
psql -U postgres -d treviwise -f database/sample_data.sql
```

### Database Operations

#### Backup and Restore
```bash
# Full backup (schema + data)
pg_dump -U postgres treviwise > backup.sql

# Schema only backup
pg_dump -U postgres --schema-only treviwise > schema_backup.sql

# Data only backup
pg_dump -U postgres --data-only treviwise > data_backup.sql

# Restore from backup
psql -U postgres -d new_database -f backup.sql
```

#### Performance Maintenance
```bash
# Refresh materialized views
psql -U postgres -d treviwise -c "SELECT refresh_net_worth_view();"

# Update table statistics
psql -U postgres -d treviwise -c "ANALYZE;"

# Rebuild indexes (if needed)
psql -U postgres -d treviwise -c "REINDEX DATABASE treviwise;"
```

---

## 📊 Sample Data

### What's Included
- **4 Financial institutions** (banks, brokerages)
- **7 Asset classes** (stocks, bonds, cash, real estate, etc.)
- **4 Investment accounts** with realistic balances
- **7 Securities** (major stocks and ETFs)
- **6 Investment positions** with current prices
- **3 Alternative assets** (real estate, vehicle, collectibles)
- **Current market prices** and exchange rates
- **Sample dividend data**

### Sample Data Overview
```sql
-- View sample data summary
SELECT 
    'Institutions' as item, COUNT(*) as count FROM institutions
UNION ALL
SELECT 'Assets', COUNT(*) FROM assets WHERE is_active = true
UNION ALL  
SELECT 'Accounts', COUNT(*) FROM investment_accounts WHERE is_active = true
UNION ALL
SELECT 'Positions', COUNT(*) FROM positions WHERE quantity > 0
UNION ALL
SELECT 'Securities', COUNT(*) FROM securities_master WHERE is_active = true;
```

### Loading Sample Data
```bash
# Load sample data
psql -U postgres -d treviwise -f database/sample_data.sql

# Verify sample data
psql -U postgres -d treviwise -c "SELECT COUNT(*) FROM positions;"
```

---

## 🔄 Migrations

### Migration Strategy
Future schema changes will be managed through numbered migration files:

```bash
database/migrations/
├── 001_add_crypto_support.sql
├── 002_add_goal_tracking.sql
└── 003_enhance_reporting.sql
```

### Creating Migrations
```sql
-- Migration template
-- Migration: 001_description
-- Date: YYYY-MM-DD
-- Author: Your Name

BEGIN;

-- Add your changes here
ALTER TABLE assets ADD COLUMN new_field VARCHAR(100);

-- Update version
INSERT INTO schema_versions (version, description, applied_at) 
VALUES ('001', 'Add new field to assets', CURRENT_TIMESTAMP);

COMMIT;
```

---

## 🛠️ Development Tools

### Useful Queries

#### Database Status Check
```sql
-- Check table sizes
SELECT 
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size
FROM pg_tables 
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;
```

#### Data Quality Checks
```sql
-- Check for orphaned records
SELECT 'Positions without accounts' as check, COUNT(*) 
FROM positions p 
LEFT JOIN investment_accounts ia ON p.account_id = ia.account_id 
WHERE ia.account_id IS NULL;

-- Check for missing market prices
SELECT DISTINCT symbol 
FROM positions 
WHERE symbol NOT IN (
    SELECT symbol FROM market_prices 
    WHERE price_date = CURRENT_DATE
);
```

#### Performance Monitoring
```sql
-- Check materialized view freshness
SELECT 
    matviewname,
    ispopulated,
    (SELECT COUNT(*) FROM current_net_worth_detailed) as row_count
FROM pg_matviews 
WHERE matviewname = 'current_net_worth_detailed';
```

### Development Workflow
1. **Make schema changes** in development database
2. **Test thoroughly** with sample data
3. **Create migration file** for the change
4. **Update documentation** if needed
5. **Test migration** on fresh database

---

## 📈 Performance Optimization

### Indexes
Key indexes for optimal performance:
- `idx_asset_valuations_asset_date` - Asset history queries
- `idx_positions_account_symbol` - Position lookups
- `idx_transactions_account_date` - Transaction history

### Query Optimization
- Use materialized views for complex aggregations
- Refresh materialized views after bulk data updates
- Use appropriate date ranges for historical queries

---

## 🔒 Security Considerations

### Data Protection
- **No real financial data** in sample datasets
- **Environment variables** for all sensitive configuration
- **Encrypted storage** for account numbers (when implemented)

### Access Control
- Use dedicated database user for application
- Limit permissions to required tables only
- Regular backup encryption for production

---

## 🆘 Troubleshooting

### Common Issues

**Materialized view not populated:**
```sql
-- Check if view exists and is populated
SELECT matviewname, ispopulated FROM pg_matviews;

-- Refresh manually
REFRESH MATERIALIZED VIEW current_net_worth_detailed;
```

**Missing dependencies:**
```sql
-- Check for missing tables
SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';

-- Should return 10+ tables
```

**Performance issues:**
```sql
-- Check for missing indexes
SELECT * FROM pg_stat_user_tables WHERE idx_scan = 0;

-- Analyze query performance
EXPLAIN ANALYZE SELECT * FROM current_net_worth_detailed;
```

---

## 📞 Support

For database-specific issues:
- **Schema Questions**: Check this documentation
- **Migration Issues**: See migration examples above  
- **Performance Problems**: Review optimization section
- **Data Issues**: Use development tools section

**Related Documentation:**
- [SETUP.md](SETUP.md) - Installation guide
- [API.md](API.md) - Backend API documentation
- [DEPLOYMENT.md](DEPLOYMENT.md) - Production deployment