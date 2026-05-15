# CSE Proxy Backend

This is a simple Django-based proxy server to forward requests to the Colombo Stock Exchange (CSE) API, bypassing CORS issues for web and mobile applications.

## Prerequisites
- Python 3.8+
- pip

## Installation

1. Create a virtual environment:
   ```bash
   python -m venv venv
   ```
2. Activate the virtual environment:
   - Windows: `venv\Scripts\activate`
   - Mac/Linux: `source venv/bin/activate`
3. Install dependencies:
   ```bash
   pip install django requests django-cors-headers
   ```

## Running the Server
```bash
python manage.py runserver
```

The proxy will be available at `http://127.0.0.1:8000/api/cse/`.

## Endpoints
- `POST /api/cse/company-info` (symbol)
- `GET  /api/cse/today-prices`
- `GET  /api/cse/trade-summary`
- `POST /api/cse/chart-data` (symbol)
- `GET  /api/cse/market-status`
- `GET  /api/cse/top-gainers`
- `GET  /api/cse/top-losers`
- `GET  /api/cse/aspi-data`
- `GET  /api/cse/snp-data`
