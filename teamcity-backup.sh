#!/usr/bin/env bash

# ---------------------------------------------------------------------
# Script for TeamCity backup
#
# Designed for running by cron
# ---------------------------------------------------------------------

readonly VERSION='1.0.0'
readonly TC_INSTALL_DIR=/var/www/TeamCity
readonly TC_BACKUP_DIR=/var/www/.BuildServer/backup
readonly TC_BACKUP_FILE_NAME=teamcity_backup
# If you don't want prev backups cleanup, comment next line
readonly PREVIOUS_BACKUPS_CLEANUP=1

export TEAMCITY_APP_DIR="${TC_INSTALL_DIR}/webapps/ROOT"
export JAVA_HOME=$(readlink -f /usr/bin/java | sed "s:jre/bin/java::")
export JRE_HOME=$(readlink -f /usr/bin/java | sed "s:bin/java::")

# Function for error messages
error() {
	printf "[$(date --rfc-3339=seconds)]: \033[0;31mERROR:\033[0m $@\n" >&2
}

# Function for debug messages
debug() {
	[ ! -z ${DEBUG} ] && printf "[$(date --rfc-3339=seconds)]: \033[0;32mDEBUG:\033[0m $@\n"
}

# Function for warning messages
warning() {
	printf "[$(date --rfc-3339=seconds)]: \033[0;33mWARNING:\033[0m $@\n" >&2
}

# Function for checking inner dependencies
check_dependencies() {
	local commands='bash rm cd'
	local result=0
	local script_path=${TC_INSTALL_DIR}/bin/maintainDB.sh

	for i in ${commands}; do
		command -v ${i} >/dev/null 2>&1
		if [ $? -eq 0 ]; then
			debug "Check $i ... OK"
		else
			warning "$i command not available"
			result=1
		fi
	done

	if [ -x ${script_path} ]; then
		debug "Check $script_path ... OK"
	else
		warning "${script_path} script not available"
		result=1
	fi

	return ${result}
}

# Function for help
usage_help() {
	cat <<EOL
	Usage: $0 [OPTIONS...]

Options:
  -v, --version              Show script version
  -h, --help                 Show this help message
  -d, --debug                Run script in debug mode

EOL
}

# Function for version printing
print_version() {
	cat <<EOL
	teamcity-backup.sh ${VERSION} by Yancharuk Alexander

EOL
}

# Function for parsing command line options
parse_options() {
	local result=0

	while getopts :vhd-: param; do
	[ ${param} == '?' ] && found=${OPTARG} || found=${param}

	debug "Found option '$found'"

	case ${param} in
		v ) print_version; exit 0;;
		h ) usage_help; exit 0;;
		d ) DEBUG=1;;
		- ) case $OPTARG in
				version ) print_version; exit 0;;
				help    ) usage_help; exit 0;;
				debug   ) DEBUG=1;;
				*       ) warning "Illegal option --$OPTARG"; result=2;;
			esac;;
		* ) warning "Illegal option -$OPTARG"; result=2;;
	esac
	done
	shift $((OPTIND-1))

	return ${result}
}

# Function for previous backups cleanup
backups_cleanup() {
	local result=0

	if [ ! -x ${TC_BACKUP_DIR} ]; then
		debug "$TC_BACKUP_DIR not found. Trying to create"
		command mkdir -p ${TC_BACKUP_DIR}
		if [ $? -eq 0 ] && [ -x ${TC_BACKUP_DIR} ]; then
			debug 'Success';
		else
			error "$TC_BACKUP_DIR creation failure"; exit 1
		fi
	fi

	if [ -z ${DEBUG} ]; then
		local rm_flag=''
	else
		local rm_flag='-v'
	fi

	debug 'Remove all previous backups'
	rm ${rm_flag} ${TC_BACKUP_DIR}/*

	if [ $? -eq 0 ]; then
		debug "Previous backups cleanup ... OK"
	else
		warning "Previous backups cleanup ... FAIL"
		result=1
	fi

	return ${result}
}

parse_options "$@" || exit $?
check_dependencies  || exit $?

[ -z ${PREVIOUS_BACKUPS_CLEANUP} ] || backups_cleanup

debug 'Open TeamCity binary dir'
cd ${TC_INSTALL_DIR}/bin

debug 'Run TeamCity backup utility'
. ${TC_INSTALL_DIR}/bin/maintainDB.sh backup -C -D -L -P -U -F ${TC_BACKUP_FILE_NAME}
