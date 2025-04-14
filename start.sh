#!/bin/bash

# Start server.py in the background
python3 ./server.py &

# Run watch-folder.sh in the foreground so its logs show up in `docker logs`
exec ./watch-folder.sh