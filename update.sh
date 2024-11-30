#!/bin/sh
git pull
dub build -b release --combined --compiler /home/ponce/ldc2-1.28.0-linux-x86_64/bin/ldc2
sudo systemctl restart dplugorg.service
