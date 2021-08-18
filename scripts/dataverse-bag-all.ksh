#!/usr/bin/env bash
#
# A helper to create a set of dataverse specific bags from a set of directories
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

# default values
BAG_TYPE=DataVerse

# bagger tool
BAGGER=$SCRIPT_DIR/dataverse-bag-dir.ksh
ensure_file_exists $BAGGER

# check the input and output directories exists
ensure_dir_exists $INPUT_DIR
ensure_dir_exists $OUTPUT_DIR

# local definitions
TMPFILE=/tmp/dataverse-bag-all.$$

# find all the files of a specified pattern
find $INPUT_DIR -type d -name doi-\* | grep "doi-" > $TMPFILE

# track our progress
SUCCESS_COUNT=0
ERROR_COUNT=0

# for all the directories we located
for i in $(<$TMPFILE); do
   BAG_DIR=$(basename $i)

   #ID=${BAG_DIR#export-}
   ID=$BAG_DIR
   echo -n "bagging $BAG_DIR... "

   # do the bagging
   BAG_NAME=${BAG_TYPE}-${ID}
   #$BAGGER $INPUT_DIR/$BAG_DIR $BAG_NAME $ID x y
   if [ $? -eq 0 ]; then
      #mv ${BAG_NAME}.tar $OUTPUT_DIR
      if [ $? -eq 0 ]; then
         echo "OK"
         ((SUCCESS_COUNT=SUCCESS_COUNT+1))
      else
         echo "ERROR: moving bag file"
         ((ERROR_COUNT=ERROR_COUNT+1))
      fi
   else
      # we get an error message from the bagging helper
      echo ""
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
