import os
from django.conf import settings

BASE_DIR = settings.BASE_DIR

# Static files (CSS, JavaScript, Images)
# https://docs.djangoproject.com/en/5.2/howto/static-files/

STATIC_URL = 'static/'

PUBLIC_MOUNT = BASE_DIR.parent / 'data' / 'public'
PRIVATE_MOUNT = BASE_DIR.parent / 'data' / 'private'

STATIC_FOLDER_NAME = 'django-static'
STATIC_ROOT = PUBLIC_MOUNT / STATIC_FOLDER_NAME

UPLOAD_FOLDER_NAME = 'nexus-uploads'
MEDIA_ROOT = PRIVATE_MOUNT / UPLOAD_FOLDER_NAME

if settings.DEBUG:
    STATIC_URL = '/static/'
    MEDIA_URL = '/media/'
else:
    static_bucket_name = os.environ.get('STATIC_BUCKET_NAME', None)
    upload_bucket_name = os.environ.get('UPLOAD_BUCKET_NAME', None)
    STATIC_URL = f'https://storage.googleapis.com/{static_bucket_name}/{STATIC_FOLDER_NAME}/'
    MEDIA_URL = f'https://storage.googleapis.com/{upload_bucket_name}/{UPLOAD_FOLDER_NAME}/'
