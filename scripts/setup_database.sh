#!/bin/bash

# Treviwise Database Setup Script
# This script sets up a fresh Treviwise database with optional sample data

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
DB_HOST="localhost"
DB_PORT="5432"
DB_USER="postgres"
DB_NAME="treviwise"  # Updated default name

echo -e "${GREEN}🚀 Treviwise Database Setup${NC}"
echo "=================================="

# Function to check if PostgreSQL is running
check_postgres() {
    echo -e "${BLUE}🔍 Checking PostgreSQL installation...${NC}"
    
    if ! command -v psql &> /dev/null; then
        echo -e "${RED}❌ PostgreSQL is not installed or not in PATH${NC}"
        echo -e "${YELLOW}💡 Install PostgreSQL from: https://www.postgresql.org/download/${NC}"
        exit 1
    fi
    
    if ! command -v createdb &> /dev/null; then
        echo -e "${RED}❌ PostgreSQL client tools not found${NC}"
        exit 1
    fi
    
    if ! pg_isready -h $DB_HOST -p $DB_PORT -U $DB_USER &> /dev/null; then
        echo -e "${RED}❌ PostgreSQL server is not running or not accessible${NC}"
        echo -e "${YELLOW}💡 Make sure PostgreSQL is running:${NC}"
        echo "   - macOS: brew services start postgresql"
        echo "   - Linux: sudo systemctl start postgresql"
        echo "   - Windows: Check PostgreSQL service in Services"
        exit 1
    fi
    
    echo -e "${GREEN}✅ PostgreSQL server is running${NC}"
}

# Function to create database
create_database() {
    echo -e "${BLUE}📦 Setting up database: $DB_NAME${NC}"
    
    # Check if database exists
    if psql -h $DB_HOST -p $DB_PORT -U $DB_USER -lqt | cut -d \| -f 1 | grep -qw $DB_NAME; then
        echo -e "${YELLOW}⚠️  Database '$DB_NAME' already exists${NC}"
        echo -e "${YELLOW}This will permanently delete all existing data in '$DB_NAME'${NC}"
        read -p "Do you want to drop and recreate it? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo -e "${YELLOW}🗑️  Dropping existing database${NC}"
            dropdb -h $DB_HOST -p $DB_PORT -U $DB_USER $DB_NAME
            echo -e "${GREEN}✅ Existing database dropped${NC}"
        else
            echo -e "${RED}❌ Setup cancelled${NC}"
            exit 1
        fi
    fi
    
    # Create database
    echo -e "${BLUE}🏗️  Creating new database${NC}"
    createdb -h $DB_HOST -p $DB_PORT -U $DB_USER $DB_NAME
    echo -e "${GREEN}✅ Database '$DB_NAME' created successfully${NC}"
}

# Function to load basic schema
load_schema() {
    echo -e "${BLUE}🏗️  Loading database schema${NC}"
    
    if [ ! -f "database/01_schema.sql" ]; then
        echo -e "${RED}❌ Schema file not found: database/01_schema.sql${NC}"
        echo "Please run this script from the project root directory"
        exit 1
    fi
    
    psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -f database/01_schema.sql -q
    echo -e "${GREEN}✅ Basic schema loaded successfully${NC}"
}

# Function to load schema enhancements
load_enhancements() {
    echo -e "${BLUE}⚡ Loading schema enhancements${NC}"
    
    if [ ! -f "database/02_schema_enhancements.sql" ]; then
        echo -e "${YELLOW}⚠️  Schema enhancements file not found: database/02_schema_enhancements.sql${NC}"
        echo -e "${YELLOW}Skipping enhancements...${NC}"
        return 0
    fi
    
    psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -f database/02_schema_enhancements.sql -q
    echo -e "${GREEN}✅ Schema enhancements loaded successfully${NC}"
}

# Function to load sample data
load_sample_data() {
    echo -e "${BLUE}📊 Loading sample data${NC}"
    
    if [ ! -f "database/sample_data.sql" ]; then
        echo -e "${YELLOW}⚠️  Sample data file not found: database/sample_data.sql${NC}"
        echo -e "${YELLOW}Skipping sample data...${NC}"
        return 0
    fi
    
    psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -f database/sample_data.sql -q
    echo -e "${GREEN}✅ Sample data loaded successfully${NC}"
}

