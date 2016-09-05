#!/usr/bin/env bash

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
	local commands='rm cd'
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

usage_help() {
	cat <<EOL
	Usage: $0 [OPTIONS...]

Options:
  -v, --version              Show script version
  -h, --help                 Show this help message
  -d, --debug                Run script in debug mode

EOL
}

print_version() {
	cat <<EOL
	teamcity-backup.sh ${VERSION} by Yancharuk Alexander

EOL
}

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
