# _isInstalled {package}
_isInstalled() {
    package="$1"
    if [ -z "$package" ]; then
        echo 1
        return
    fi
    
    check="$(sudo pacman -Qs --color always "${package}" 2>/dev/null | grep "local" | grep "${package} ")"
    if [ -n "${check}" ]; then
        echo 0
    else
        echo 1
    fi
}

# _installPackage {package}
_installPackage() {
    package="$1"
    testcommand="$2"
    install_type="$3"
    
    if [ -z "$package" ]; then
        _echo_error "Package name cannot be empty"
        return 1
    fi
    
	if [[ $(_isInstalled "${package}") == 0 ]]; then
		_echo_success "${package} ${pkginst_lang["package_already_installed"]}"
        return 0
    fi
    
    _echo_success "${pkginst_lang["install_package"]} ${package} with pacman"
    
    # Install package with retry mechanism
    install_cmd="sudo pacman -S --needed --noconfirm \"${package}\""
    if [[ "$debug" == 0 ]]; then
        if ! _execute_with_retry "$install_cmd" 2 "pacman install $package"; then
            _echo_error "Failed to install package: $package"
            return 1
        fi
    else
        if ! _execute_with_retry "$install_cmd &>>$(_getLogFile)" 2 "pacman install $package"; then
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

# _installPackageAur {package}
_installPackageAur() {
    package="$1"
    testcommand="$2"
    
    if [ -z "$package" ]; then
        _echo_error "Package name cannot be empty"
        return 1
    fi
    
    # Check if AUR helper is available
    if [ $(_checkCommandExists "$aur_helper") == 1 ]; then
        _echo_error "AUR helper '$aur_helper' is not available"
        return 1
    fi
    
	if [[ $(_isInstalled "${package}") == 0 ]]; then
		_echo_success "${package} ${pkginst_lang["package_already_installed"]}"
        return 0
    fi
    
	_echo_success "${pkginst_lang["install_package"]} ${package} with ${aur_helper}"
    
    # Install AUR package with retry mechanism
    install_cmd="${aur_helper} -S --noconfirm \"${package}\""
    if [[ "$debug" == 0 ]]; then
        if ! _execute_with_retry "$install_cmd" 2 "AUR install $package"; then
            _echo_error "Failed to install AUR package: $package"
            return 1
        fi
    else
        if ! _execute_with_retry "$install_cmd &>>$(_getLogFile)" 2 "AUR install $package"; then
            _echo_error "Failed to install AUR package: $package"
            return 1
        fi
    fi
    
    # Verify installation
    if [[ $(_isInstalled "${package}") == 1 ]]; then
        _echo_error "AUR package installation appears to have failed: $package"
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

# _installYay
_installYay() {
    _echo "Installing yay AUR helper..."
    
    # Check if already installed
    if [ $(_checkCommandExists "yay") == 0 ]; then
        _echo_success "yay is already installed"
        return 0
    fi
    
    # Install base-devel if needed
    if ! _installPackage "base-devel"; then
        _echo_error "Failed to install base-devel required for yay"
        return 1
    fi
    
    # Check if git is available
    if [ $(_checkCommandExists "git") == 1 ]; then
        _echo_error "git is required to install yay"
        return 1
    fi
    
    SCRIPT=$(realpath "$0")
    temp_path=$(dirname "$SCRIPT")
    yay_build_dir="$pkginst_download_folder/yay"
    
    # Clean up any previous build
    if [ -d "$yay_build_dir" ]; then
        rm -rf "$yay_build_dir" 2>/dev/null
    fi
    
    # Clone and build yay
    if ! git clone https://aur.archlinux.org/yay.git "$yay_build_dir" 2>/dev/null; then
        _echo_error "Failed to clone yay repository"
        return 1
    fi
    
    if ! cd "$yay_build_dir" 2>/dev/null; then
        _echo_error "Failed to change to yay build directory"
        return 1
    fi
    
    if ! makepkg -si --noconfirm 2>/dev/null; then
        cd "$temp_path"
        _echo_error "Failed to build and install yay"
        return 1
    fi
    
    cd "$temp_path"
    
    # Verify installation
    if [ $(_checkCommandExists "yay") == 1 ]; then
        _echo_error "yay installation failed"
        return 1
    fi
    
    _echo_success "${pkginst_lang["yay_installed"]}"
    return 0
}

# _installParu
_installParu() {
    _echo "Installing paru AUR helper..."
    
    # Check if already installed
    if [ $(_checkCommandExists "paru") == 0 ]; then
        _echo_success "paru is already installed"
        return 0
    fi
    
    # Install base-devel if needed
    if ! _installPackage "base-devel"; then
        _echo_error "Failed to install base-devel required for paru"
        return 1
    fi
    
    # Check if git is available
    if [ $(_checkCommandExists "git") == 1 ]; then
        _echo_error "git is required to install paru"
        return 1
    fi
    
    SCRIPT=$(realpath "$0")
    temp_path=$(dirname "$SCRIPT")
    paru_build_dir="$pkginst_download_folder/paru"
    
    # Clean up any previous build
    if [ -d "$paru_build_dir" ]; then
        rm -rf "$paru_build_dir" 2>/dev/null
    fi
    
    # Clone and build paru
    if ! git clone https://aur.archlinux.org/paru.git "$paru_build_dir" 2>/dev/null; then
        _echo_error "Failed to clone paru repository"
        return 1
    fi
    
    if ! cd "$paru_build_dir" 2>/dev/null; then
        _echo_error "Failed to change to paru build directory"
        return 1
    fi
    
    if ! makepkg -si --noconfirm 2>/dev/null; then
        cd "$temp_path"
        _echo_error "Failed to build and install paru"
        return 1
    fi
    
    cd "$temp_path"
    
    # Verify installation
    if [ $(_checkCommandExists "paru") == 1 ]; then
        _echo_error "paru installation failed"
        return 1
    fi
    
    _echo_success "${pkginst_lang["paru_installed"]}"
    return 0
}
