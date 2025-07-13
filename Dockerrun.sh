#!/bin/bash

if bash -c 'docker images | grep thadigus-glpages'; then
  echo 'Image found locally, proceeding with run...'
else
  echo 'Image not found, building image...'
  docker build -t thadigus-glpages:latest -f ./.devcontainer/Dockerfile . 
fi

docker run --rm -it --network host -v ./:/code thadigus-glpages:latest
