from django.conf.urls import url

from schedule.views import dashboard

urlpatterns = [
    url(r'^dashboard/$', view=dashboard, name='dashboard'),
]