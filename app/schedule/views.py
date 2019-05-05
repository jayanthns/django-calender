# -*- coding: utf-8 -*-
from __future__ import unicode_literals

from django.shortcuts import render
from django.contrib.auth.decorators import login_required

# Create your views here.


@login_required()
def dashboard(request):
    user = request.user
    template = 'schedule/dashboard.html' if user.is_interviewer else 'schedule/student_dashboard.html'
    return render(request, template, {'nbar': 'dashboard'})
