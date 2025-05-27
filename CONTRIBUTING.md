# Contributing to Treviwise

Thank you for your interest in contributing to Treviwise! 🎉 

We welcome contributions from developers of all skill levels. Whether you're fixing bugs, adding features, improving documentation, or helping with design, your contributions make Treviwise better for everyone.

## 🤝 Code of Conduct

This project and everyone participating in it is governed by our [Code of Conduct](CODE_OF_CONDUCT.md). By participating, you are expected to uphold this code.

## 🚀 Ways to Contribute

### 🐛 **Bug Reports**
- Use the [Bug Report Template](.github/ISSUE_TEMPLATE/bug_report.md)
- Include steps to reproduce the issue
- Provide system information (OS, Python version, etc.)
- Include screenshots for UI issues

### 💡 **Feature Requests**
- Use the [Feature Request Template](.github/ISSUE_TEMPLATE/feature_request.md)
- Explain the problem you're trying to solve
- Describe your proposed solution
- Consider alternative solutions

### 📖 **Documentation**
- Fix typos and improve clarity
- Add examples and tutorials
- Improve API documentation
- Translate documentation

### 💻 **Code Contributions**
- Bug fixes
- New features
- Performance improvements
- Code refactoring
- Test coverage improvements

## 🛠️ Development Setup

### Prerequisites
- Python 3.10+
- Node.js 16+
- PostgreSQL 15+
- Git

### Setup Steps

1. **Fork and Clone**
   ```bash
   git clone https://github.com/aalbahar80/treviwise.git
   cd treviwise
   ```

2. **Backend Setup**
   ```bash
   cd backend
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   pip install -r requirements.txt
   cp .env.example .env
   # Edit .env with your configuration
   ```

3. **Frontend Setup**
   ```bash
   cd frontend
   npm install
   cp .env.example .env
   ```

4. **Database Setup**
   ```bash
   # Create database
   createdb treviwise
   
   # Run migrations
   python backend/setup_database.py
   
   # Optional: Load demo data
   python scripts/demo_data.py
   ```

5. **Start Development Servers**
   ```bash
   # Terminal 1: Backend
   cd backend && python main.py
   
   # Terminal 2: Frontend
   cd frontend && npm start
   ```

## 📋 Development Guidelines

### **Code Style**

