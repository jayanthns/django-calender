# -*- coding: utf-8 -*-
from __future__ import unicode_literals

from django.contrib import admin

# from accounts.forms import UserCreateForm
from accounts.models import Account

# Register your models here.


class AccountAdmin(admin.ModelAdmin):
    # form = UserCreateForm
    pass


admin.site.register(Account, AccountAdmin)
