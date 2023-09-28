#!/usr/bin/env bash
#
# A helper to wait for all the bags processing to complete
#

#set -x

# source common helpers
SCRIPT_DIR=$( (cd -P $(dirname $0) && pwd) )
. $SCRIPT_DIR/common.ksh

function show_use_and_exit {
   error_and_exit "use: $(basename $0) <input directory>"
}

# ensure correct usage
if [ $# -lt 1 ]; then
   show_use_and_exit
fi

# input parameters for clarity
INPUT_DIR=$1
shift

# wait tool
WAIT_TOOL=$SCRIPT_DIR/wait-bag-complete.ksh
ensure_file_exists $WAIT_TOOL

# check the input directory exists
ensure_dir_exists $INPUT_DIR

# define TMP if not done already
TMP=${TMP:-/tmp}

# local definitions
TMPFILE=${TMP}/wait-all.$$

# track our progress
SUCCESS_COUNT=0
ERROR_COUNT=0

# find all the files of a specified pattern
find $INPUT_DIR -type f -name \*.tar | grep ".tar" > $TMPFILE

# for all the directories we located
for i in $(<$TMPFILE); do
   BASE_NAME=$(basename $i)

   # wait for complete
   $WAIT_TOOL ${INPUT_DIR}/${BASE_NAME}
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
