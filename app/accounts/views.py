# -*- coding: utf-8 -*-
from __future__ import unicode_literals

from django.contrib import messages
from django.contrib.auth import authenticate, login, logout
from django.contrib.auth.decorators import login_required
from django.http import HttpResponse
from django.shortcuts import redirect, render
from django.views import View
from django.views.decorators.csrf import csrf_exempt

from app.accounts.forms import LoginForm
from app.accounts.models import Account

from common.util.logger import get_custom_logger

log = get_custom_logger()

# Create your views here.


def index(request):
    log.info(request.user)
    return render(request, 'common/index.html', {'nbar': 'home'})


def logout_view(request):
    logout(request)
    return redirect('login')


class Login(View):

    @staticmethod
    def get(request):
        if request.user.is_authenticated():
            return redirect('dashboard', permanent=True)
        return render(request, 'accounts/login.html',
                      {'nbar': 'login', 'error': False})

    @staticmethod
    def post(request):
        print("BEFORE.................")
        form = LoginForm(request.POST)
        if not form.is_valid():
            return render(
                request,
                'accounts/login.html',
                {
                    'nbar': 'login', 'error': True,
                    'msg': 'Invalid Credentials. Please try \
                    again!!'
                }
            )
        user = authenticate(
            username=form.data['email'], password=form.data['password'])
        if not user:
            return render(
                request,
                'accounts/login.html',
                {
                    'nbar': 'login', 'error': True,
                    'msg': 'Invalid Credentials. Please try \
                    again!!'
                }
            )
        login(request, user)
        return redirect('dashboard', permanent=True)


class Signup(View):

    @staticmethod
    def get(request):
        return render(request, 'accounts/signup.html', {'nbar': 'signup'})

    @staticmethod
    def post(request):
        password = request.POST['password']
        account = Account(
            username=request.POST['username'],
            email=request.POST['email']
        )
        account.set_password(password)
        account.save()
        user = authenticate(username=account.email, password=password)
        if user:
            login(request, user)
            messages.success(request, 'Your account has created successfully!')
            return redirect('dashboard', permanent=True)
        return render(request, 'accounts/signup.html', {'nbar': 'signup'})


@csrf_exempt
def check_email(request):
    if request.method == "POST":
        email = request.POST.get("email", None)
        user = Account.objects.filter(email__iexact=email.lower()).first()
        return HttpResponse("false" if user else "true")
