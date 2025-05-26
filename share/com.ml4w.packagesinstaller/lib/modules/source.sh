if [ -z "$pkginst_package" ]; then
    # Allow empty package name if source is provided - we'll determine it later
    if [ -z "$pkginst_source" ]; then
        _echo_error "Please specify the name of the pkginst package: package-installer pkginstpackage"
        _echo_error "Or use -s flag to specify a source: packages-installer -s /path/to/source [package-name]"
        exit 1
    fi
fi

# Remove Old Package
if [ ! -z "$pkginst_package" ] && [ -d "$HOME/.local/share/com.ml4w.packagesinstaller/pkginst/$pkginst_package" ]; then
    rm -rf "$HOME/.local/share/com.ml4w.packagesinstaller/pkginst/$pkginst_package" 2>/dev/null
fi

# Install Source
if [ ! -z "$pkginst_source" ]; then
    if [[ $pkginst_source == *"https://"* ]]; then
        # Check for dependencies
        if [[ $(_checkCommandExists "unzip") == 1 ]] || [[ $(_checkCommandExists "wget") == 1 ]]; then
            _echo_error "For remote sources you need to have wget and unzip installed on your system."
            exit 1
        fi

        # Clean up previous attempts
        rm -f "$HOME/.cache/pkginst_tmp.zip" 2>/dev/null
        rm -rf "$HOME/.cache/pkginst_tmp" 2>/dev/null
        
        # Ensure cache directory exists
        mkdir -p "$HOME/.cache" 2>/dev/null

        # Download Remote with validation
        _echo "Checking remote source: $pkginst_source"
        if ! wget --spider "$pkginst_source" 2>/dev/null; then
            _echo_error "Remote file does not exist or is not accessible. Please check your URL: $pkginst_source"
            exit 1
        fi
        
        _echo "Downloading remote source..."
        if ! _execute_with_retry "wget -q -c \"$pkginst_source\" -O \"$HOME/.cache/pkginst_tmp.zip\"" 3 "download remote source"; then
            _echo_error "Failed to download remote source after multiple attempts"
            exit 1
        fi

        # Check if file is actually a valid zip
        if ! unzip -t "$HOME/.cache/pkginst_tmp.zip" >/dev/null 2>&1; then
            rm -f "$HOME/.cache/pkginst_tmp.zip" 2>/dev/null
            _echo_error "Downloaded file is not a valid zip archive"
            exit 1
        fi
        
        # Ensure target directory exists
        target_dir="$HOME/.local/share/com.ml4w.packagesinstaller/pkginst/"
        mkdir -p "$target_dir" 2>/dev/null

        # Unzip to target folder
        _echo "Extracting package..."
        if ! unzip -o -q "$HOME/.cache/pkginst_tmp.zip" -d "$target_dir" 2>/dev/null; then
            _echo_error "Failed to extract package archive"
            exit 1
        fi
        
        # Clean up downloaded file
        rm -f "$HOME/.cache/pkginst_tmp.zip" 2>/dev/null
        
    else
        # Local source validation
        if [ ! -d "$pkginst_source" ]; then
            _echo_error "Source directory does not exist: $pkginst_source"
            exit 1
        fi
        
        # Check if source is already a pkginst directory (contains config.json and packages.json)
        if [ -f "$pkginst_source/config.json" ] && [ -f "$pkginst_source/packages.json" ]; then
            # Direct pkginst directory - extract package name from config if not provided
            if [ -z "$pkginst_package" ] || [ "$pkginst_package" = "" ]; then
                if [ -f "$pkginst_source/config.json" ]; then
                    pkginst_package=$(jq -r '.name // .id // "default-package"' "$pkginst_source/config.json" 2>/dev/null | tr ' ' '-' | tr '[:upper:]' '[:lower:]')
                    if [ "$pkginst_package" = "null" ]; then
                        pkginst_package="default-package"
                    fi
                else
                    pkginst_package="default-package"
                fi
            fi
            
            # Ensure target directory exists
            target_dir="$HOME/.local/share/com.ml4w.packagesinstaller/pkginst/$pkginst_package/pkginst"
            mkdir -p "$target_dir" 2>/dev/null
            
            _echo "Copying local pkginst configuration..."
            if ! cp -rf "$pkginst_source"/* "$target_dir/" 2>/dev/null; then
                _echo_error "Failed to copy local pkginst configuration"
                exit 1
            fi
        else
            # Traditional structure - expect source/package/pkginst
            if [ -z "$pkginst_package" ] || [ "$pkginst_package" = "" ]; then
                _echo_error "Package name is required when using traditional source structure. Use: packages-installer -s /path/to/source package-name"
                exit 1
            fi
            
            if [ ! -d "$pkginst_source/$pkginst_package" ]; then
                _echo_error "pkginst package '$pkginst_source/$pkginst_package' does not exist."
                _echo_error "Expected structure: $pkginst_source/$pkginst_package/pkginst/"
                exit 1
            fi
            
            # Ensure target directory exists
            target_dir="$HOME/.local/share/com.ml4w.packagesinstaller/pkginst"
            mkdir -p "$target_dir" 2>/dev/null
            
            _echo "Copying local source..."
            if ! cp -rf "$pkginst_source/$pkginst_package" "$target_dir" 2>/dev/null; then
                _echo_error "Failed to copy local source"
                exit 1
            fi
        fi
    fi
fi

# Set and validate target folder
pkginst_data_folder="$HOME/.local/share/com.ml4w.packagesinstaller/pkginst/$pkginst_package/pkginst"
if [ ! -d "$pkginst_data_folder" ]; then
    _echo_error "Cannot find the pkginst package $pkginst_package in $HOME/.local/share/com.ml4w.packagesinstaller/pkginst/"
    _echo_error "Expected directory structure:"
    _echo_error "  $HOME/.local/share/com.ml4w.packagesinstaller/pkginst/$pkginst_package/pkginst/"
    _echo_error "    ├── config.json"
    _echo_error "    └── packages.json"
    exit 1
fi

# Check if main config file exists
if [ ! -f "$pkginst_data_folder/packages.json" ]; then
    _echo_error "Package configuration file not found: $pkginst_data_folder/packages.json"
    exit 1
fi

# Set Log Folder
log_dir="$pkginst_log_folder/$pkginst_package"
mkdir -p "$log_dir" 2>/dev/null
