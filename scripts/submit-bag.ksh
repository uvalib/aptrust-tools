#!/usr/bin/env bash
#
# A helper to copy a bag file to the specified bucket
#

#set -x

# source common helpers
SCRIPT_DIR=$( (cd -P $(dirname $0) && pwd) )
. $SCRIPT_DIR/common.ksh

function show_use_and_exit {
   error_and_exit "use: $(basename $0) <bag file> <bucket name>"
}

# ensure correct usage
if [ $# -lt 2 ]; then
   show_use_and_exit
fi

# input parameters for clarity
BAG_FILE=$1
shift
BUCKET_NAME=$1
shift

# check the bag file exists
ensure_file_exists $BAG_FILE

# ensure we have the necessary tools available
AWS_TOOL=aws
ensure_tool_available $AWS_TOOL
JQ_TOOL=jq
ensure_tool_available $JQ_TOOL

# upload the file
BASE_NAME=$(basename $BAG_FILE)
$AWS_TOOL s3 cp ${BAG_FILE} s3://${BUCKET_NAME}/${BASE_NAME} --quiet
exit_on_error $? "uploading $BASE_NAME"

# now get the etag so we can track it later
ETAG=$($AWS_TOOL s3api head-object --bucket $BUCKET_NAME --key $BASE_NAME | $JQ_TOOL ".ETag" | tr -d "\"\\")
if [ -z "$ETAG" ]; then
   exit_on_error 1 "getting etag for $BASE_NAME"
fi

# write the etag
echo "$ETAG" > ${BAG_FILE}.etag

# all over
exit 0

#
# end of file
#
