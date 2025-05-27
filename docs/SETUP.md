# Treviwise Setup Guide

Complete installation guide for setting up Treviwise on your local machine or server.

## 📋 Prerequisites

### Required Software

| Software | Version | Purpose | Installation |
|----------|---------|---------|--------------|
| **PostgreSQL** | 17+ | Database server | [Download](https://www.postgresql.org/download/) |
| **Python** | 3.8+ | Backend runtime | [Download](https://www.python.org/downloads/) |
| **Node.js** | 16+ | Frontend runtime | [Download](https://nodejs.org/) |
| **Git** | Latest | Version control | [Download](https://git-scm.com/) |

### System Requirements
- **RAM**: 4GB minimum, 8GB recommended
- **Storage**: 2GB free space
- **OS**: Windows 10+, macOS 10.15+, or Linux (Ubuntu 18.04+)

## 🚀 Quick Start (5 minutes)

### 1. Clone Repository
```bash
git clone https://github.com/yourusername/treviwise.git
cd treviwise
```

### 2. Database Setup (Automated)
```bash
# Interactive setup (recommended for first-time users)
./scripts/setup_database.sh
```

### 3. Backend Setup
```bash
cd backend
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt
cp .env.example .env
# Edit .env with your database password
```

### 4. Frontend Setup
```bash
cd frontend
npm install
cp .env.example .env
# Edit .env if needed (defaults should work)
```

### 5. Start Application
```bash
# Terminal 1 (Backend)
cd backend && python main.py

# Terminal 2 (Frontend)  
cd frontend && npm start
```

🎉 **Access your app**: http://localhost:3000

---

## 📖 Detailed Installation

### Step 1: System Prerequisites

#### PostgreSQL Installation

**macOS (Homebrew):**
```bash
brew install postgresql@17
brew services start postgresql@17
```

**Ubuntu/Debian:**
```bash
sudo apt update
sudo apt install postgresql-17 postgresql-contrib
sudo systemctl start postgresql
sudo systemctl enable postgresql
```

**Windows:**
1. Download installer from [PostgreSQL.org](https://www.postgresql.org/download/windows/)
2. Run installer and follow setup wizard
3. Remember your postgres user password!

#### Verify PostgreSQL Installation
```bash
psql --version
pg_isready
```

### Step 2: Project Setup

#### Clone the Repository
```bash
git clone https://github.com/yourusername/treviwise.git
cd treviwise
```

**Note**: If you downloaded a ZIP file instead of cloning:
```bash
# Make setup script executable
chmod +x scripts/setup_database.sh
```

### Step 3: Database Configuration

#### Option A: Automated Setup (Recommended)
```bash
# Interactive setup with sample data
./scripts/setup_database.sh

# Quick empty database setup
./scripts/setup_database.sh --no-sample-data

# Custom database name
./scripts/setup_database.sh --database my_treviwise

# Remote database setup
./scripts/setup_database.sh --host prod-server --user myuser
```

#### Option B: Manual Setup
```bash
# Create database
createdb -U postgres treviwise

# Load schema
psql -U postgres -d treviwise -f database/01_schema.sql
psql -U postgres -d treviwise -f database/02_schema_enhancements.sql

# Load sample data (optional)
psql -U postgres -d treviwise -f database/sample_data.sql
```

#### Test Database Setup
```bash
./scripts/setup_database.sh --help
psql -U postgres -d treviwise -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';"
```

### Step 4: Backend Configuration

#### Create Virtual Environment
```bash
cd backend
python -m venv venv

# Activate virtual environment
source venv/bin/activate  # Linux/macOS
# OR
venv\Scripts\activate     # Windows
```

#### Install Dependencies
```bash
pip install -r requirements.txt
```

#### Environment Configuration
```bash
cp .env.example .env
```

Edit `backend/.env` with your settings:
```bash
# Required settings
DB_PASSWORD=your_postgres_password
FMP_API_KEY=your_api_key  # Get from financialmodelingprep.com

# Optional settings (defaults provided)
DB_HOST=localhost
DB_NAME=treviwise
DB_USER=postgres
DB_PORT=5432
```

#### Get API Key (Optional but Recommended)
1. Visit [Financial Modeling Prep](https://financialmodelingprep.com/developer/docs)
2. Sign up for free account
3. Copy your API key to `FMP_API_KEY` in `.env`

#### Test Backend
```bash
python main.py
# Should see: "Treviwise API startup complete"
# Visit: http://localhost:8000/docs for API documentation
```

### Step 5: Frontend Configuration

#### Install Dependencies
```bash
cd frontend
npm install
```

#### Environment Configuration
```bash
cp .env.example .env
```

Edit `frontend/.env` if needed (defaults should work):
```bash
REACT_APP_API_URL=http://localhost:8000
REACT_APP_NAME=Treviwise
REACT_APP_TAGLINE=Personal Wealth Management Platform
```

#### Test Frontend
```bash
npm start
# Should open: http://localhost:3000
```

---

## 🔧 Troubleshooting

### Database Issues

**PostgreSQL not running:**
```bash
# Check status
pg_isready -h localhost -p 5432 -U postgres

# Start PostgreSQL
# macOS: brew services start postgresql@17
# Linux: sudo systemctl start postgresql
# Windows: Check Services app
```

**Permission denied:**
```bash
# Grant database creation permissions
sudo -u postgres psql -c "ALTER USER postgres CREATEDB;"

# Reset postgres password
sudo -u postgres psql -c "ALTER USER postgres PASSWORD 'newpassword';"
```

**Database connection failed:**
```bash
# Test connection manually
psql -h localhost -U postgres -d treviwise -c "SELECT version();"

# Check your .env file settings
cat backend/.env | grep DB_
```

### Backend Issues

**Module not found:**
```bash
# Ensure virtual environment is activated
source venv/bin/activate
pip list | grep fastapi

# Reinstall if needed
pip install -r requirements.txt
```

**API key errors:**
```bash
# Check if API key is set
echo $FMP_API_KEY
# OR
cat backend/.env | grep FMP_API_KEY

# Test API key
curl "https://financialmodelingprep.com/api/v3/quote/AAPL?apikey=YOUR_KEY"
```

### Frontend Issues

**npm install fails:**
```bash
# Clear cache and retry
npm cache clean --force
rm -rf node_modules package-lock.json
npm install
```

**Build errors:**
```bash
# Check Node.js version
node --version  # Should be 16+

# Check environment variables
cat frontend/.env
```

### Common Solutions

**Port already in use:**
```bash
# Find process using port
lsof -i :8000  # Backend
lsof -i :3000  # Frontend

# Kill process
kill -9 <PID>
```

**SSL certificate errors:**
```bash
pip install --trusted-host pypi.org --trusted-host pypi.python.org -r requirements.txt
```

---

## 🎯 Verification Checklist

- [ ] PostgreSQL is installed and running
- [ ] Database `treviwise` exists with tables
- [ ] Backend starts without errors on port 8000
- [ ] Frontend starts without errors on port 3000
- [ ] API documentation accessible at http://localhost:8000/docs
- [ ] Frontend loads at http://localhost:3000
- [ ] Sample data visible in the application (if loaded)

---

## 🔄 Next Steps

1. **Customize Data**: Replace sample data with your actual financial information
2. **API Integration**: Configure real market data feeds
3. **Security**: Set up proper authentication for production
4. **Deployment**: See [DEPLOYMENT.md](DEPLOYMENT.md) for production setup

---

## 📞 Support

- **Documentation**: Check `/docs` folder for detailed guides
- **Issues**: Create a GitHub issue for bugs
- **Discussions**: Use GitHub discussions for questions
- **Database Guide**: See [DATABASE.md](DATABASE.md) for schema details

---

**⚠️ Important**: This setup uses sample data by default. No real financial information is included.