# Function to verify setup
verify_setup() {
    echo -e "${BLUE}🔍 Verifying database setup${NC}"
    
    # Count tables
    table_count=$(psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';" 2>/dev/null || echo "0")
    
    # Count functions
    function_count=$(psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -t -c "SELECT COUNT(*) FROM information_schema.routines WHERE routine_schema = 'public';" 2>/dev/null || echo "0")
    
    # Count sample records
    position_count=$(psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -t -c "SELECT COUNT(*) FROM positions;" 2>/dev/null || echo "0")
    
    # Check materialized view status
    matview_status=$(psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -t -c "SELECT CASE WHEN EXISTS(SELECT 1 FROM pg_matviews WHERE matviewname = 'current_net_worth_detailed') THEN 'exists' ELSE 'missing' END;" 2>/dev/null || echo "unknown")
    
    echo -e "${GREEN}✅ Database verification complete${NC}"
    echo "   📋 Tables created: $(echo $table_count | tr -d ' ')"
    echo "   ⚙️  Functions created: $(echo $function_count | tr -d ' ')"
    echo "   📈 Sample positions: $(echo $position_count | tr -d ' ')"
    echo "   👁️  Materialized view: $(echo $matview_status | tr -d ' ')"
    
    # Test database connection for backend
    echo -e "${BLUE}🔧 Testing database connectivity${NC}"
    connection_test=$(psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c "SELECT 'Database connection successful' as status;" -t 2>/dev/null || echo "failed")
    
    if [[ $connection_test == *"successful"* ]]; then
        echo -e "${GREEN}✅ Database connection test passed${NC}"
    else
        echo -e "${YELLOW}⚠️  Database connection test failed${NC}"
    fi
}

# Main execution
main() {
    echo "Database Configuration:"
    echo "  Host: $DB_HOST"
    echo "  Port: $DB_PORT"
    echo "  User: $DB_USER"
    echo "  Database: $DB_NAME"
    echo ""
    
    # Ask about sample data upfront
    echo -e "${YELLOW}📊 Sample Data Option${NC}"
    echo "Would you like to load sample data for demo purposes?"
    echo "This includes fake financial data to test the application."
    read -p "Load sample data? (Y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Nn]$ ]]; then
        LOAD_SAMPLE_DATA=false
        echo -e "${BLUE}📭 Will create empty database${NC}"
    else
        LOAD_SAMPLE_DATA=true
        echo -e "${BLUE}📊 Will load sample data${NC}"
    fi
    echo ""
    
    # Execute setup steps
    check_postgres
    create_database
    load_schema
    load_enhancements
    
    if [ "$LOAD_SAMPLE_DATA" = true ]; then
        load_sample_data
    fi
    
    verify_setup
    
    echo ""
    echo -e "${GREEN}🎉 Database setup complete!${NC}"
    echo ""
    echo -e "${YELLOW}Next steps:${NC}"
    echo "1. Update your backend .env file:"
    echo "   DB_NAME=$DB_NAME"
    echo "   DB_PASSWORD=your_postgres_password"
    echo ""
    echo "2. Start your backend server:"
    echo "   cd backend && python main.py"
    echo ""
    echo "3. Start your frontend:"
    echo "   cd frontend && npm start"
    echo ""
    
    if [ "$LOAD_SAMPLE_DATA" = true ]; then
        echo -e "${BLUE}📊 Sample data loaded - ready for demo!${NC}"
    else
        echo -e "${BLUE}📭 Empty database created - add your own data${NC}"
        echo -e "${YELLOW}💡 Tip: You can load sample data later with:${NC}"
        echo "   psql -U $DB_USER -d $DB_NAME -f database/sample_data.sql"
    fi
    echo ""
    echo -e "${GREEN}🌟 Treviwise is ready to go!${NC}"
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --host HOST       Database host (default: localhost)"
    echo "  --port PORT       Database port (default: 5432)"
    echo "  --user USER       Database user (default: postgres)"
    echo "  --database NAME   Database name (default: treviwise)"
    echo "  --no-sample-data  Skip loading sample data"
    echo "  --help           Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                                    # Interactive setup with default settings"
    echo "  $0 --database my_treviwise           # Use custom database name"
    echo "  $0 --no-sample-data                  # Create empty database only"
    echo "  $0 --host prod-server --user myuser  # Connect to remote database"
}

# Parse command line arguments
LOAD_SAMPLE_DATA=true  # Default to true, can be overridden

while [[ $# -gt 0 ]]; do
    case $1 in
        --host)
            DB_HOST="$2"
            shift 2
            ;;
        --port)
            DB_PORT="$2"
            shift 2
            ;;
        --user)
            DB_USER="$2"
            shift 2
            ;;
        --database)
            DB_NAME="$2"
            shift 2
            ;;
        --no-sample-data)
            LOAD_SAMPLE_DATA=false
            shift
            ;;
        --help)
            show_usage
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Run main function
main