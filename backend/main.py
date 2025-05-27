# main.py - FastAPI Backend for Wealth Tracker
"""
FastAPI backend providing REST API for wealth tracker dashboard
"""

from fastapi import FastAPI, HTTPException, Depends
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
import psycopg2
from psycopg2.extras import RealDictCursor
from typing import List, Dict, Any, Optional
from datetime import datetime, date, timedelta
from decimal import Decimal
import os
from dataclasses import dataclass
import uvicorn
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

# Configuration
class Config:
    DB_HOST = os.getenv("DB_HOST", "localhost")
    DB_NAME = os.getenv("DB_NAME", "treviwise")
    DB_USER = os.getenv("DB_USER", "postgres")
    DB_PASSWORD = os.getenv("DB_PASSWORD")
    DB_PORT = os.getenv("DB_PORT", "5432")
    
    # API Configuration
    API_HOST = os.getenv("API_HOST", "0.0.0.0")
    API_PORT = int(os.getenv("API_PORT", "8000"))
    
    # CORS Configuration
    CORS_ORIGINS = os.getenv("CORS_ORIGINS", "http://localhost:3000").split(",")
    
    # Application Settings
    DEBUG = os.getenv("DEBUG", "false").lower() == "true"
    SECRET_KEY = os.getenv("SECRET_KEY", "your_super_secret_key_here")
    LOG_LEVEL = os.getenv("LOG_LEVEL", "INFO")
    
    # API Keys
    FMP_API_KEY = os.getenv("FMP_API_KEY")
    
    @property
    def database_url(self):
        if not self.DB_PASSWORD:
            raise ValueError("DB_PASSWORD environment variable is required")
        return f"postgresql://{self.DB_USER}:{self.DB_PASSWORD}@{self.DB_HOST}:{self.DB_PORT}/{self.DB_NAME}"

config = Config()

# FastAPI app
app = FastAPI(
    title="Treviwise API",
    description="API for personal wealth and investment tracking",
    version="1.0.0",
    debug=config.DEBUG
)

