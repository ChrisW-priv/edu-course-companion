import os

from django.contrib.auth import get_user_model
from django.core.management.base import BaseCommand


class Command(BaseCommand):
    help = "Creates an admin user non-interactively if it doesn't exist"
    EMAIL = 'admin-no-exist-email@axpo.com'

    def handle(self, *args, **options):
        User = get_user_model()

        if not User.objects.filter(username='admin').exists():
            User.objects.create_superuser(
                username='admin', email=self.EMAIL, password=os.environ['DJANGO_SUPERUSER_PASSWORD']
            )
            self.stdout.write(self.style.SUCCESS('Admin user created'))
        else:
            self.stdout.write(self.style.SUCCESS('Admin user already exists'))
