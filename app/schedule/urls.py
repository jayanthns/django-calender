from django.conf.urls import url

from app.schedule.views import dashboard

urlpatterns = [
    url(r'^dashboard/$', view=dashboard, name='dashboard'),
]
