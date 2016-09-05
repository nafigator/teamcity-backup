#!/usr/bin/env bash

# ---------------------------------------------------------------------
# Script for TeamCity backup
#
# Designed for running by cron
# ---------------------------------------------------------------------

readonly VERSION='0.0.2'
readonly TC_INSTALL_DIR=/var/www/TeamCity
readonly TC_BACKUP_DIR=/var/www/.BuildServer/backup
readonly TC_BACKUP_FILE_NAME=teamcity_backup
# If you don't want prev backups cleanup, comment next line
readonly PREVIOUS_BACKUPS_CLEANUP=1

export TEAMCITY_APP_DIR="${TC_INSTALL_DIR}/webapps/ROOT"
export JAVA_HOME=$(readlink -f /usr/bin/java | sed "s:jre/bin/java::")
export JRE_HOME=$(readlink -f /usr/bin/java | sed "s:bin/java::")

. $(dirname $0)/functions.sh

parse_options "$@" || exit $?
check_dependencies  || exit $?

[ -z ${PREVIOUS_BACKUPS_CLEANUP} ] || backups_cleanup

debug 'Open TeamCity binary dir'
cd ${TC_INSTALL_DIR}/bin

debug 'Run TeamCity backup utility'
. ${TC_INSTALL_DIR}/bin/maintainDB.sh backup -C -D -L -P -U -F ${TC_BACKUP_FILE_NAME}
