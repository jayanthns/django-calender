# -*- coding: utf-8 -*-
from __future__ import unicode_literals

from django.contrib.auth.decorators import login_required
from django.http import HttpResponse
from django.shortcuts import render, redirect

# Create your views here.
from django.utils.decorators import method_decorator
from django.views import View

from app.calender.models import Calender
from django.contrib import messages
import datetime
import calendar
import json

WEEK_DAYS = ('Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday')
MONTH_NAMES = (
    'January', 'February', 'March', 'April', 'May', 'June', 'July',
    'August', 'September', 'October', 'November', 'December'
)


def get_days_dict(year, month):
    today = datetime.datetime.now()
    num_days = calendar.monthrange(year, month)[1]
    days = [datetime.date(year, month, day) for day in range(1, num_days + 1)]
    days_dict = [
        {
            day.day: calendar.day_name[day.weekday()],
            'disable': day.day < today.day or month < today.month
        }
        for day in days
    ]
    print(days_dict)
    dict = {
        'days': days_dict,
        'year': year,
        'month': month,
        'today': today.day
    }
    return dict


def is_muted_month(c_year, c_month, p_year, p_month, c_day, p_day):
    if p_year < c_year:
        return True
    elif p_year == c_year:
        if p_month < c_month:
            return True
        elif p_month == c_month:
            if p_day < c_day:
                return True
            else:
                return False
    else:
        return False


def modified_get_days_dict(year, month):
    today = datetime.datetime.now()
    num_days = calendar.monthrange(year, month)[1]
    days = [datetime.date(year, month, day) for day in range(1, num_days + 1)]
    p_month = month - 1
    p_year = year
    if p_month == 0:
        p_month = 12
        p_year -= 1

    p_num_days = calendar.monthrange(p_year, p_month)[1]
    p_days = [datetime.date(p_year, p_month, p_day) for p_day in range(1, p_num_days + 1)]

    n_month = month + 1
    n_year = year
    if n_month > 12:
        n_month = 1
        n_year += 1

    n_num_days = calendar.monthrange(n_year, n_month)[1]
    n_days = [datetime.date(n_year, n_month, n_day) for n_day in range(1, n_num_days + 1)]

    days_dict = [
        {
            'styles': 'tdClass ' +
            ('today ' if (
                day.day == today.day and
                day.month == today.month and
                day.year == today.year
            ) else '') +
            ('oldMonth ' if is_muted_month(
                today.year, today.month, year, month, today.day, day.day
            ) else 'currentMonthDays '),

            'day': day.day,
            'week_day': calendar.day_name[day.weekday()],
            'extra': ''
            # 'current_month': day.month == today.month and day.year == today.year,
            # 'active': day.day == today.day and day.month == today.month and day.year == today.year,
        }
        for day in days
    ]
    first_day = days_dict[0]['week_day']
    starts_at = WEEK_DAYS.index(first_day)
    if starts_at > 0:
        p_days = p_days[-starts_at:]
    else:
        p_days = []
    print(p_days)
    p_days_dict = [
        {
            'styles': 'tdClass muted',
            'day': day.day,
            'week_day': calendar.day_name[day.weekday()],
            'extra': 'e',
            # 'current_month': False,
            # 'active': False,
        }
        for day in p_days
    ]
    days_dict = p_days_dict + days_dict

    remains = 0

    if not days_dict.__len__() % 7 == 0:
        print("NO COMPLETED")
        remains = 7 - (days_dict.__len__() % 7)

    if remains > 0:
        n_days = n_days[:remains]
    else:
        n_days = []

    n_days_dict = [
        {
            'styles': 'tdClass muted',
            'day': day.day,
            'week_day': calendar.day_name[day.weekday()],
            'extra': 'e',
            # 'current_month': False,
            # 'active': False,
        }
        for day in n_days
    ]
    days_dict += n_days_dict
    # print(days_dict)

    dict = {
        'days': days_dict,
        'year': year,
        'month': month,
        'month_name': MONTH_NAMES[month - 1],
        'today': str(today.day) + '/' + str(today.month) + '/' + str(today.year)
    }
    return dict


class MyCalender(View):
    @method_decorator(login_required)
    def get(self, request):
        if request.user.is_interviewer:
            try:
                user_calender = Calender.objects.get(user=request.user)
            except:
                user_calender = None
            data = {
                'nbar': 'calender',
                'user_calender': user_calender,
                'show_msg': False
            }
            return render(request, 'calender/my_calender.html', data)
        else:
            return redirect('dashboard')


class CreateMyCalender(View):
    @method_decorator(login_required)
    def post(self, request):
        if request.user.is_interviewer:
            data = {'nbar': 'calender', 'show_msg': True}
            try:
                Calender.objects.get(user=request.user)
                messages.warning(request, 'You have already created your calender!')
            except:
                Calender.objects.create(user=request.user)
                messages.success(request, 'Your Calender has created successfully.')
            return redirect('my_calender')
        else:
            return redirect('dashboard')


def get_calender_days(request):
    if request.method == 'GET':
        year, month = int(request.GET['year']), int(request.GET['month'])

        return HttpResponse(
            json.dumps(modified_get_days_dict(year, month)),
            content_type='application/javascript; charset=utf8'
        )
