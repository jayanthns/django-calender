from django.conf.urls import url

from views import dashboard

urlpatterns = [
    url(r'^dashboard/$', view=dashboard, name='dashboard'),
]