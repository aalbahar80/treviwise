# backend/dividend_collector.py
"""
Fetch dividend data from FMP and update database
Secured version using environment variables
"""

import asyncio
import aiohttp
import psycopg2
from psycopg2.extras import RealDictCursor
from datetime import datetime, date
import logging
from config import settings

logger = logging.getLogger(__name__)

class DividendCollector:
    def __init__(self, fmp_api_key: str = None, db_connection_string: str = None):
        # Use environment variables by default, allow override for testing
        self.api_key = fmp_api_key or settings.FMP_API_KEY
        self.db_connection_string = db_connection_string or settings.database_url
        self.base_url = "https://financialmodelingprep.com/api/v3"
        
        # Validate required settings
        if not self.api_key:
            raise ValueError("FMP_API_KEY is required. Set it in your .env file.")
        if not self.db_connection_string:
            raise ValueError("Database connection settings are required. Check your .env file.")
    
    def get_db_connection(self):
        return psycopg2.connect(self.db_connection_string, cursor_factory=RealDictCursor)
    
    async def fetch_symbol_dividends(self, symbol: str):
        """Fetch dividend history for a symbol"""
        url = f"{self.base_url}/historical-price-full/stock_dividend/{symbol}?apikey={self.api_key}"
        
        async with aiohttp.ClientSession() as session:
            try:
                async with session.get(url) as response:
                    if response.status == 200:
                        data = await response.json()
                        if 'historical' in data:
                            return [(symbol, div) for div in data['historical']]
            except Exception as e:
                logger.error(f"Failed to fetch dividends for {symbol}: {e}")
        return []
    
    async def collect_all_dividends(self):
        """Collect dividends for all portfolio symbols"""
        conn = self.get_db_connection()
        
        # Get symbols from positions
        cursor = conn.cursor()
        cursor.execute("SELECT DISTINCT symbol FROM positions WHERE quantity > 0")
        symbols = [row['symbol'] for row in cursor.fetchall()]
        conn.close()
        
        logger.info(f"Fetching dividends for {len(symbols)} symbols")
        
        # Fetch dividends for all symbols
        tasks = [self.fetch_symbol_dividends(symbol) for symbol in symbols]
        results = await asyncio.gather(*tasks)
        
        # Flatten results
        all_dividends = []
        for symbol_dividends in results:
            all_dividends.extend(symbol_dividends)
        
        # Store in database
        if all_dividends:
            logger.info(f"Collected {len(all_dividends)} total dividend records")
            self.store_dividends(all_dividends)
        else:
            logger.warning("No dividend data collected")
    
    def store_dividends(self, dividend_data):
        """Store dividend data in database"""
        conn = self.get_db_connection()
        try:
            cursor = conn.cursor()
            
            for symbol, div in dividend_data:
                # Skip if essential data is missing
                if not div.get('date') or not div.get('dividend'):
                    continue
                
                # Helper function to handle empty/null dates
                def clean_date(date_str):
                    if date_str and date_str.strip():
                        return date_str
                    return None
                
                cursor.execute("""
                    INSERT INTO dividends (
                        symbol, ex_dividend_date, record_date, payment_date, 
                        declaration_date, dividend_amount, currency
                    ) VALUES (%s, %s, %s, %s, %s, %s, %s)
                    ON CONFLICT (symbol, ex_dividend_date) 
                    DO UPDATE SET
                        dividend_amount = EXCLUDED.dividend_amount,
                        record_date = EXCLUDED.record_date,
                        payment_date = EXCLUDED.payment_date
                """, (
                    symbol,
                    clean_date(div.get('date')),
                    clean_date(div.get('recordDate')),
                    clean_date(div.get('paymentDate')),
                    clean_date(div.get('declarationDate')),
                    float(div.get('dividend', 0)),
                    'USD'
                ))
            
            conn.commit()
            logger.info(f"Successfully stored {len([d for d in dividend_data if d[1].get('date') and d[1].get('dividend')])} valid dividend records")
            
        except Exception as e:
            conn.rollback()
            logger.error(f"Failed to store dividends: {e}")
            
            # Log problematic data for debugging
            for symbol, div in dividend_data[:3]:  # Show first 3 for debugging
                logger.error(f"Sample data - {symbol}: {div}")
            raise
        finally:
            conn.close()

# Usage example
async def main():
    """
    Main function using environment variables from .env file
    No hardcoded secrets!
    """
    try:
        # Initialize collector with environment variables
        collector = DividendCollector()
        
        # Collect dividends
        await collector.collect_all_dividends()
        
        # Show collected dividends
        conn = collector.get_db_connection()
        cursor = conn.cursor()
        cursor.execute("""
            SELECT 
                symbol, 
                ex_dividend_date, 
                dividend_amount,
                payment_date
            FROM dividends 
            ORDER BY ex_dividend_date DESC 
            LIMIT 10
        """)
        
        print("\n=== Recent Dividends Collected ===")
        for row in cursor.fetchall():
            print(f"{row['symbol']}: ${row['dividend_amount']:.4f} on {row['ex_dividend_date']}")
        
        conn.close()
        
    except ValueError as e:
        print(f"❌ Configuration Error: {e}")
        print("💡 Make sure to:")
        print("   1. Copy backend/.env.example to backend/.env")
        print("   2. Fill in your FMP_API_KEY and database credentials")
    except Exception as e:
        logger.error(f"Application error: {e}")

if __name__ == "__main__":
    asyncio.run(main())