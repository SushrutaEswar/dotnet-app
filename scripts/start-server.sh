#!/bin/bash

echo "Starting .NET API"

cd /var/www/dotnetapi

pkill dotnet || true

nohup dotnet DotNetMinimalAPI.dll > app.log 2>&1 &