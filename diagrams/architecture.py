#!/usr/bin/env python3
"""
Main EKS Architecture Diagram
Generates: architecture.png
"""

from diagrams import Diagram, Cluster, Edge
from diagrams.aws.compute import EKS, EC2
from diagrams.aws.network import VPC, PrivateSubnet, PublicSubnet, NATGateway, InternetGateway, ELB
from diagrams.aws.storage import S3
from diagrams.aws.database import Dynamodb
from diagrams.aws.management import Cloudwatch
from diagrams.k8s.compute import Pod, Deployment
from diagrams.k8s.network import Ingress, Service
from diagrams.k8s.infra import Node
from diagrams.onprem.gitops import Flux
from diagrams.onprem.monitoring import Prometheus, Grafana

graph_attr = {
    "fontsize": "24",
    "bgcolor": "white",
    "pad": "0.5",
    "splines": "spline",
}

with Diagram(
    "DevOps Experiment - EKS Architecture",
    filename="architecture",
    outformat="png",
    show=False,
    direction="TB",
    graph_attr=graph_attr,
):

    # External
    internet = InternetGateway("Internet")

    with Cluster("AWS Cloud"):

        # State Management
        with Cluster("Terraform State"):
            s3 = S3("State Bucket")
            dynamodb = Dynamodb("Lock Table")

        with Cluster("VPC (10.0.0.0/16)"):

            # Public Subnets
            with Cluster("Public Subnets"):
                nat = NATGateway("NAT Gateway")
                alb = ELB("Application\nLoad Balancer")

            # Private Subnets - EKS
            with Cluster("Private Subnets"):

                with Cluster("EKS Cluster"):
                    eks = EKS("Control Plane")

                    with Cluster("CPU Node Group"):
                        cpu_nodes = [
                            Node("cpu-node-1"),
                            Node("cpu-node-2"),
                        ]

                    with Cluster("GPU Node Group (g4dn)"):
                        gpu_nodes = [
                            Node("gpu-node-1\n(T4 GPU)"),
                        ]

                    with Cluster("Platform Services"):
                        flux = Flux("Flux CD")
                        prometheus = Prometheus("Prometheus")
                        grafana = Grafana("Grafana")

    # Connections
    internet >> alb >> eks
    eks >> cpu_nodes
    eks >> gpu_nodes
    nat >> internet
    flux >> eks
    prometheus >> grafana
