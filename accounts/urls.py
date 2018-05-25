from django.conf.urls import url
from views import Login, logout_view, Signup


urlpatterns = [
    url(r'^logout/$', view=logout_view, name='logout'),
    url(r'^login/$', view=Login.as_view(), name='login'),
    url(r'^signup/$', view=Signup.as_view(), name='signup'),
]
