#!/usr/bin/env bash
#
# A helper to create a bag from the specified directory
#

#set -x

# source common helpers
SCRIPT_DIR=$( (cd -P $(dirname $0) && pwd) )
. $SCRIPT_DIR/common.ksh

function show_use_and_exit {
   error_and_exit "use: $(basename $0) <input directory> <bag name> <sender ID> <group ID>"
}

# ensure correct usage
if [ $# -lt 4 ]; then
   show_use_and_exit
fi

# input parameters for clarity
INPUT_DIR=$1
shift
BAG_NAME=$1
shift
SENDER_ID=$1
shift
GROUP_ID=$1
shift

# ensure we have the tools available
JQ_TOOL=jq
ensure_tool_available $JQ_TOOL
TAR_TOOL=tar
ensure_tool_available $TAR_TOOL
PYTHON_TOOL=python3
ensure_tool_available $PYTHON_TOOL

# check the input directory exists
ensure_dir_exists $INPUT_DIR

# make sure we have the bagit tool available
$PYTHON_TOOL -m bagit --version > /dev/null 2>&1
exit_on_error $? "the bagit tool is not available; install with \"pip3 install bagit\""

# local definitions
OUTPUT_FILE=${BAG_NAME}.tar
BAGIT_OPTS="--quiet --bag-count 1 --source-organization virginia.edu --md5 --sha256 --internal-sender-description \"\" --internal-sender-identifier $SENDER_ID --bag-group-identifier $GROUP_ID"

# create the directory we will be bagging
mkdir $BAG_NAME > /dev/null 2>&1
exit_on_error $? "cannot create the working directory $BAG_NAME"

# copy the source files
cp -R $INPUT_DIR/* $BAG_NAME
exit_on_error $? "copying source files"

$PYTHON_TOOL -m bagit $BAGIT_OPTS $BAG_NAME
exit_on_error $? "during bagging"

# create the aptrust-info.txt file
INFO_FILE=${BAG_NAME}/aptrust-info.txt
WORK_FILE=${BAG_NAME}/data/work.json
ensure_file_exists $WORK_FILE
TITLE=$($JQ_TOOL ".title[0]" $WORK_FILE)
DESCRIPTION=$($JQ_TOOL ".description" $WORK_FILE)
echo "Title: ${TITLE}" >> $INFO_FILE
echo "Description: ${DESCRIPTION}" >> $INFO_FILE
echo "Access: Consortia" >> $INFO_FILE
echo "Storage: Standard" >> $INFO_FILE

# run the bagging tool
# bundle up the bagged directory
$TAR_TOOL cvf ${BAG_NAME}.tar $BAG_NAME > /dev/null 2>&1
exit_on_error $? "during tar"

# cleanup
rm -fr $BAG_NAME > /dev/null 2>&1

# its all over
exit 0

#
# end of file
#
