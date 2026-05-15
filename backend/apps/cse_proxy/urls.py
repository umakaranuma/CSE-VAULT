from django.urls import path
from . import views

urlpatterns = [
    path('company-info', views.company_info_summary, name='company-info'),
    path('today-prices', views.today_share_price, name='today-prices'),
    path('trade-summary', views.trade_summary, name='trade-summary'),
    path('chart-data', views.chart_data, name='chart-data'),
    path('market-status', views.market_status, name='market-status'),
    path('top-gainers', views.top_gainers, name='top-gainers'),
    path('top-losers', views.top_losers, name='top-losers'),
    path('aspi-data', views.aspi_data, name='aspi-data'),
    path('snp-data', views.snp_data, name='snp-data'),
]
