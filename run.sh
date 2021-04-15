#!/bin/bash
set -euo pipefail

esh -o config.cfg config.esh
esh -o client_config.py client_config.esh
touch modules/gtvd_config.py
exec gosu python3 pubobot.py
