#!/usr/bin/env bash
#
# A helper to create a set of bags from a set of directories
#

#set -x

# source common helpers
SCRIPT_DIR=$( (cd -P $(dirname $0) && pwd) )
. $SCRIPT_DIR/common.ksh

function show_use_and_exit {
   error_and_exit "use: $(basename $0) <input directory> <output directory> <LibraETD|LibraOpen>"
}

# ensure correct usage
if [ $# -lt 3 ]; then
   show_use_and_exit
fi

# input parameters for clarity
INPUT_DIR=$1
shift
OUTPUT_DIR=$1
shift
BAG_TYPE=$1
shift

# validate the bag type parameter
case $BAG_TYPE in
   LibraETD|LibraOpen)
   ;;
   *) echo "ERROR: specify LibraETD or LibraOpen, aborting"
   exit 1
   ;;
esac

# bagger tool
BAGGER=$SCRIPT_DIR/bag-dir.ksh
ensure_file_exists $BAGGER

# check the input and output directories exists
ensure_dir_exists $INPUT_DIR
ensure_dir_exists $OUTPUT_DIR

# local definitions
TMPFILE=/tmp/bag-all.$$

# find all the files of a specified pattern
find $INPUT_DIR -type d -name export-\* | grep "export-" > $TMPFILE

# track our progress
SUCCESS_COUNT=0
ERROR_COUNT=0

# for all the directories we located
for i in $(<$TMPFILE); do
   BAG_DIR=$(basename $i)

   ID=${BAG_DIR#export-}
   echo -n "bagging $BAG_DIR... "

   # do the bagging
   BAG_NAME=${BAG_TYPE}-${ID}
   $BAGGER $INPUT_DIR/$BAG_DIR $BAG_NAME $ID $BAG_TYPE
   if [ $? -eq 0 ]; then
      mv ${BAG_NAME}.tar $OUTPUT_DIR
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
