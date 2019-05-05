# -*- coding: utf-8 -*-
from __future__ import unicode_literals

from django.db import models

# Create your models here.
from app.accounts.models import Account


class Calender(models.Model):
    created_on = models.DateTimeField(auto_now_add=True)
    user = models.OneToOneField(Account, on_delete=models.CASCADE, primary_key=True)
    is_active = models.BooleanField(default=True)

    class Meta:
        db_table = "calenders"
