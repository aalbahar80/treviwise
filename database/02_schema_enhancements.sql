-- Enhancement 1: Automatic Asset Value Change Tracking
-- =====================================================

CREATE OR REPLACE FUNCTION track_asset_value_changes()
RETURNS TRIGGER AS $$
BEGIN
    -- Only create history record if value actually changed
    IF OLD.current_value_original IS DISTINCT FROM NEW.current_value_original THEN
        INSERT INTO asset_valuations (
            asset_id,
            valuation_date,
            value_original_currency,
            value_usd,
            valuation_method,
            notes
        ) VALUES (
            NEW.asset_id,
            CURRENT_DATE,
            NEW.current_value_original,
            NEW.current_value_usd,
            CASE 
                WHEN NEW.last_api_update > COALESCE(OLD.last_api_update, '1900-01-01') THEN 'API'
                WHEN NEW.last_manual_update > COALESCE(OLD.last_manual_update, '1900-01-01') THEN 'Manual'
                ELSE 'System'
            END,
            'Auto-tracked value change from ' || COALESCE(OLD.current_value_original, 0) || ' to ' || NEW.current_value_original
        );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create the trigger
CREATE TRIGGER asset_value_change_trigger
    AFTER UPDATE ON assets
    FOR EACH ROW
    EXECUTE FUNCTION track_asset_value_changes();

-- Enhancement 2: Complete Account Values View (Cash + Positions)
-- =====================================================

CREATE VIEW account_total_values AS
SELECT 
    ia.account_id,
    a.asset_name as account_name,
    ia.cash_balance,
    COALESCE(SUM(p.market_value), 0) as positions_value,
    ia.cash_balance + COALESCE(SUM(p.market_value), 0) as total_account_value,
    ia.base_currency,
    ia.last_sync,
    COUNT(p.position_id) as positions_count
FROM investment_accounts ia
JOIN assets a ON ia.asset_id = a.asset_id
LEFT JOIN positions p ON ia.account_id = p.account_id
WHERE ia.is_active = TRUE
GROUP BY ia.account_id, a.asset_name, ia.cash_balance, ia.base_currency, ia.last_sync;

-- Enhancement 3: Add cash balance tracking fields
-- =====================================================

ALTER TABLE investment_accounts 
ADD COLUMN IF NOT EXISTS cash_balance_last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
ADD COLUMN IF NOT EXISTS cash_balance_update_method VARCHAR(20) DEFAULT 'Manual';

-- Enhancement 4: Asset Value History Function for Charts
-- =====================================================

CREATE OR REPLACE FUNCTION get_asset_value_history(
    p_asset_id INTEGER,
    p_start_date DATE DEFAULT NULL,
    p_end_date DATE DEFAULT CURRENT_DATE
)
RETURNS TABLE(
    valuation_date DATE,
    value_original NUMERIC(15,4),
    value_usd NUMERIC(15,4),
    update_method VARCHAR(30)
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        av.valuation_date,
        av.value_original_currency,
        av.value_usd,
        av.valuation_method
    FROM asset_valuations av
    WHERE av.asset_id = p_asset_id
    AND av.valuation_date >= COALESCE(p_start_date, '1900-01-01')
    AND av.valuation_date <= p_end_date
    ORDER BY av.valuation_date;
END;
$$ LANGUAGE plpgsql;

-- Enhancement 5: Net Worth Calculation View
-- =====================================================

CREATE MATERIALIZED VIEW current_net_worth_detailed AS
SELECT 
    -- Direct assets (bank accounts, real estate, etc.)
    'Direct Asset' as source_type,
    a.asset_id as source_id,
    a.asset_name as source_name,
    ac.class_name as asset_class,
    a.current_value_original as value_original,
    a.current_value_usd as value_usd,
    a.base_currency,
    a.last_manual_update,
    a.last_api_update
FROM assets a
JOIN asset_classes ac ON a.class_id = ac.class_id
WHERE a.is_active = TRUE
-- Exclude trading accounts since they're handled separately below
AND a.asset_id NOT IN (SELECT asset_id FROM investment_accounts WHERE asset_id IS NOT NULL)

UNION ALL

SELECT 
    -- Investment account cash
    'Account Cash' as source_type,
    ia.account_id as source_id,
    a.asset_name || ' (Cash)' as source_name,
    'Cash & Equivalents' as asset_class,
    ia.cash_balance as value_original,
    ia.cash_balance as value_usd, -- Will need currency conversion later
    ia.base_currency,
    ia.cash_balance_last_updated as last_manual_update,
    ia.last_sync as last_api_update
FROM investment_accounts ia
JOIN assets a ON ia.asset_id = a.asset_id
WHERE ia.is_active = TRUE AND ia.cash_balance > 0

UNION ALL

SELECT 
    -- Investment positions
    'Investment Position' as source_type,
    p.position_id as source_id,
    sm.security_name || ' (' || a.asset_name || ')' as source_name,
    CASE sm.security_type
        WHEN 'Stock' THEN 'Equities'
        WHEN 'ETF' THEN 'Equities'
        WHEN 'Bond' THEN 'Fixed Income'
        ELSE 'Alternative Investments'
    END as asset_class,
    COALESCE(p.market_value, p.quantity * p.average_cost_basis) as value_original,
    COALESCE(p.market_value, p.quantity * p.average_cost_basis) as value_usd,
    p.currency as base_currency,
    p.last_updated as last_manual_update,
    p.last_updated as last_api_update
FROM positions p
JOIN investment_accounts ia ON p.account_id = ia.account_id
JOIN assets a ON ia.asset_id = a.asset_id
JOIN securities_master sm ON p.symbol = sm.symbol
WHERE ia.is_active = TRUE AND p.quantity > 0;

-- Enhancement 6: Useful Indexes for Performance
-- =====================================================

CREATE INDEX IF NOT EXISTS idx_asset_valuations_asset_date ON asset_valuations(asset_id, valuation_date DESC);
CREATE INDEX IF NOT EXISTS idx_positions_account_symbol ON positions(account_id, symbol);
CREATE INDEX IF NOT EXISTS idx_transactions_account_date ON transactions(account_id, transaction_date DESC);

-- Enhancement 7: Refresh Function for Materialized View
-- =====================================================

CREATE OR REPLACE FUNCTION refresh_net_worth_view()
RETURNS VOID AS $$
BEGIN
    REFRESH MATERIALIZED VIEW current_net_worth_detailed;
END;
$$ LANGUAGE plpgsql;

-- Test the enhancements
-- =====================================================

-- Test 1: View your current net worth breakdown
SELECT 
    asset_class,
    COUNT(*) as items,
    SUM(value_usd) as total_value_usd,
    ROUND(SUM(value_usd) / (SELECT SUM(value_usd) FROM current_net_worth_detailed) * 100, 2) as percentage
FROM current_net_worth_detailed
GROUP BY asset_class
ORDER BY total_value_usd DESC;

-- Test 2: View account totals
SELECT * FROM account_total_values;

-- Test 3: Test the value history function (will show your initial migration data)
SELECT * FROM get_asset_value_history(1); -- Replace 1 with actual asset_id

-- Test 4: Show all current asset values
SELECT 
    source_name,
    asset_class,
    value_original,
    base_currency,
    value_usd
FROM current_net_worth_detailed
ORDER BY value_usd DESC;

-- Verification: Check that trigger is working
-- =====================================================
SELECT 
    'Trigger exists' as check_type,
    EXISTS (
        SELECT 1 FROM information_schema.triggers 
        WHERE trigger_name = 'asset_value_change_trigger'
    ) as status;

-- Success message
SELECT 'Schema enhancements successfully added!' as message;