from django.urls import path
from .views import EventarcHandler

urlpatterns = [
    path('', EventarcHandler.as_view()),
]
