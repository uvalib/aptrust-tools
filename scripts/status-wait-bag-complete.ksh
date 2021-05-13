#!/usr/bin/env bash
#
# A helper to wait for the status of a bag file until a terminating condition
#

#set -x

# source common helpers
SCRIPT_DIR=$( (cd -P $(dirname $0) && pwd) )
. $SCRIPT_DIR/common.ksh

function show_use_and_exit {
   error_and_exit "use: $(basename $0) <bag file> <environment>"
}

# ensure correct usage
if [ $# -lt 2 ]; then
   show_use_and_exit
fi

# input parameters for clarity
BAG_FILE=$1
shift
ENVIRONMENT=$1
shift

# validate the environment parameter
case $ENVIRONMENT in
   test|production)
   ;;
   *) echo "ERROR: specify test or production, aborting"
   exit 1
   ;;
esac

# status tool
STATUS_TOOL=$SCRIPT_DIR/status-bag.ksh
ensure_file_exists $STATUS_TOOL

# check the input file exists
ensure_file_exists $BAG_FILE
BASE_NAME=$(basename $BAG_FILE)

while true; do
   echo -n "status $BASE_NAME... "

   # get the status
   STATUS=$($STATUS_TOOL ${BAG_FILE} $ENVIRONMENT)
   echo $STATUS
   if [ "$STATUS" == "Success" -o "$STATUS" == "Failed" ]; then
      break
   else
      sleep 3
   fi

done

# its all over
exit 0

#
# end of file
#
