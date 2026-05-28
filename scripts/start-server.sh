#!/bin/bash

echo "Starting .NET API"

cd /home/ubuntu/app

pkill dotnet || true

nohup dotnet DotNetMinimalAPI.dll > app.log 2>&1 &
