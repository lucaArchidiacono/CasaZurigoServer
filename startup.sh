#!/bin/bash

# Check if the argument is provided
if [ "$#" -eq 0 ]; then
    echo "Please provide a profile argument (debug or release)"
    exit 1
fi

# Check if the provided argument is either debug or release
if [ "$1" != "debug" ] && [ "$1" != "release" ]; then
    echo "Invalid profile argument. Please use 'debug' or 'release'"
    exit 1
fi

# Run Docker Compose with the specified profile
docker compose --profile "$1" up -d

if [ "$1" == "release" ] && [ "$1" != "release" ]; then
    docker compose --profile "$1" run migrate
    exit 0
fi
