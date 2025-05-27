# Treviwise Demo Data

This directory contains scripts for generating realistic but fictional demo data for Treviwise.

## Demo Data Overview

### **Fictional Portfolio Profile**
- **Total Net Worth**: ~$125,000
- **Age Group**: Young professional (25-35)
- **Investment Style**: Diversified, growth-oriented
- **Experience Level**: Intermediate investor

### **Asset Breakdown**
- **Cash & Equivalents**: $45,000 (36%)
  - Checking account: $5,000
  - Savings account: $25,000
  - High-yield savings: $15,000

- **Equities**: $65,000 (52%)
  - Individual stocks: $35,000
  - ETFs: $30,000
  - Mix of growth and dividend stocks

- **Fixed Income**: $10,000 (8%)
  - Bond ETFs: $7,000
  - I-Bonds: $3,000

- **Alternative/Other**: $5,000 (4%)
  - Crypto: $3,000
  - Collectibles: $2,000

### **Sample Holdings**
- **Tech Heavy**: AAPL, MSFT, GOOGL, AMZN
- **Diversified ETFs**: VTI, SPY, QQQ
- **Bonds**: BND, TIP
- **International**: VEA, VWO
- **Sectors**: XLF, VGT, VHT

### **Fictional Institutions**
- **Primary Bank**: Demo Community Bank
- **Savings**: Demo Online Bank  
- **Brokerage**: Demo Investment Services
- **Crypto**: Demo Crypto Exchange

## Scripts

### **demo_data.py**
Main script for loading demo data:
```bash
python scripts/demo_data.py
```

Options:
- `--portfolio-size` - small/medium/large
- `--include-crypto` - add cryptocurrency holdings
- `--include-real-estate` - add property investments
- `--time-period` - historical data period

### **clear_demo_data.py**
Remove all demo data:
```bash
python scripts/clear_demo_data.py
```

## Privacy & Ethics

### **Completely Fictional**
- All data is generated, not based on real portfolios
- Names, accounts, and values are entirely fictional
- No correlation to actual user data

### **Educational Purpose**
- Designed to showcase platform capabilities
- Helps users understand features before adding real data
- Provides realistic examples for testing

### **Easy Removal**
- Demo data is clearly marked in database
- Can be completely removed with one command
- No mixing with real user data

## Usage Guidelines

### **For New Users**
1. Install Treviwise
2. Run demo data script
3. Explore features with sample data
4. Clear demo data when ready for real data

### **For Developers**
1. Use for testing new features
2. Validate calculations and charts
3. Test UI with realistic data volumes
4. Ensure no performance issues

### **For Screenshots/Marketing**
1. Generate clean, professional-looking portfolios
2. Showcase diverse investment types
3. Demonstrate platform capabilities
4. Create realistic use case scenarios