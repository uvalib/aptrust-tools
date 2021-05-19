#!/usr/bin/env bash
#
# A helper to wait for the status of a bag file until a terminating condition
#

#set -x

# source common helpers
SCRIPT_DIR=$( (cd -P $(dirname $0) && pwd) )
. $SCRIPT_DIR/common.ksh

function show_use_and_exit {
   error_and_exit "use: $(basename $0) <bag file>"
}

# ensure correct usage
if [ $# -lt 1 ]; then
   show_use_and_exit
fi

# input parameters for clarity
BAG_FILE=$1
shift

# status tool
STATUS_TOOL=$SCRIPT_DIR/status-bag.ksh
ensure_file_exists $STATUS_TOOL

# check the input file exists
ensure_file_exists $BAG_FILE
BASE_NAME=$(basename $BAG_FILE)

while true; do
   echo -n "status $BASE_NAME... "

   # get the status
   STATUS=$($STATUS_TOOL ${BAG_FILE})
   echo $STATUS

   # happy day...
   if [ "$STATUS" == "Success" ]; then
      exit 0
   fi

   # sad panda...
   if [ "$STATUS" == "Failed" ]; then
      exit 1
   fi

   # wait...
   sleep 5

done

# its all over
exit 0

#
# end of file
#
