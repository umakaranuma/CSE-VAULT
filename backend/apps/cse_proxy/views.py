import requests
from django.http import JsonResponse, HttpResponse
from django.views.decorators.csrf import csrf_exempt

BASE_CSE_URL = "https://www.cse.lk/api/"

# CSE.lk validates these headers on every request — without them it returns 403
CSE_HEADERS = {
    'Referer': 'https://www.cse.lk/',
    'Origin': 'https://www.cse.lk',
    'User-Agent': (
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) '
        'AppleWebKit/537.36 (KHTML, like Gecko) '
        'Chrome/124.0.0.0 Safari/537.36'
    ),
    'Accept': 'application/json, text/plain, */*',
    'Accept-Language': 'en-US,en;q=0.9',
}


def forward_post(endpoint, data=None):
    """All CSE.lk endpoints require POST — GET returns 405."""
    url = f"{BASE_CSE_URL}{endpoint}"
    try:
        response = requests.post(url, data=data, headers=CSE_HEADERS, timeout=10)

        if response.status_code != 200:
            return JsonResponse(
                {"error": f"CSE returned {response.status_code}", "body": response.text[:300]},
                status=response.status_code,
            )

        if not response.text.strip():
            return JsonResponse({"error": "CSE returned empty body"}, status=502)

        return JsonResponse(response.json(), safe=False)
    except requests.exceptions.JSONDecodeError:
        return JsonResponse(
            {"error": "CSE returned non-JSON", "body": response.text[:300]},
            status=502,
        )
    except Exception as e:
        return JsonResponse({"error": str(e)}, status=500)


# --- Views (all csrf_exempt so Flutter can call them freely) ---

@csrf_exempt
def company_info_summary(request):
    symbol = request.POST.get('symbol') or request.GET.get('symbol', '')
    return forward_post("companyInfoSummery", data={'symbol': symbol})

@csrf_exempt
def today_share_price(request):
    return forward_post("todaySharePrice")

@csrf_exempt
def trade_summary(request):
    return forward_post("tradeSummary")

@csrf_exempt
def chart_data(request):
    symbol = request.POST.get('symbol') or request.GET.get('symbol', '')
    return forward_post("chartData", data={'symbol': symbol})

@csrf_exempt
def market_status(request):
    return forward_post("marketStatus")

@csrf_exempt
def top_gainers(request):
    return forward_post("topGainers")

@csrf_exempt
def top_losers(request):
    return forward_post("topLooses")

@csrf_exempt
def aspi_data(request):
    return forward_post("aspiData")

@csrf_exempt
def snp_data(request):
    return forward_post("snpData")
