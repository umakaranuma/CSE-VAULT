from django.urls import path, include

urlpatterns = [
    path('api/cse/', include('apps.cse_proxy.urls')),
]
