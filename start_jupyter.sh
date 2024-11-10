#!/bin/bash
cd /home/gap_sdk_private
source .venv/bin/activate
source configs/gap9_evk_audio.sh
cd /home
exec /home/gap_sdk_private/.venv/bin/jupyter notebook --ip=0.0.0.0 --port=8888 --no-browser --allow-root
