# -*- coding: utf-8 -*-
from __future__ import unicode_literals

from django.contrib import messages
from django.contrib.auth.decorators import login_required
from django.http import HttpResponse
from django.shortcuts import render, redirect
from django.contrib.auth import authenticate, login, logout

# Create your views here.
from django.views import View
from django.views.decorators.csrf import csrf_exempt

from accounts.forms import LoginForm
from accounts.models import Account


def index(request):
    print(request.user)
    return render(request, 'common/index.html', {'nbar': 'home'})


def logout_view(request):
    logout(request)
    return redirect('login')


class Login(View):

    @staticmethod
    def get(request):
        if request.user.is_authenticated():
            print("EEEEEEEEEEEEEEEE")
            return redirect('dashboard', permanent=True)
        return render(request, 'accounts/login.html', {'nbar': 'login', 'error': False})

    @staticmethod
    def post(request):
        print("BEFORE.................")
        form = LoginForm(request.POST)
        if form.is_valid():
            user = authenticate(username=form.data['email'], password=form.data['password'])
            if user:
                login(request, user)
                return redirect('dashboard', permanent=True)
            else:
                return render(request, 'accounts/login.html', {'nbar': 'login', 'error': True, 'msg': 'Invalid Credentials. Please try again!!'})


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
