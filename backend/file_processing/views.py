from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status


class EventarcHandler(APIView):
    def post(self, request, format=None):
        event = request.data
        bucket = event.get('data', {}).get('bucket')
        name = event.get('data', {}).get('name')
        print(f'Received file: gs://{bucket}/{name}')
        return Response(status=status.HTTP_204_NO_CONTENT)
