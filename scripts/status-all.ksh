#!/usr/bin/env bash
#
# A helper to get the status of a set of bag files
#

#set -x

# source common helpers
SCRIPT_DIR=$( (cd -P $(dirname $0) && pwd) )
. $SCRIPT_DIR/common.ksh

function show_use_and_exit {
   error_and_exit "use: $(basename $0) <input directory> <environment>"
}

# ensure correct usage
if [ $# -lt 2 ]; then
   show_use_and_exit
fi

# input parameters for clarity
INPUT_DIR=$1
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

# check the input directory exists
ensure_dir_exists $INPUT_DIR

# local definitions
TMPFILE=/tmp/status-all.$$

# track our progress
SUCCESS_COUNT=0
ERROR_COUNT=0

# find all the files of a specified pattern
find $INPUT_DIR -type f -name \*.tar | grep ".tar" > $TMPFILE

# for all the directories we located
for i in $(<$TMPFILE); do
   BASE_NAME=$(basename $i)
   echo -n "status $BASE_NAME... "

   # get the status
   $STATUS_TOOL ${INPUT_DIR}/${BASE_NAME} $ENVIRONMENT
   if [ $? -eq 0 ]; then
      ((SUCCESS_COUNT=SUCCESS_COUNT+1))
   else
      ((ERROR_COUNT=ERROR_COUNT+1))
   fi

done

# cleanup
rm -fr $TMPFILE > /dev/null 2>&1

# status message
echo "done... ${SUCCESS_COUNT} successful, ${ERROR_COUNT} error(s)"

# its all over
exit 0

#
# end of file
#
