#!/usr/bin/env bash
#
# A helper to unbag the dataverse specific bags in preparation to have them bagged for APTrust
#

#set -x

# source common helpers
SCRIPT_DIR=$( (cd -P $(dirname $0) && pwd) )
. $SCRIPT_DIR/common.ksh

function show_use_and_exit {
   error_and_exit "use: $(basename $0) <input directory> <output directory>"
}

# ensure correct usage
if [ $# -lt 2 ]; then
   show_use_and_exit
fi

# input parameters for clarity
INPUT_DIR=$1
shift
OUTPUT_DIR=$1
shift

# unbagger tool
UNBAGGER=unzip
ensure_tool_available $UNBAGGER

# check the input and output directories exists
ensure_dir_exists $INPUT_DIR
ensure_dir_exists $OUTPUT_DIR

# define TMP if not done already
TMP=${TMP:-/tmp}

# local definitions
TMPFILE=${TMP}/dataverse-unbag-all.$$
TMPDIR=${TMP}/unbag.$$

# find all the files of a specified pattern
find $INPUT_DIR -type f -name doi-\*.zip | grep "doi-" > $TMPFILE

# track our progress
SUCCESS_COUNT=0
ERROR_COUNT=0

# for all the files we located
for i in $(<$TMPFILE); do
   BAG_FILE=$(basename $i)
   ID=${BAG_FILE%.zip}

   echo -n "unbagging $BAG_FILE... "

   # create clean working directory
   rm -fr $TMPDIR > /dev/null 2>&1
   mkdir $TMPDIR

   # do the unbagging
   $UNBAGGER -qq $INPUT_DIR/$BAG_FILE -d $TMPDIR
   if [ $? -ne 0 ]; then
      echo "ERROR: unbagging file"
      ((ERROR_COUNT=ERROR_COUNT+1))
      continue
   fi

   # determine the bag output directory name (cos it does not match the bag filename)
   OUT_DIR=$(ls $TMPDIR | grep doi\-)

   # ensure the output directory does not already exist
   if [ -d $OUTPUT_DIR/$OUT_DIR ]; then
      echo "ERROR: unbag directory already exists"
      ((ERROR_COUNT=ERROR_COUNT+1))
      continue
   fi

   # move the unbagged directory to the correct location
   mv $TMPDIR/$OUT_DIR $OUTPUT_DIR
   if [ $? -eq 0 ]; then
      echo "OK"
      ((SUCCESS_COUNT=SUCCESS_COUNT+1))
   else
      echo "ERROR: moving unbagged directory"
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
