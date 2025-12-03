#!/usr/bin/env python3
"""
Standalone health check script
Used by container health checks
"""

import sys
import urllib.request
import urllib.error

def check_health():
    """Check if the application is healthy"""
    try:
        response = urllib.request.urlopen('http://localhost:8080/health', timeout=5)
        return response.status == 200
    except urllib.error.URLError:
        return False
    except Exception:
        return False

if __name__ == '__main__':
    sys.exit(0 if check_health() else 1)
