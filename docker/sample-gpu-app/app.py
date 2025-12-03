#!/usr/bin/env python3
"""
Sample GPU Application
Demonstrates GPU workload scheduling and monitoring on Kubernetes
"""

import os
import time
import threading
import subprocess
from flask import Flask, jsonify
from prometheus_client import Counter, Histogram, Gauge, generate_latest, CONTENT_TYPE_LATEST

# Initialize Flask app
app = Flask(__name__)

# Prometheus metrics
REQUEST_COUNT = Counter('app_requests_total', 'Total request count', ['method', 'endpoint', 'status'])
REQUEST_LATENCY = Histogram('app_request_latency_seconds', 'Request latency', ['endpoint'])
GPU_AVAILABLE = Gauge('app_gpu_available', 'Number of GPUs available')
GPU_MEMORY_USED = Gauge('app_gpu_memory_used_bytes', 'GPU memory used in bytes', ['gpu_index'])
COMPUTATION_COUNT = Counter('app_gpu_computations_total', 'Total GPU computations performed')

def check_nvidia_smi():
    """Check if nvidia-smi is available and return GPU info"""
    try:
        result = subprocess.run(
            ['nvidia-smi', '--query-gpu=index,name,memory.used,memory.total,utilization.gpu',
             '--format=csv,noheader,nounits'],
            capture_output=True,
            text=True,
            timeout=10
        )
        if result.returncode == 0:
            gpus = []
            for line in result.stdout.strip().split('\n'):
                if line:
                    parts = [p.strip() for p in line.split(',')]
                    if len(parts) >= 5:
                        gpus.append({
                            'index': int(parts[0]),
                            'name': parts[1],
                            'memory_used_mb': int(parts[2]),
                            'memory_total_mb': int(parts[3]),
                            'utilization_percent': int(parts[4])
                        })
            return gpus
        return []
    except (subprocess.TimeoutExpired, FileNotFoundError, Exception):
        return []

def update_gpu_metrics():
    """Background thread to update GPU metrics"""
    while True:
        gpus = check_nvidia_smi()
        GPU_AVAILABLE.set(len(gpus))
        for gpu in gpus:
            GPU_MEMORY_USED.labels(gpu_index=str(gpu['index'])).set(
                gpu['memory_used_mb'] * 1024 * 1024  # Convert to bytes
            )
        time.sleep(15)

def simulate_gpu_work():
    """Simulate GPU computation work"""
    try:
        import numpy as np
        # Simulate matrix operations (would use GPU if cupy/pytorch installed)
        size = 1000
        a = np.random.rand(size, size)
        b = np.random.rand(size, size)
        _ = np.dot(a, b)
        COMPUTATION_COUNT.inc()
        return True
    except Exception as e:
        print(f"Computation error: {e}")
        return False

@app.route('/')
def index():
    """Main endpoint"""
    start = time.time()
    REQUEST_COUNT.labels(method='GET', endpoint='/', status='200').inc()

    gpus = check_nvidia_smi()
    response = {
        'status': 'healthy',
        'service': 'sample-gpu-app',
        'gpu_count': len(gpus),
        'gpus': gpus,
        'environment': os.getenv('ENVIRONMENT', 'unknown'),
        'pod_name': os.getenv('POD_NAME', 'unknown'),
        'node_name': os.getenv('NODE_NAME', 'unknown')
    }

    REQUEST_LATENCY.labels(endpoint='/').observe(time.time() - start)
    return jsonify(response)

@app.route('/compute')
def compute():
    """Trigger GPU computation"""
    start = time.time()

    success = simulate_gpu_work()
    status = '200' if success else '500'
    REQUEST_COUNT.labels(method='GET', endpoint='/compute', status=status).inc()

    response = {
        'status': 'success' if success else 'error',
        'computation_time_ms': (time.time() - start) * 1000
    }

    REQUEST_LATENCY.labels(endpoint='/compute').observe(time.time() - start)
    return jsonify(response), 200 if success else 500

@app.route('/metrics')
def metrics():
    """Prometheus metrics endpoint"""
    return generate_latest(), 200, {'Content-Type': CONTENT_TYPE_LATEST}

@app.route('/health')
def health():
    """Health check endpoint"""
    return jsonify({'status': 'healthy'}), 200

@app.route('/ready')
def ready():
    """Readiness check endpoint"""
    # Could add dependency checks here
    return jsonify({'status': 'ready'}), 200

if __name__ == '__main__':
    # Start background metrics updater
    metrics_thread = threading.Thread(target=update_gpu_metrics, daemon=True)
    metrics_thread.start()

    # Run Flask app
    port = int(os.getenv('PORT', '8080'))
    app.run(host='0.0.0.0', port=port, threaded=True)
