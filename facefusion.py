#!/usr/bin/env python3

import os
import sys
from facefusion import core

if __name__ == '__main__':
    port = os.environ.get("PORT", "8080")
    sys.argv = ['facefusion', 'run', '--host', '0.0.0.0', '--port', port]
    core.cli()
