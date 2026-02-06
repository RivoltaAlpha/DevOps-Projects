#!/bin/bash
set -x

checkjobs (){
    jobs
}

sleep 30 &
sleep 40 &

fg %40

echo "Current Jobs"
checkjobs

set +x              # Stop tracing

echo ""
echo ""
read -p "Press Enter to close..."
echo ""