#!/bin/bash
echo 'export PYTHONPATH=${PYTHONPATH}:/usr/local/lib/python3/dist-packages' >> /root/.bashrc
echo -e "$(head -1 /root/.vnc/xstartup)\nexport PYTHONPATH=\${PYTHONPATH}:/usr/local/lib/python3/dist-packages\n$(awk '(NR>1)' /root/.vnc/xstartup)" > /root/.vnc/xstartup
