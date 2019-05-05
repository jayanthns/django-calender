from django import forms

from app.accounts.models import Account


class LoginForm(forms.Form):
    class Meta:
        model = Account
        fields = ('email', 'password')


class UserCreateForm(forms.ModelForm):
    class Meta:
        model = Account
        widgets = {
            'password': forms.PasswordInput()
        }
        fields = '__all__'
