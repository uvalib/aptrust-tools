#!/usr/bin/env bash
#
# A helper to create a bag from the specified DataVerse export directory
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
GROUP_ID=$1
shift
OUTPUT_FILE=$1
shift

# ensure we have the tools available
JQ_TOOL=jq
ensure_tool_available ${JQ_TOOL}
TAR_TOOL=tar
ensure_tool_available ${TAR_TOOL}
MD5_TOOL=md5sum
ensure_tool_available ${MD5_TOOL}

# check the input directory exists
ensure_dir_exists $INPUT_DIR

# define TMP if not done already
TMP=${TMP:-/tmp}

# local definitions
BAG_DIR=${TMP}/${BAG_NAME}

# create the directory we will be bagging
rm -fr ${BAG_DIR} > /dev/null 2>&1
mkdir ${BAG_DIR} > /dev/null 2>&1
exit_on_error $? "cannot create the working directory ${BAG_DIR}"

# copy the source files
cp -R $INPUT_DIR/* ${BAG_DIR}
exit_on_error $? "copying source files"

# create the aptrust-info.txt file
BAG_INFO_FILE=${BAG_DIR}/bag-info.txt
APT_INFO_FILE=${BAG_DIR}/aptrust-info.txt
WORK_FILE=${BAG_DIR}/metadata/oai-ore.jsonld
ensure_file_exists $WORK_FILE
TITLE=$(${JQ_TOOL} '."ore:describes"."title" // empty' $WORK_FILE 2>/dev/null)
DESCRIPTION=$(${JQ_TOOL} '."ore:describes"."citation:dsDescription"."citation:dsDescriptionValue" // empty' $WORK_FILE 2>/dev/null)
if [ -z "$DESCRIPTION" ]; then
   DESCRIPTION=$(${JQ_TOOL} '."ore:describes"."citation:dsDescription".[0]."citation:dsDescriptionValue" // empty' $WORK_FILE 2>/dev/null)
fi

if [ -z "$TITLE" ]; then
   echo "ERROR: title is blank"
   exit 1
fi
if [ -z "$DESCRIPTION" ]; then
   echo "ERROR: description is blank"
   exit 1
fi

echo "Title: ${TITLE}" >> $APT_INFO_FILE
echo "Description: ${DESCRIPTION}" >> $APT_INFO_FILE
echo "Access: Consortia" >> $APT_INFO_FILE
echo "Storage: Standard" >> $APT_INFO_FILE

# various possible manifests
MANIFEST_MD5_FILENAME=manifest-md5.txt
MANIFEST_MD5=${BAG_DIR}/${MANIFEST_MD5_FILENAME}
MANIFEST_SHA1=${BAG_DIR}/manifest-sha1.txt

# create an empty manifest if one does not exist
if [ ! -f ${MANIFEST_MD5} ]; then
   if [ -f ${MANIFEST_SHA1} ]; then
      TMPFILE=${TMP}/manifest.$$
      echo -n "creating ${MANIFEST_MD5_FILENAME} "
      cat ${MANIFEST_SHA1} | cut -c 42- > ${TMPFILE}
      while read -r line; do
         # cos embedded windoze CR characters
         line=$(echo ${line} | tr -d '\r')
         sum=$(${MD5_TOOL} "${BAG_DIR}/${line}" | awk '{print $1}')
         # seen an error here
         if [ -z "${sum}" ]; then
            exit_on_error 1 "creating md5 for ${line}"
         fi

         echo "${sum} ${line}" >> ${MANIFEST_MD5}
      done < ${TMPFILE}
   else
      echo -n "creating empty ${MANIFEST_MD5_FILENAME} "
      touch ${MANIFEST_MD5}
      exit_on_error $? "creating empty ${MANIFEST_MD5_FILENAME}"
   fi
fi

# special case for Dataverse bags, add the group identifier
echo "Bag-Group-Identifier: ${GROUP_ID}" >> $BAG_INFO_FILE

# bundle up the directory
cd ${TMP}
${TAR_TOOL} cvf ${OUTPUT_FILE} ${BAG_NAME} > /dev/null 2>&1
exit_on_error $? "during tar"

# cleanup
rm -fr ${BAG_NAME} > /dev/null 2>&1

# its all over
exit 0

#
# end of file
#
