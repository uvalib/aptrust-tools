#!/usr/bin/env bash
#
# A helper to upload a set of bag files
#

#set -x

# source common helpers
SCRIPT_DIR=$( (cd -P $(dirname $0) && pwd) )
. $SCRIPT_DIR/common.ksh

function show_use_and_exit {
   error_and_exit "use: $(basename $0) <input directory> <bucket name>"
}

# ensure correct usage
if [ $# -lt 2 ]; then
   show_use_and_exit
fi

# input parameters for clarity
INPUT_DIR=$1
shift
BUCKET_NAME=$1
shift

# submitter tool
SUBMITTER=$SCRIPT_DIR/submit-bag.ksh
ensure_file_exists $SUBMITTER

# check the input directory exists
ensure_dir_exists $INPUT_DIR

# local definitions
TMPFILE=/tmp/submit-all.$$

# find all the files of a specified pattern
find $INPUT_DIR -type f -name \*.tar | grep ".tar" > $TMPFILE

# for all the directories we located
for i in $(<$TMPFILE); do
   BASE_NAME=$(basename $i)
   echo "submitting $BASE_NAME..."

   $SUBMITTER ${INPUT_DIR}/${BASE_NAME} $BUCKET_NAME
   exit_on_error $? "while submitting $BASE_NAME"
done

# cleanup
rm -fr $TMPFILE > /dev/null 2>&1

# its all over
exit 0

#
# end of file
#
