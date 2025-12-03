#!/usr/bin/env python3
"""
GitOps Workflow Diagram
Generates: gitops_flow.png
"""

from diagrams import Diagram, Cluster, Edge
from diagrams.onprem.vcs import Github
from diagrams.onprem.gitops import Flux
from diagrams.aws.compute import EKS
from diagrams.k8s.compute import Deployment, Pod
from diagrams.k8s.network import Service
from diagrams.k8s.controlplane import API
from diagrams.onprem.monitoring import Prometheus, Grafana

graph_attr = {
    "fontsize": "20",
    "bgcolor": "white",
    "pad": "0.5",
    "splines": "ortho",
}

with Diagram(
    "GitOps Workflow with Flux",
    filename="gitops_flow",
    outformat="png",
    show=False,
    direction="TB",
    graph_attr=graph_attr,
):

    # Git as source of truth
    with Cluster("GitHub Repository"):
        repo = Github("devops-experiment")

        with Cluster("kubernetes/"):
            infra = Github("infrastructure/\n(Helm Releases)")
            apps = Github("apps/\n(Workloads)")

    # Flux Controller
    with Cluster("EKS Cluster"):

        with Cluster("flux-system namespace"):
            flux = Flux("Flux Controllers")
            source = Flux("Source\nController")
            kustomize = Flux("Kustomize\nController")
            helm = Flux("Helm\nController")

        api = API("Kubernetes\nAPI Server")

        with Cluster("Deployed Resources"):
            with Cluster("monitoring"):
                prom = Prometheus("Prometheus")
                graf = Grafana("Grafana")

            with Cluster("apps"):
                deploy = Deployment("App\nDeployments")
                pods = Pod("Running\nPods")

    # Flow
    repo >> Edge(label="git pull") >> source
    source >> kustomize
    source >> helm
    kustomize >> Edge(label="apply") >> api
    helm >> Edge(label="apply") >> api
    api >> prom
    api >> deploy >> pods
