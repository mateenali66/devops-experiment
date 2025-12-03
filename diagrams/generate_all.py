#!/usr/bin/env python3
"""
Generate all architecture diagrams.
Run this script to regenerate all PNG diagrams.

Usage:
    python3 generate_all.py

Or run individual diagrams:
    python3 architecture.py
    python3 cicd_pipeline.py
    python3 gpu_inference.py
    python3 gitops_flow.py
"""

import subprocess
import sys
from pathlib import Path

DIAGRAMS = [
    "architecture.py",
    "cicd_pipeline.py",
    "gpu_inference.py",
    "gitops_flow.py",
]

def main():
    script_dir = Path(__file__).parent

    for diagram in DIAGRAMS:
        diagram_path = script_dir / diagram
        print(f"Generating {diagram}...")

        result = subprocess.run(
            [sys.executable, str(diagram_path)],
            cwd=str(script_dir),
            capture_output=True,
            text=True
        )

        if result.returncode != 0:
            print(f"  Error: {result.stderr}")
        else:
            png_name = diagram.replace(".py", ".png")
            print(f"  Created: {png_name}")

    print("\nDone! All diagrams generated in diagrams/ directory.")

if __name__ == "__main__":
    main()
