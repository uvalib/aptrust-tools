#!/usr/bin/env bash
#
# A helper to check the APTrust status of a specified bag
#

#set -x

# source common helpers
SCRIPT_DIR=$( (cd -P $(dirname $0) && pwd) )
. $SCRIPT_DIR/common.ksh

function show_use_and_exit {
   error_and_exit "use: $(basename $0) <bag file>"
}

# ensure correct usage
if [ $# -lt 1 ]; then
   show_use_and_exit
fi

# input parameters for clarity
BAG_FILE=$1
shift

# ensure we have the tools available
CURL_TOOL=curl
ensure_tool_available $CURL_TOOL
JQ_TOOL=jq
ensure_tool_available $JQ_TOOL

# ensure we have the environment config we need
ensure_var_defined "$aptrust_api_url" "aptrust_api_url"
ensure_var_defined "$aptrust_user" "aptrust_user"
ensure_var_defined "$aptrust_key" "aptrust_key"

# check the bag etag file exists
ensure_file_exists ${BAG_FILE}.etag

# get the etag
ETAG=$(cat ${BAG_FILE}.etag)
if [ -z "$ETAG" ]; then
   exit_on_error 1 "undefined etag for ${BAG_FILE}"
fi

# local definitions
TMPFILE=/tmp/status-bag.$$
CURL_DEFAULTS="--fail -s -S"

# issue the query
API=${aptrust_api_url}/items?etag=${ETAG}
$CURL_TOOL $CURL_DEFAULTS -H "Accept: application/json" -H "X-Pharos-API-User: ${aptrust_user}" -H "X-Pharos-API-Key: ${aptrust_key}" $API > $TMPFILE
exit_on_error $? "querying $API"

# see if we have any results
COUNT=$($JQ_TOOL ".count" $TMPFILE)
if [ "$COUNT" == "0" ]; then
   STATUS="unknown"
else
   STATUS=$($JQ_TOOL ".results[0].status" $TMPFILE | tr -d "\"")
fi

# output the status
echo $STATUS

# cleanup
rm -fr $TMPFILE > /dev/null 2>&1

# all over
exit 0

#
# end of file
#
