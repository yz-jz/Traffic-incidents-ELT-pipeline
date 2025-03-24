import os
from googleapiclient import discovery
from google.auth import default

# Authenticate with Google Cloud
credentials, project_id = default()
compute = discovery.build("compute", "v1", credentials=credentials)

INSTANCE_NAME = os.environ("compute_instance")
ZONE = os.environ("gcp_zone")

def start_instance():
    """Start a stopped Compute Engine instance"""
    request = compute.instances().start(
        project=project_id, zone=ZONE, instance=INSTANCE_NAME
    )
    response = request.execute()

if __name__ == "__main__":
    start_instance()

