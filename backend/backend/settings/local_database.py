from django.conf import settings

BASE_DIR = settings.BASE_DIR

# Database
# https://docs.djangoproject.com/en/5.2/ref/settings/#databases

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.sqlite3',
        'NAME': BASE_DIR / '..' / 'data' / 'private' / 'db.sqlite3',
    }
}
