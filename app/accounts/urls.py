from django.conf.urls import url
from app.accounts.views import Login, logout_view, Signup, check_email


urlpatterns = [
    url(r'^logout/$', view=logout_view, name='logout'),
    url(r'^login/$', view=Login.as_view(), name='login'),
    url(r'^signup/$', view=Signup.as_view(), name='signup'),
    url(r'^check-email/$', view=check_email, name='check_email'),
]
