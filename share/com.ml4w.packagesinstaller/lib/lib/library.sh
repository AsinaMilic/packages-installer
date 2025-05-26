# _echo {output}
_echo() {
    output="$1"
    echo "${echo_prefix}${output}"
}

# _echo_error {output}
_echo_error() {
    output="$1"
    echo "${echo_prefix_error}${output}" >&2
}

# _echo_success {output}
_echo_success() {
    output="$1"
    printf '\u2714\ufe0e' 
    echo " ${output}"
}

# _echo_warning {output}
_echo_warning() {
    output="$1"
    echo "${echo_prefix_warning}${output}" >&2
}

# _exit_with_error {message} {exit_code}
_exit_with_error() {
    message="$1"
    exit_code="${2:-1}"
    _echo_error "$message"
    _cleanup_on_error
    exit "$exit_code"
}

# _cleanup_on_error
_cleanup_on_error() {
    # Clean up temporary files and partial downloads
    if [ -f "$HOME/.cache/pkginst_tmp.zip" ]; then
        rm -f "$HOME/.cache/pkginst_tmp.zip" 2>/dev/null
    fi
    if [ -d "$HOME/.cache/pkginst_tmp" ]; then
        rm -rf "$HOME/.cache/pkginst_tmp" 2>/dev/null
    fi
}

# _execute_with_retry {command} {max_retries} {description}
_execute_with_retry() {
    command="$1"
    max_retries="${2:-3}"
    description="$3"
    
    for i in $(seq 1 $max_retries); do
        if eval "$command"; then
            return 0
        else
            if [ $i -lt $max_retries ]; then
                _echo_warning "Attempt $i failed for: $description. Retrying..."
                sleep 2
            else
                _echo_error "All $max_retries attempts failed for: $description"
                return 1
            fi
        fi
    done
}

# _validate_file {file_path} {description}
_validate_file() {
    file_path="$1"
    description="$2"
    
    if [ -z "$file_path" ]; then
        _echo_error "File path cannot be empty for validation: $description"
        return 1
    fi
    
    if [ ! -f "$file_path" ]; then
        _echo_error "File does not exist: $file_path ($description)"
        return 1
    fi
    
    if [ ! -r "$file_path" ]; then
        _echo_error "File is not readable: $file_path ($description)"
        return 1
    fi
    
    return 0
}

