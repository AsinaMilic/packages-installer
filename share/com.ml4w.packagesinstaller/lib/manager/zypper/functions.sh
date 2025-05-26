# _isInstalled {package}
_isInstalled() {
    package="$1"
    if [ -z "$package" ]; then
        echo 1
        return
    fi
    
    package_info=$(zypper se -i "$package" 2>/dev/null | grep "^i" | awk '{print $3}')
    ret=1
    for pkg in $package_info
    do
	if [ "$package" == "$pkg" ]; then
		ret=0
		break
	fi
	done
	echo $ret
}

# _installPackage {package}
_installPackage() {
    package="$1"
	testcommand="$2"
    
    if [ -z "$package" ]; then
        _echo_error "Package name cannot be empty"
        return 1
    fi
    
	if [[ $(_isInstalled "${package}") == 0 ]]; then
		_echo_success "${package} ${pkginst_lang["package_already_installed"]}"
        return 0
    fi
    
	_echo_success "${pkginst_lang["install_package"]} ${package} with zypper"
    
    # Install package with retry mechanism
    install_cmd="sudo zypper -n install \"${package}\""
    if [[ "$debug" == 0 ]]; then
        if ! _execute_with_retry "$install_cmd" 2 "zypper install $package"; then
            _echo_error "Failed to install package: $package"
            return 1
        fi
    else
        if ! _execute_with_retry "$install_cmd &>>$(_getLogFile)" 2 "zypper install $package"; then
            _echo_error "Failed to install package: $package"
            return 1
        fi
    fi
    
    # Verify installation
    if [[ $(_isInstalled "${package}") == 1 ]]; then
        _echo_error "Package installation appears to have failed: $package"
        return 1
    fi
    
    # Test command if provided
    if [ ! -z "$testcommand" ] && [ "$testcommand" != "null" ]; then
        if [ $(_checkCommandExists "$testcommand") == 1 ]; then
            _echo_error "$testcommand ${pkginst_lang["command_check_failed"]}"
            pkginst_commanderrors+=($testcommand)
            return 1
        fi
    fi
    
    return 0
}
