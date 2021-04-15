#!/bin/bash
set -euo pipefail

gosu pubobot esh -o config.cfg config.esh
gosu pubobot esh -o client_config.py client_config.esh
touch modules/gtvd_config.py
exec gosu pubobot python3 pubobot.py
