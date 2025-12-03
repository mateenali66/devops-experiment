#!/usr/bin/env python3
"""
GPU/ML Inference Pipeline Diagram
Generates: gpu_inference.png
"""

from diagrams import Diagram, Cluster, Edge
from diagrams.aws.compute import EKS, EC2
from diagrams.aws.network import ELB, APIGateway
from diagrams.aws.ml import Sagemaker
from diagrams.aws.storage import S3
from diagrams.k8s.compute import Pod, Deployment
from diagrams.k8s.network import Service, Ingress
from diagrams.onprem.monitoring import Prometheus, Grafana
from diagrams.onprem.queue import Kafka
from diagrams.generic.device import Mobile

graph_attr = {
    "fontsize": "20",
    "bgcolor": "white",
    "pad": "0.5",
}

with Diagram(
    "GPU/ML Inference Pipeline",
    filename="gpu_inference",
    outformat="png",
    show=False,
    direction="LR",
    graph_attr=graph_attr,
):

    # Input
    audio = Mobile("Audio\nStream")

    with Cluster("EKS Cluster"):

        ingress = Ingress("API Gateway\n(Ingress)")

        with Cluster("GPU Node Pool (g4dn.xlarge)"):

            with Cluster("Inference Service"):
                svc = Service("Model Router\n(Load Balancer)")

                with Cluster("Model Versions"):
                    model_stable = Pod("Model v1.2\n(Stable 90%)")
                    model_canary = Pod("Model v1.3\n(Canary 10%)")

                gpu = EC2("NVIDIA T4\nGPU")

        with Cluster("Observability"):
            prometheus = Prometheus("Prometheus\n+ DCGM")
            grafana = Grafana("Grafana\nDashboards")

    # Model Storage
    s3 = S3("Model\nArtifacts")

    # Flow
    audio >> ingress >> svc
    svc >> model_stable >> gpu
    svc >> model_canary >> gpu
    s3 >> Edge(label="load") >> model_stable
    s3 >> Edge(label="load") >> model_canary
    prometheus >> grafana
    gpu >> Edge(label="metrics", style="dashed") >> prometheus