# Enable CORS for React frontend
app.add_middleware(
    CORSMiddleware,
    allow_origins=config.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Database dependency
def get_db_connection():
    try:
        conn = psycopg2.connect(config.database_url, cursor_factory=RealDictCursor)
        return conn
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Database connection failed: {str(e)}")

# Custom JSON encoder for Decimal and datetime
class DecimalEncoder:
    @staticmethod
    def default(obj):
        if isinstance(obj, Decimal):
            return float(obj)
        if isinstance(obj, (datetime, date)):
            return obj.isoformat()
        raise TypeError

def serialize_response(data):
    """Convert Decimals to floats for JSON serialization"""
    if isinstance(data, list):
        return [serialize_response(item) for item in data]
    elif isinstance(data, dict):
        return {key: serialize_response(value) for key, value in data.items()}
    elif isinstance(data, Decimal):
        return float(data)
    elif isinstance(data, (datetime, date)):
        return data.isoformat()
    else:
        return data

# API Routes

@app.get("/")
async def root():
    return {"message": "Treviwise API", "version": "1.0.0", "environment": "development" if config.DEBUG else "production"}

@app.get("/api/health")
async def health_check():
    """Health check endpoint"""
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("SELECT 1")
        cursor.fetchone()
        conn.close()
        return {"status": "healthy", "timestamp": datetime.now(), "database": "connected"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Health check failed: {str(e)}")

@app.get("/api/portfolio/summary")
async def get_portfolio_summary():
    """Get overall portfolio summary"""
    conn = get_db_connection()
    try:
        cursor = conn.cursor()
        
        # Get total portfolio value and P&L
        cursor.execute("""
            SELECT 
                SUM(p.quantity * p.average_cost_basis) as total_cost_basis,
                SUM(p.market_value) as total_market_value,
                SUM(p.unrealized_gain_loss) as total_unrealized_gain_loss,
                COUNT(*) as total_positions
            FROM positions p
            WHERE p.quantity > 0
        """)
        portfolio_totals = cursor.fetchone()
        
        # Get account breakdown
        cursor.execute("""
            SELECT 
                i.institution_name,
                ia.cash_balance,
                COALESCE(SUM(p.market_value), 0) as positions_value,
                ia.cash_balance + COALESCE(SUM(p.market_value), 0) as total_account_value
            FROM investment_accounts ia
            JOIN institutions i ON ia.institution_id = i.institution_id
            LEFT JOIN positions p ON ia.account_id = p.account_id
            WHERE ia.is_active = TRUE
            GROUP BY ia.account_id, i.institution_name, ia.cash_balance
            ORDER BY total_account_value DESC
        """)
        accounts = cursor.fetchall()
        
        # Get asset class breakdown
        cursor.execute("""
            SELECT 
                asset_class,
                COUNT(*) as count,
                SUM(value_usd) as total_value,
                ROUND(SUM(value_usd) / (SELECT SUM(value_usd) FROM current_net_worth_detailed) * 100, 2) as percentage
            FROM current_net_worth_detailed
            GROUP BY asset_class
            ORDER BY total_value DESC
        """)
        asset_classes = cursor.fetchall()
        
        return JSONResponse(content=serialize_response({
            "portfolio_totals": portfolio_totals,
            "accounts": accounts,
            "asset_classes": asset_classes,
            "last_updated": datetime.now()
        }))
        
    finally:
        conn.close()

@app.get("/api/positions")
async def get_positions():
    """Get all current positions"""
    conn = get_db_connection()
    try:
        cursor = conn.cursor()
        cursor.execute("""
            SELECT 
                p.symbol,
                sm.security_name,
                sm.security_type,
                p.quantity,
                p.average_cost_basis,
                p.current_price,
                p.market_value,
                p.unrealized_gain_loss,
                p.unrealized_gain_loss_percent,
                p.currency,
                p.last_updated,
                i.institution_name as brokerage
            FROM positions p
            JOIN securities_master sm ON p.symbol = sm.symbol
            JOIN investment_accounts ia ON p.account_id = ia.account_id
            JOIN institutions i ON ia.institution_id = i.institution_id
            WHERE p.quantity > 0
            ORDER BY p.market_value DESC
        """)
        positions = cursor.fetchall()
        
        return JSONResponse(content=serialize_response(positions))
        
    finally:
        conn.close()

@app.get("/api/assets")
async def get_assets():
    """Get all assets"""
    conn = get_db_connection()
    try:
        cursor = conn.cursor()
        cursor.execute("""
            SELECT 
                a.asset_id,
                a.asset_name,
                a.asset_type,
                ac.class_name as asset_class,
                a.current_value_original,
                a.current_value_usd,
                a.base_currency,
                a.location,
                i.institution_name,
                a.last_manual_update,
                a.last_api_update
            FROM assets a
            JOIN asset_classes ac ON a.class_id = ac.class_id
            JOIN institutions i ON a.institution_id = i.institution_id
            WHERE a.is_active = TRUE
            ORDER BY a.current_value_usd DESC
        """)
        assets = cursor.fetchall()
        
        return JSONResponse(content=serialize_response(assets))
        
    finally:
        conn.close()

@app.get("/api/dividends")
async def get_recent_dividends(limit: int = 20):
    """Get recent dividend payments"""
    conn = get_db_connection()
    try:
        cursor = conn.cursor()
        cursor.execute("""
            SELECT 
                d.symbol,
                sm.security_name,
                d.ex_dividend_date,
                d.payment_date,
                d.dividend_amount,
                d.frequency,
                -- Calculate total dividend for owned position
                CASE 
                    WHEN p.quantity IS NOT NULL THEN d.dividend_amount * p.quantity
                    ELSE 0
                END as total_dividend_received
            FROM dividends d
            JOIN securities_master sm ON d.symbol = sm.symbol
            LEFT JOIN positions p ON d.symbol = p.symbol AND p.quantity > 0
            WHERE d.ex_dividend_date >= CURRENT_DATE - INTERVAL '1 year'
            ORDER BY d.ex_dividend_date DESC
            LIMIT %s
        """, (limit,))
        dividends = cursor.fetchall()
        
        return JSONResponse(content=serialize_response(dividends))
        
    finally:
        conn.close()

@app.get("/api/net-worth")
async def get_net_worth():
    """Get detailed net worth breakdown"""
    conn = get_db_connection()
    try:
        cursor = conn.cursor()
        
        # Refresh materialized view first
        cursor.execute("SELECT refresh_net_worth_view()")
        
        # Get detailed breakdown
        cursor.execute("""
            SELECT 
                source_type,
                source_name,
                asset_class,
                value_original,
                value_usd,
                base_currency
            FROM current_net_worth_detailed
            ORDER BY value_usd DESC
        """)
        detailed_breakdown = cursor.fetchall()
        
        # Get summary by asset class
        cursor.execute("""
            SELECT 
                asset_class,
                COUNT(*) as items,
                SUM(value_usd) as total_value,
                ROUND(SUM(value_usd) / (SELECT SUM(value_usd) FROM current_net_worth_detailed) * 100, 2) as percentage
            FROM current_net_worth_detailed
            GROUP BY asset_class
            ORDER BY total_value DESC
        """)
        summary = cursor.fetchall()
        
        # Calculate total net worth
        total_net_worth = sum(item['total_value'] for item in summary)
        
        return JSONResponse(content=serialize_response({
            "total_net_worth": total_net_worth,
            "summary_by_class": summary,
            "detailed_breakdown": detailed_breakdown,
            "last_updated": datetime.now()
        }))
        
    finally:
        conn.close()

@app.get("/api/asset/{asset_id}/history")
async def get_asset_history(asset_id: int, days: int = 90):
    """Get value history for a specific asset"""
    conn = get_db_connection()
    try:
        cursor = conn.cursor()
        cursor.execute("""
            SELECT * FROM get_asset_value_history(%s, %s)
        """, (asset_id, date.today() - timedelta(days=days)))
        
        history = cursor.fetchall()
        return JSONResponse(content=serialize_response(history))
        
    finally:
        conn.close()

@app.get("/api/market-prices")
async def get_latest_market_prices():
    """Get latest market prices for all securities"""
    conn = get_db_connection()
    try:
        cursor = conn.cursor()
        cursor.execute("""
            SELECT 
                mp.symbol,
                sm.security_name,
                mp.price,
                mp.price_date,
                mp.created_at
            FROM market_prices mp
            JOIN securities_master sm ON mp.symbol = sm.symbol
            WHERE mp.price_date = CURRENT_DATE
            ORDER BY mp.symbol
        """)
        prices = cursor.fetchall()
        
        return JSONResponse(content=serialize_response(prices))
        
    finally:
        conn.close()

@app.post("/api/refresh-data")
async def refresh_market_data():
    """Trigger market data refresh"""
    try:
        # This could trigger your market_data_service.py script
        # For now, just refresh the materialized view
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("SELECT refresh_net_worth_view()")
        conn.commit()
        conn.close()
        
        return {"message": "Data refreshed successfully", "timestamp": datetime.now()}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Refresh failed: {str(e)}")

if __name__ == "__main__":
    uvicorn.run(
        "main:app", 
        host=config.API_HOST, 
        port=config.API_PORT, 
        reload=config.DEBUG,
        log_level=config.LOG_LEVEL.lower()
    )
