#!/usr/bin/env python3

import os
import sys
from facefusion import core

# Set environment variable to control OpenMP threads
os.environ['OMP_NUM_THREADS'] = '1'

if __name__ == '__main__':
    # Set the port to 8080 as Cloud Run uses it by default
    port = os.environ.get("PORT", "8080")

    # Call core.cli() directly without manually passing host/port via sys.argv
    core.cli()
