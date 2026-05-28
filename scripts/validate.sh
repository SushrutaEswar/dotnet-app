#!/bin/bash

echo "Validating application"

sleep 15

curl -f http://localhost/health

if [ $? -ne 0 ]; then
  echo "Health check failed"
  exit 1
fi

echo "Application healthy"