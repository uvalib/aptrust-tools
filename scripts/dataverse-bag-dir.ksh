#!/usr/bin/env bash
#
# A helper to create a bag from the specified directory
#

#set -x

# source common helpers
SCRIPT_DIR=$( (cd -P $(dirname $0) && pwd) )
. $SCRIPT_DIR/common.ksh

function show_use_and_exit {
   error_and_exit "use: $(basename $0) <input directory> <bag name>"
}

# ensure correct usage
if [ $# -lt 2 ]; then
   show_use_and_exit
fi

# input parameters for clarity
INPUT_DIR=$1
shift
BAG_NAME=$1
shift

# ensure we have the tools available
JQ_TOOL=jq
ensure_tool_available $JQ_TOOL
TAR_TOOL=tar
ensure_tool_available $TAR_TOOL

# check the input directory exists
ensure_dir_exists $INPUT_DIR

# local definitions
OUTPUT_FILE=${BAG_NAME}.tar

# create the directory we will be bagging
mkdir $BAG_NAME > /dev/null 2>&1
exit_on_error $? "cannot create the working directory $BAG_NAME"

# copy the source files
cp -R $INPUT_DIR/* $BAG_NAME
exit_on_error $? "copying source files"

# create the aptrust-info.txt file
INFO_FILE=${BAG_NAME}/aptrust-info.txt
WORK_FILE=${BAG_NAME}/metadata/oai-ore.jsonld
ensure_file_exists $WORK_FILE
TITLE=$($JQ_TOOL '."ore:describes".Title' $WORK_FILE)
DESCRIPTION=$($JQ_TOOL '."ore:describes"."citation:Dataset Description"."dsDescription:Text"' $WORK_FILE)

if [ -z "$TITLE" ]; then
   echo "ERROR: title is blank"
   exit 1
fi
if [ -z "$DESCRIPTION" ]; then
   echo "ERROR: description is blank"
   exit 1
fi

echo "Title: ${TITLE}" >> $INFO_FILE
echo "Description: ${DESCRIPTION}" >> $INFO_FILE
echo "Access: Consortia" >> $INFO_FILE
echo "Storage: Standard" >> $INFO_FILE

# create an empty manifest if one does not exist
MANIFEST=${BAG_NAME}/manifest-md5.txt
if [ ! -f ${MANIFEST} ]; then
   touch ${MANIFEST}
   exit_on_error $? "creating empty manifest"
fi

# bundle up the directory
$TAR_TOOL cvf ${OUTPUT_FILE} $BAG_NAME > /dev/null 2>&1
exit_on_error $? "during tar"

# cleanup
rm -fr $BAG_NAME > /dev/null 2>&1

# its all over
exit 0

#
# end of file
#
