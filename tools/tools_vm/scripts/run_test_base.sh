#!/bin/bash

# This script will pass base edition system test to an external controller
# Please make sure you can ping external controller before launching the script

MYIP=`ifconfig  | grep 'inet addr:'| grep -v '127.0.0.1' | cut -d: -f2 | awk '{ print $1}'`
if [ -d $1 ]; then
   echo "Usage: run_test_base.sh [controllerIP]"
   echo ""
   exit 1
fi
cd ~
pybot -d ${HOME} -v ODL_SYSTEM_IP:$1 -v TOOLS_SYSTEM_IP:$MYIP -v USER_HOME:${HOME} -v TOOLS_SYSTEM_USER:${USER} ${HOME}/integration/test/csit/suites/base
