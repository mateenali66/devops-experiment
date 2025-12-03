#!/usr/bin/env python3
"""
CI/CD Pipeline Diagram
Generates: cicd_pipeline.png
"""

from diagrams import Diagram, Cluster, Edge
from diagrams.onprem.vcs import Github
from diagrams.onprem.ci import GithubActions
from diagrams.onprem.gitops import Flux
from diagrams.aws.compute import EKS, ECR
from diagrams.aws.storage import S3
from diagrams.aws.security import IAM
from diagrams.custom import Custom

graph_attr = {
    "fontsize": "20",
    "bgcolor": "white",
    "pad": "0.5",
    "splines": "ortho",
}

with Diagram(
    "CI/CD Pipeline",
    filename="cicd_pipeline",
    outformat="png",
    show=False,
    direction="LR",
    graph_attr=graph_attr,
):

    dev = Github("Developer\nPush")

    with Cluster("GitHub Actions"):
        with Cluster("Infrastructure Pipeline"):
            tf_validate = GithubActions("TF Validate\n& Lint")
            tf_plan = GithubActions("TF Plan\n(PR Preview)")
            tf_apply = GithubActions("TF Apply\n(Main)")

        with Cluster("Container Pipeline"):
            build = GithubActions("Docker\nBuild")
            scan = GithubActions("Trivy\nScan")
            push = GithubActions("Push to\nECR")

    # AWS Resources
    ecr = ECR("Container\nRegistry")
    s3 = S3("TF State")
    eks = EKS("EKS Cluster")

    # GitOps
    flux = Flux("Flux CD\n(GitOps)")

    # Infrastructure flow
    dev >> tf_validate >> tf_plan >> tf_apply >> s3
    tf_apply >> eks

    # Container flow
    dev >> build >> scan >> push >> ecr

    # GitOps sync
    flux >> Edge(label="sync") >> eks
    ecr >> Edge(label="pull") >> eks