# _sourceFilesInFolder {folder}
_sourceFilesInFolder() {
    folder="$1"
    if [ -d "$folder" ]; then
        if [ -r "$folder" ]; then
            for f in "$folder"/*; do 
                if [ -f "$f" ] && [ -r "$f" ]; then
                    source "$f"
                else
                    _echo_warning "Cannot source file: $f (not readable)"
                fi
            done
        else
            _echo_warning "Cannot read directory: $folder"
        fi
    fi
}

# _sourceFile {file}
_sourceFile() {
    file="$1"
    if [ -f "$file" ]; then
        if [ -r "$file" ]; then
            source "$file"
        else
            _echo_warning "Cannot source file: $file (not readable)"
        fi
    fi
}

# _checkCommandExists {command}
_checkCommandExists() {
    cmd="$1"
    if [ -z "$cmd" ]; then
        echo 1
        return
    fi
    
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo 1
    else
        echo 0
    fi
}

# _installPip {package}
_installPip() {
    package="$1"
    if [ -z "$package" ]; then
        _echo_error "Package name cannot be empty for pip installation"
        return 1
    fi
    
    _echo_success "${pkginst_lang["install_package"]} ${package} with pip"
    
    install_cmd="pip install -y \"${package}\""
    if [[ "$debug" == 0 ]]; then
        if ! _execute_with_retry "$install_cmd" 2 "pip install $package"; then
            _echo_error "Failed to install $package with pip"
            return 1
        fi
    else
        if ! _execute_with_retry "$install_cmd &>>$(_getLogFile)" 2 "pip install $package"; then
            _echo_error "Failed to install $package with pip"
            return 1
        fi
    fi
}

# _installCargo {package}
_installCargo() {
    package="$1"
    if [ -z "$package" ]; then
        _echo_error "Package name cannot be empty for cargo installation"
        return 1
    fi
    
    _echo_success "${pkginst_lang["install_package"]} ${package} with cargo"
    
    install_cmd="cargo install \"${package}\""
    if [[ "$debug" == 0 ]]; then
        if ! _execute_with_retry "$install_cmd" 2 "cargo install $package"; then
            _echo_error "Failed to install $package with cargo"
            return 1
        fi
    else
        if ! _execute_with_retry "$install_cmd &>>$(_getLogFile)" 2 "cargo install $package"; then
            _echo_error "Failed to install $package with cargo"
            return 1
        fi
    fi
}

# _verify_system_state
_verify_system_state() {
    # Skip verification for help and info commands
    if [ "$HELP" = true ] || [ "$INSTALLED" = true ]; then
        return 0
    fi
    
    _echo "Verifying system state..."
    
    # Check disk space
    available_space=$(df "$HOME" | awk 'NR==2 {print $4}')
    if [ "$available_space" -lt 1048576 ]; then  # Less than 1GB
        _echo_warning "Low disk space detected (less than 1GB available)"
    fi
    
    _echo_success "System state verification completed"
}

# Define log file extension
_getLogFile() {
    log_filename="log.txt"
    log_path="$pkginst_log_folder/$pkginst_package/$pkginst_log_file-$log_filename"
    
    # Ensure log directory exists
    log_dir=$(dirname "$log_path")
    if [ ! -d "$log_dir" ]; then
        mkdir -p "$log_dir" 2>/dev/null || {
            _echo_warning "Cannot create log directory: $log_dir"
            echo "/tmp/pkginst-fallback.log"
            return
        }
    fi
    
    echo "$log_path"
}

# _getConfiguration {conf_key}
_getConfiguration() {
    conf_key="$1"
    if [[ $(jq -r .$conf_key $pkginst_data_folder/config.json) != "null" ]]; then
        echo $(jq -r .$conf_key $pkginst_data_folder/config.json)
    else
        echo ""
    fi
}

# _writeModuleHeadline {headline}
_writeModuleHeadline() {
    headline="$1"
    if [ -f "$pkginst_data_folder/templates/moduleheader.sh" ]; then
        source "$pkginst_data_folder/templates/moduleheader.sh"
    else
        source "$pkginst_script_folder/templates/moduleheader.sh"
    fi    
}

# _showAllPackages
_showAllPackages() {
    _echo "${pkginst_lang["show_all_packages_message"]}"
    echo
    _echo "Dependencies ($(jq -r '.packages | length' $pkginst_script_dependencies/packages.json)):"
    for pkg in $(jq -r '.packages[] | .package' $pkginst_script_dependencies/packages.json); do
        _echo_success ${pkg}
    done
    echo    
    _echo "Packages ($(jq -r '.packages | length' $pkginst_data_folder/packages.json)):"
    for pkg in $(jq -r '.packages[] | .package' $pkginst_data_folder/packages.json); do
        _echo_success ${pkg}
    done    
    echo
}

# _installPackages {json_file}
_installPackages() {
    json_file="$1"
    for row in $(jq -c '.packages[]' "$json_file"); do
        pkg=$(echo "$row" | jq -r '.package')
        if [[ "$pkg" != "null" ]]; then
            _installPkg "$row"
        fi
    done    
}

# _installPkg {row} - simplified version
_installPkg() {
    row="$1"
    pkg=$(echo "$row" | jq -r '.package')
    pkg_aur=$(echo "$row" | jq -r '.aur')
    pkg_fedoracopr=$(echo "$row" | jq -r '.fedoracopr')
    pkg_pacman=$(echo "$row" | jq -r '.pacman')
    pkg_zypper=$(echo "$row" | jq -r '.zypper')
    pkg_dnf=$(echo "$row" | jq -r '.dnf')
    pkg_apt=$(echo "$row" | jq -r '.apt')
    pkg_test=$(echo "$row" | jq -r '.test')
    pkg_pip=$(echo "$row" | jq -r '.pip')
    pkg_cargo=$(echo "$row" | jq -r '.cargo')
    pkg_flatpak=$(echo "$row" | jq -r '.flatpak')

    if [ -f "$pkginst_data_folder/$pkginst_manager/$pkg" ]; then
        source "$pkginst_data_folder/$pkginst_manager/$pkg"
    elif [[ ! "$pkg_flatpak" == "null" ]]; then
        _installFlatpakFlathub "$pkg_flatpak"
    elif [[ ! "$pkg_pip" == "null" && ! "$pkginst_manager" == "pacman" ]]; then
        _installPip "$pkg"
    elif [[ ! "$pkg_cargo" == "null" ]]; then
        _installCargo "$pkg"
    else
        case $pkginst_manager in
        "pacman")
            if [[ ! "$pkg_aur" == "null" ]]; then
                _installPackageAur "$pkg" "$pkg_test"
            else
                if [[ ! "$pkg_pacman" == "null" ]]; then
                    pkg="$pkg_pacman"
                fi
                if [[ ! "$pkg" == "SKIP" ]]; then
                    _installPackage "$pkg" "$pkg_test"
                fi
            fi
            ;;
        "dnf")
            if [[ ! "$pkg_fedoracopr" == "null" ]]; then
                _addCoprRepository "$pkg_fedoracopr"
            fi
            if [[ ! "$pkg_dnf" == "null" ]]; then
                pkg="$pkg_dnf"
            fi
            if [[ ! "$pkg" == "SKIP" ]]; then
                _installPackage "$pkg" "$pkg_test"
            fi
            ;;
        "apt")
            if [[ ! "$pkg_apt" == "null" ]]; then
                pkg="$pkg_apt"
            fi
            if [[ ! "$pkg" == "SKIP" ]]; then
                _installPackage "$pkg" "$pkg_test"
            fi
            ;;
        "zypper")
            if [[ ! "$pkg_zypper" == "null" ]]; then
                pkg="$pkg_zypper"
            fi            
            if [[ ! "$pkg" == "SKIP" ]]; then
                _installPackage "$pkg" "$pkg_test"
            fi
            ;;
        "flatpak")
            # Use specific Flatpak ID if available, otherwise fall back to package name
            if [[ ! "$pkg_flatpak" == "null" ]]; then
                _installFlatpakFlathub "$pkg_flatpak"
            else
                _installFlatpakFlathub "$pkg"
            fi
            ;;
        esac
    fi    
}
