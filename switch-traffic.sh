#!/bin/bash

if [ "$1" == "blue" ]; then
  kubectl patch service blue-green-service -p '{"spec": {"selector": {"app": "blue"}}}'
  echo "Switched traffic to Blue."
elif [ "$1" == "green" ]; then
  kubectl patch service blue-green-service -p '{"spec": {"selector": {"app": "green"}}}'
  echo "Switched traffic to Green."
else
  echo "Usage: ./switch-traffic.sh [blue|green]"
fi
