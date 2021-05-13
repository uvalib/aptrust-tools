#!/usr/bin/env bash
#
# A helper to check the APTrust status of a specified bag
#

#set -x

# source common helpers
SCRIPT_DIR=$( (cd -P $(dirname $0) && pwd) )
. $SCRIPT_DIR/common.ksh

function show_use_and_exit {
   error_and_exit "use: $(basename $0) <bag file> <environment>"
}

# ensure correct usage
if [ $# -lt 2 ]; then
   show_use_and_exit
fi

# input parameters for clarity
BAG_FILE=$1
shift
ENVIRONMENT=$1
shift

# validate the environment parameter
case $ENVIRONMENT in
   test)
   CONFIG_FILE=$SCRIPT_DIR/../tmp/config/ap-trust-test.config
   ;;
   production)
   CONFIG_FILE=$SCRIPT_DIR/../tmp/config/ap-trust-production.config
   ;;
   *) echo "ERROR: specify test or production, aborting"
   exit 1
   ;;
esac

# ensure we have the tools available
CURL_TOOL=curl
ensure_tool_available $CURL_TOOL
JQ_TOOL=jq
ensure_tool_available $JQ_TOOL

# check the config file exists
ensure_file_exists $CONFIG_FILE

# get the needed configuration
aptrust_api_url=$(extract_nv_from_file $CONFIG_FILE aptrust_api_url)
aptrust_user=$(extract_nv_from_file $CONFIG_FILE aptrust_user)
aptrust_key=$(extract_nv_from_file $CONFIG_FILE aptrust_key)

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
COUNT=$(cat $TMPFILE | $JQ_TOOL ".count")
if [ "$COUNT" == "0" ]; then
   STATUS="unknown"
else
   STATUS=$(cat $TMPFILE | $JQ_TOOL ".results[0].status")
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
