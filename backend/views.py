from django.http import JsonResponse
from django.shortcuts import redirect


def api_root(request):
    """
    Root view that provides API information and redirects to documentation
    """
    if request.method == 'GET':
        return JsonResponse({
            'message': 'Outing Management System API',
            'version': '1.0.0',
            'endpoints': {
                'api_docs': '/api/docs/',
                'api_schema': '/api/schema/',
                'admin': '/admin/',
                'api_endpoints': {
                    'accounts': '/api/accounts/',
                    'outings': '/api/outings/',
                    'auditlog': '/api/auditlog/',
                    'notifications': '/api/notifications/'
                }
            },
            'description': 'Multi-level outing approval and gate verification system',
            'status': 'running'
        })
    
    return JsonResponse({'error': 'Method not allowed'}, status=405)
