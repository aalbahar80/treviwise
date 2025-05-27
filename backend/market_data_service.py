# market_data_service.py
"""
Local Market Data Service for Wealth Tracker
Fetches market prices and updates PostgreSQL database
"""

import os
import asyncio
import aiohttp
import psycopg2
from psycopg2.extras import RealDictCursor
import pandas as pd
from datetime import datetime, date
import logging
from typing import List, Dict, Optional
from dataclasses import dataclass
import json
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

# Setup logging
log_level = os.getenv("LOG_LEVEL", "INFO").upper()
log_file = os.getenv("LOG_FILE", "treviwise.log")

logging.basicConfig(
    level=getattr(logging, log_level),
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler(log_file),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

@dataclass
class SecurityPrice:
    symbol: str
    price: float
    currency: str
    date: str
    change_percent: Optional[float] = None

@dataclass
class ExchangeRate:
    from_currency: str
    to_currency: str
    rate: float
    date: str

class DatabaseManager:
    def __init__(self, connection_string: str):
        self.connection_string = connection_string
    
    def get_connection(self):
        """Get database connection"""
        try:
            conn = psycopg2.connect(self.connection_string, cursor_factory=RealDictCursor)
            return conn
        except Exception as e:
            logger.error(f"Database connection failed: {e}")
            raise
    
    def get_active_symbols(self) -> List[str]:
        """Get list of symbols that need price updates"""
        conn = self.get_connection()
        try:
            cursor = conn.cursor()
            cursor.execute("""
                SELECT DISTINCT symbol 
                FROM securities_master 
                WHERE is_active = TRUE
                AND symbol IN (
                    SELECT DISTINCT symbol FROM positions
                    WHERE quantity > 0
                )
                ORDER BY symbol
            """)
            return [row['symbol'] for row in cursor.fetchall()]
        finally:
            conn.close()
    
    def update_market_prices(self, prices: List[SecurityPrice]):
        """Update market prices in database"""
        conn = self.get_connection()
        try:
            cursor = conn.cursor()
            
            for price in prices:
                cursor.execute("""
                    INSERT INTO market_prices (symbol, price, price_date, currency, created_at)
                    VALUES (%s, %s, %s, %s, %s)
                    ON CONFLICT (symbol, price_date) 
                    DO UPDATE SET 
                        price = EXCLUDED.price,
                        created_at = EXCLUDED.created_at
                """, (price.symbol, price.price, price.date, price.currency, datetime.now()))
            
            conn.commit()
            logger.info(f"Updated prices for {len(prices)} securities")
            
        except Exception as e:
            conn.rollback()
            logger.error(f"Failed to update market prices: {e}")
            raise
        finally:
            conn.close()
    
    def update_exchange_rates(self, rates: List[ExchangeRate]):
        """Update exchange rates in database"""
        conn = self.get_connection()
        try:
            cursor = conn.cursor()
            
            for rate in rates:
                cursor.execute("""
                    INSERT INTO exchange_rates (from_currency, to_currency, rate, rate_date, created_at)
                    VALUES (%s, %s, %s, %s, %s)
                    ON CONFLICT (from_currency, to_currency, rate_date)
                    DO UPDATE SET 
                        rate = EXCLUDED.rate,
                        created_at = EXCLUDED.created_at
                """, (rate.from_currency, rate.to_currency, rate.rate, rate.date, datetime.now()))
            
            conn.commit()
            logger.info(f"Updated {len(rates)} exchange rates")
            
        except Exception as e:
            conn.rollback()
            logger.error(f"Failed to update exchange rates: {e}")
            raise
        finally:
            conn.close()
    
    def update_position_values(self):
        """Update position market values and calculations"""
        conn = self.get_connection()
        try:
            cursor = conn.cursor()
            
            # Update positions with current market prices
            cursor.execute("""
                UPDATE positions 
                SET 
                    current_price = mp.price,
                    market_value = positions.quantity * mp.price,
                    unrealized_gain_loss = (positions.quantity * mp.price) - (positions.quantity * positions.average_cost_basis),
                    unrealized_gain_loss_percent = 
                        CASE 
                            WHEN positions.average_cost_basis > 0 THEN
                                ((mp.price - positions.average_cost_basis) / positions.average_cost_basis) * 100
                            ELSE 0
                        END,
                    last_updated = CURRENT_TIMESTAMP
                FROM market_prices mp
                WHERE positions.symbol = mp.symbol
                AND mp.price_date = CURRENT_DATE
                AND positions.quantity > 0
            """)
            
            rows_updated = cursor.rowcount
            conn.commit()
            logger.info(f"Updated market values for {rows_updated} positions")
            
        except Exception as e:
            conn.rollback()
            logger.error(f"Failed to update position values: {e}")
            raise
        finally:
            conn.close()

class MarketDataService:
    def __init__(self, fmp_api_key: str, db_manager: DatabaseManager):
        self.api_key = fmp_api_key
        self.db_manager = db_manager
        self.base_url = "https://financialmodelingprep.com/api/v3"
    
    async def fetch_security_prices(self, symbols: List[str]) -> List[SecurityPrice]:
        """Fetch current market prices for securities"""
        async with aiohttp.ClientSession() as session:
            tasks = []
            for symbol in symbols:
                url = f"{self.base_url}/quote-short/{symbol}?apikey={self.api_key}"
                tasks.append(self._fetch_single_price(session, url, symbol))
            
            results = await asyncio.gather(*tasks, return_exceptions=True)
            prices = [r for r in results if isinstance(r, SecurityPrice)]
            
            logger.info(f"Successfully fetched prices for {len(prices)}/{len(symbols)} symbols")
            return prices
    
    async def _fetch_single_price(self, session: aiohttp.ClientSession, url: str, symbol: str) -> Optional[SecurityPrice]:
        """Fetch single security price"""
        try:
            async with session.get(url) as response:
                if response.status == 200:
                    data = await response.json()
                    if data and len(data) > 0:
                        price_data = data[0]
                        return SecurityPrice(
                            symbol=symbol,
                            price=float(price_data['price']),
                            currency='USD',
                            date=date.today().isoformat(),
                            change_percent=price_data.get('changesPercentage')
                        )
        except Exception as e:
            logger.error(f"Failed to fetch price for {symbol}: {e}")
            return None
    
    async def fetch_exchange_rates(self) -> List[ExchangeRate]:
        """Fetch current exchange rates"""
        rates = []
        currencies = ['KWD', 'EUR', 'GBP']  # Convert from USD to these
        
        async with aiohttp.ClientSession() as session:
            for currency in currencies:
                url = f"{self.base_url}/fx/USD{currency}?apikey={self.api_key}"
                try:
                    async with session.get(url) as response:
                        if response.status == 200:
                            data = await response.json()
                            if data and len(data) > 0:
                                rate_data = data[0]
                                rates.append(ExchangeRate(
                                    from_currency='USD',
                                    to_currency=currency,
                                    rate=float(rate_data['bid']),
                                    date=date.today().isoformat()
                                ))
                except Exception as e:
                    logger.error(f"Failed to fetch rate for USD/{currency}: {e}")
        
        return rates
    
    async def update_all_market_data(self):
        """Main method to update all market data"""
        logger.info("Starting market data update")
        
        try:
            # Get symbols that need updates
            symbols = self.db_manager.get_active_symbols()
            logger.info(f"Updating data for {len(symbols)} symbols: {symbols}")
            
            # Fetch and update security prices
            prices = await self.fetch_security_prices(symbols)
            if prices:
                self.db_manager.update_market_prices(prices)
            
            # Fetch and update exchange rates
            rates = await self.fetch_exchange_rates()
            if rates:
                self.db_manager.update_exchange_rates(rates)
            
            # Update position calculations
            self.db_manager.update_position_values()
            
            # Refresh net worth view
            conn = self.db_manager.get_connection()
            try:
                cursor = conn.cursor()
                cursor.execute("SELECT refresh_net_worth_view()")
                conn.commit()
                logger.info("Refreshed net worth materialized view")
            finally:
                conn.close()
            
            logger.info("Market data update completed successfully")
            
        except Exception as e:
            logger.error(f"Market data update failed: {e}")
            raise

# Configuration using environment variables
class Config:
    # Database configuration from environment variables
    DB_HOST = os.getenv("DB_HOST", "localhost")
    DB_NAME = os.getenv("DB_NAME", "treviwise")
    DB_USER = os.getenv("DB_USER", "postgres")
    DB_PASSWORD = os.getenv("DB_PASSWORD")
    DB_PORT = os.getenv("DB_PORT", "5432")
    
    # API Keys from environment variables
    FMP_API_KEY = os.getenv("FMP_API_KEY")
    
    # Application settings
    DEBUG = os.getenv("DEBUG", "false").lower() == "true"
    LOG_LEVEL = os.getenv("LOG_LEVEL", "INFO")
    LOG_FILE = os.getenv("LOG_FILE", "treviwise.log")
    
    def __post_init__(self):
        """Validate required environment variables"""
        if not self.DB_PASSWORD:
            raise ValueError("DB_PASSWORD environment variable is required")
        if not self.FMP_API_KEY:
            raise ValueError("FMP_API_KEY environment variable is required")
    
    @property
    def database_url(self):
        return f"postgresql://{self.DB_USER}:{self.DB_PASSWORD}@{self.DB_HOST}:{self.DB_PORT}/{self.DB_NAME}"

async def main():
    """Main execution function"""
    try:
        config = Config()
        
        # Validate required environment variables
        if not config.DB_PASSWORD:
            logger.error("DB_PASSWORD environment variable is required")
            return
        
        if not config.FMP_API_KEY:
            logger.error("FMP_API_KEY environment variable is required")
            return
        
        logger.info(f"Starting Treviwise market data service")
        logger.info(f"Database: {config.DB_HOST}:{config.DB_PORT}/{config.DB_NAME}")
        logger.info(f"Debug mode: {config.DEBUG}")
        
        # Initialize services
        db_manager = DatabaseManager(config.database_url)
        market_service = MarketDataService(config.FMP_API_KEY, db_manager)
        
        # Run market data update
        await market_service.update_all_market_data()
        
        # Show summary
        conn = db_manager.get_connection()
        try:
            cursor = conn.cursor()
            
            # Show updated positions
            cursor.execute("""
                SELECT 
                    p.symbol,
                    sm.security_name,
                    p.quantity,
                    p.average_cost_basis,
                    p.current_price,
                    p.market_value,
                    p.unrealized_gain_loss,
                    p.unrealized_gain_loss_percent
                FROM positions p
                JOIN securities_master sm ON p.symbol = sm.symbol
                WHERE p.quantity > 0
                ORDER BY p.market_value DESC
            """)
            
            positions = cursor.fetchall()
            
            print("\n" + "="*80)
            print("TREVIWISE PORTFOLIO SUMMARY")
            print("="*80)
            
            total_cost = 0
            total_value = 0
            
            for pos in positions:
                cost_basis = pos['quantity'] * pos['average_cost_basis']
                total_cost += cost_basis
                total_value += pos['market_value'] or cost_basis
                
                print(f"{pos['symbol']:<6} | {pos['security_name']:<30} | "
                      f"Qty: {pos['quantity']:>6} | "
                      f"Price: ${pos['current_price'] or 0:>8.2f} | "
                      f"Value: ${pos['market_value'] or cost_basis:>10,.2f} | "
                      f"P&L: {pos['unrealized_gain_loss_percent'] or 0:>6.1f}%")
            
            print("-" * 80)
            print(f"Total Cost Basis: ${total_cost:>15,.2f}")
            print(f"Total Market Value: ${total_value:>13,.2f}")
            print(f"Total P&L: ${total_value - total_cost:>18,.2f} ({((total_value - total_cost) / total_cost * 100):>5.1f}%)")
            print("="*80)
            
        finally:
            conn.close()
            
    except Exception as e:
        logger.error(f"Application failed to start: {e}")
        raise

if __name__ == "__main__":
    # Run the market data update
    asyncio.run(main())