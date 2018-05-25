from django.conf.urls import url

from views import CreateMyCalender, MyCalender, get_calender_days

urlpatterns = [
    url(r'^create-calender/$', view=CreateMyCalender.as_view(), name='create_my_calender'),
    url(r'^my-calender/$', view=MyCalender.as_view(), name='my_calender'),
    url(r'^get-calender-days/$', view=get_calender_days, name='get_calender_days'),
]