#### Python (Backend)
- Follow [PEP 8](https://pep8.org/)
- Use [Black](https://black.readthedocs.io/) for formatting
- Use [Flake8](https://flake8.pycqa.org/) for linting
- Type hints required for new code
- Docstrings for public functions

```python
def calculate_portfolio_value(positions: List[Position]) -> Decimal:
    """Calculate total portfolio value from positions.
    
    Args:
        positions: List of portfolio positions
        
    Returns:
        Total portfolio value in USD
    """
    return sum(pos.market_value for pos in positions)
```

#### JavaScript/React (Frontend)
- Use [Prettier](https://prettier.io/) for formatting
- Follow [Airbnb JavaScript Style Guide](https://github.com/airbnb/javascript)
- Use functional components with hooks
- PropTypes or TypeScript for type checking

```javascript
// Good
const Portfolio = ({ positions, onRefresh }) => {
  const [loading, setLoading] = useState(false);
  
  const handleRefresh = async () => {
    setLoading(true);
    await onRefresh();
    setLoading(false);
  };
  
  return (
    <div>
      {/* Component content */}
    </div>
  );
};
```

### **Commit Messages**
Use [Conventional Commits](https://www.conventionalcommits.org/):

```
feat: add portfolio performance analytics
fix: resolve currency conversion bug
docs: update API documentation
style: format code with prettier
refactor: simplify asset allocation logic
test: add unit tests for portfolio calculations
```

### **Branch Naming**
- `feature/description` - New features
- `fix/description` - Bug fixes
- `docs/description` - Documentation updates
- `refactor/description` - Code refactoring

Example: `feature/add-crypto-support`

## 🧪 Testing

### **Running Tests**

```bash
# Backend tests
cd backend
pytest

# Frontend tests
cd frontend
npm test

# All tests
npm run test:all
```

### **Writing Tests**

#### Python Tests
```python
import pytest
from decimal import Decimal
from app.services.portfolio import calculate_portfolio_value

def test_calculate_portfolio_value():
    positions = [
        Position(symbol="AAPL", quantity=10, market_value=Decimal("1000")),
        Position(symbol="GOOGL", quantity=5, market_value=Decimal("500")),
    ]
    
    total_value = calculate_portfolio_value(positions)
    assert total_value == Decimal("1500")
```

#### React Tests
```javascript
import { render, screen } from '@testing-library/react';
import Portfolio from './Portfolio';

test('renders portfolio summary', () => {
  const mockPositions = [
    { symbol: 'AAPL', marketValue: 1000 },
    { symbol: 'GOOGL', marketValue: 500 }
  ];
  
  render(<Portfolio positions={mockPositions} />);
  
  expect(screen.getByText('Total Value: $1,500.00')).toBeInTheDocument();
});
```

## 📝 Pull Request Process

### **Before Submitting**
1. ✅ Fork the repository
2. ✅ Create a feature branch
3. ✅ Write or update tests
4. ✅ Update documentation
5. ✅ Ensure all tests pass
6. ✅ Follow code style guidelines

### **PR Template**
```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Documentation update
- [ ] Performance improvement

## Testing
- [ ] Tests pass locally
- [ ] Added new tests for changes
- [ ] Manual testing completed

## Screenshots (if applicable)

## Checklist
- [ ] Code follows style guidelines
- [ ] Self-review completed
- [ ] Documentation updated
- [ ] No breaking changes
```

### **Review Process**
1. **Automated Checks** - CI/CD pipeline runs tests
2. **Code Review** - Maintainers review changes
3. **Feedback** - Address review comments
4. **Approval** - At least one maintainer approval required
5. **Merge** - Squash and merge to main branch

## 🎯 Good First Issues

New contributors should look for issues labeled:
- `good first issue` - Easy to implement
- `help wanted` - Community help needed
- `documentation` - Documentation improvements
- `frontend` or `backend` - Specific area focus

### **Beginner-Friendly Areas**
- **UI Improvements** - Better mobile responsiveness
- **New Currency Support** - Add currencies and formatting
- **Chart Enhancements** - New chart types or styling
- **Documentation** - Examples, tutorials, API docs
- **Testing** - Unit tests for existing functionality

## 💬 Communication

### **Getting Help**
- **[GitHub Discussions](https://github.com/aalbahar80/treviwise/discussions)** - Questions and ideas
- **[GitHub Issues](https://github.com/aalbahar80/treviwise/issues)** - Bug reports and features
- **Pull Request Comments** - Code-specific discussions

### **Response Time**
- **Issues**: We aim to respond within 48 hours
- **Pull Requests**: Initial review within 72 hours
- **Discussions**: Community-driven, typically within 24 hours

## 🏆 Recognition

Contributors will be recognized in:
- **README.md** - Contributors section
- **Release Notes** - Major contribution highlights
- **Hall of Fame** - Top contributors page (future)

## 📚 Additional Resources

- **[Development Setup](docs/DEVELOPMENT.md)** - Detailed development guide
- **[API Documentation](docs/API.md)** - Backend API reference
- **[Database Schema](docs/DATABASE.md)** - Database structure
- **[Deployment Guide](docs/DEPLOYMENT.md)** - Production deployment

## ❓ Questions?

Don't hesitate to ask! We're here to help:
- Open a [GitHub Discussion](https://github.com/aalbahar80/treviwise/discussions)
- Comment on relevant issues
- Reach out to maintainers

Thank you for contributing to Treviwise! 🙏