#!/bin/bash

# application.sh - Handles argument parsing, package name derivation, and setup.
# Repository: https://github.com/AsinaMilic/packages-installer

# --- Globals, Library Sourcing (Assumed to be set up by the main packages-installer script) ---
pkginst_script_dependencies="$HOME/.local/share/com.ml4w.packagesinstaller/lib/dependencies"
pkginst_download_folder="$HOME/.cache/download"
pkginst_log_folder="$HOME/.local/share/com.ml4w.packagesinstaller/log"
# pkginst_script_folder is typically $HOME/.local/share/com.ml4w.packagesinstaller/lib
# Ensure it's correctly passed or derived if this script is called directly.
if [ -z "$pkginst_script_folder" ]; then
    # This is a fallback, the main script should define it.
    pkginst_script_folder="$(cd "$(dirname "${BASH_SOURCE[0]}")" && cd .. && pwd)" # Assumes this is in lib/modules/
fi

# Source Library (library.sh should be in $pkginst_script_folder/lib/)
source "$pkginst_script_folder/lib/library.sh"
# Source Global Variables (from $pkginst_script_folder/global/)
_sourceFilesInFolder "$pkginst_script_folder/global"

# --- Variable Initialization ---
pkginst_manager=""
pkginst_source=""
pkginst_package=""
assumeyes_flag=1 # 1 means false (don't assume yes), 0 means true (assume yes)
debug_flag=1     # 1 means false (don't debug), 0 means true (debug)
aur_helper="yay"
pkginst_commanderrors=()
HELP_FLAG=false
INSTALLED_FLAG=false # For -i (preview) flag

# Language
pkginst_language="en"
source "$pkginst_script_folder/lang/$pkginst_language.sh"

# Create necessary folders if they don't exist
if [ ! -d "$pkginst_download_folder" ]; then mkdir -p "$pkginst_download_folder"; fi
if [ ! -d "$pkginst_log_folder" ]; then mkdir -p "$pkginst_log_folder"; fi
pkginst_log_file=$(date '+%Y%m%d%H%M%S') # For logging purposes

# --- Package Manager Detection ---
_echo "Detecting package manager..."
if command -v pacman >/dev/null 2>&1; then pkginst_manager="pacman"; _echo_success "Detected: pacman";
elif command -v apt-get >/dev/null 2>&1; then pkginst_manager="apt"; _echo_success "Detected: apt"; # Changed to apt-get for broader compatibility
elif command -v dnf >/dev/null 2>&1; then pkginst_manager="dnf"; _echo_success "Detected: dnf";
elif command -v zypper >/dev/null 2>&1; then pkginst_manager="zypper"; _echo_success "Detected: zypper";
else _echo_warning "No primary supported package manager (apt, dnf, pacman, zypper) detected."; fi

# --- Argument Parsing with getopt ---
OPTS=$(getopt -o s:p:a:hyid --long source:,packagemanager:,aurhelper:,help,assumeyes,installed,debug -- "$@")
if [ $? -ne 0 ]; then _echo_error "Failed to parse options. Use --help for usage."; exit 1; fi
eval set -- "$OPTS"

while true; do
    case "$1" in
        -s | --source) pkginst_source="$2"; shift 2 ;;
        -p | --packagemanager) pkginst_manager="$2"; shift 2 ;;
        -a | --aurhelper) aur_helper="$2"; shift 2 ;;
        -h | --help) HELP_FLAG=true; shift ;;
        -y | --assumeyes) assumeyes_flag=0; shift ;;
        -i | --installed) INSTALLED_FLAG=true; shift ;;
        -d | --debug) debug_flag=0; shift ;;
        --) shift; break ;;
        *) _echo_error "Internal error parsing options!"; exit 1 ;;
    esac
done

# Handle positional argument for pkginst_package (the package name for the configuration)
if [ "$#" -gt 0 ]; then
    pkginst_package="$1"
fi

# --- Help Display ---
if [ "$HELP_FLAG" = true ]; then
    echo "Usage: packages-installer [options] [config_package_name]"
    echo "Options:"
    echo "  -s, --source SOURCE          Path to local config dir/archive, or URL to .pkginst file/archive."
    echo "                               If SOURCE is a dir containing config.json/packages.json, it's used directly."
    echo "                               If SOURCE is a parent dir, config_package_name is expected as a subdir."
    echo "  -p, --packagemanager MANAGER Force specific package manager (apt, dnf, pacman, zypper, flatpak)."
    echo "  -a, --aurhelper HELPER       AUR helper for Arch (yay, paru). Default: yay."
    echo "  -i, --installed              Preview packages that would be installed from the specified config."
    echo "  -y, --assumeyes              Assume yes to all prompts."
    echo "  -d, --debug                  Enable debug mode (more verbose output)."
    echo "  -h, --help                   Display this help message."
    echo
    echo "config_package_name: Optional. Name of the configuration package."
    echo "                       If -s points to a directory containing config.json/packages.json directly,"
    echo "                       this can be omitted and name is derived from config.json."
    echo "                       If -s points to a parent directory, this specifies the sub-directory to use."
    echo "                       If -s is a URL, this is often derived from the filename."
    echo
    echo "Examples:"
    echo "  packages-installer -s ./my-config-dir             # Uses my-config-dir directly"
    echo "  packages-installer -s ./projects my-project       # Uses ./projects/my-project/pkginst/"
    echo "  packages-installer -s http://example.com/setup.pkginst"
    echo "  packages-installer my-installed-config-name -i  # Preview installed config"
    exit 0
fi

# --- Package Name and Path Derivation (Crucial Logic) ---
# This section determines pkginst_package and pkginst_data_folder

# If a source is provided, it takes precedence for defining the context.
if [ ! -z "$pkginst_source" ]; then
    # Absolutize local paths for consistency, ignore URLs
    if [[ "$pkginst_source" != *"://"* ]] && [[ "$pkginst_source" != /* ]]; then
        # Convert relative path to absolute path
        pkginst_source="$(cd "$(dirname "$pkginst_source")" 2>/dev/null && pwd)/$(basename "$pkginst_source")"
        # Clean up any double slashes
        pkginst_source=$(echo "$pkginst_source" | sed 's|//|/|g')
    fi

    # Case 1: pkginst_source is a directory directly containing config.json and packages.json
    if [ -d "$pkginst_source" ] && [ -f "$pkginst_source/config.json" ] && [ -f "$pkginst_source/packages.json" ]; then
        pkginst_data_folder="$pkginst_source"
        if [ -z "$pkginst_package" ]; then # If package name wasn't given as positional arg
            if ! command -v jq >/dev/null 2>&1; then 
                _echo_warning "jq is not installed. Attempting to install it..."
                # Try to install jq using the detected package manager
                case "$pkginst_manager" in
                    pacman) sudo pacman -S --noconfirm jq >/dev/null 2>&1 ;;
                    apt) sudo apt-get install -y jq >/dev/null 2>&1 ;;
                    dnf) sudo dnf install -y jq >/dev/null 2>&1 ;;
                    zypper) sudo zypper install -y jq >/dev/null 2>&1 ;;
                esac
                if ! command -v jq >/dev/null 2>&1; then
                    _echo_error "Failed to install jq. Please install it manually."
                    exit 1
                fi
            fi
            derived_name=$(jq -r '.name // .id // ""' "$pkginst_data_folder/config.json" 2>/dev/null)
            if [ -n "$derived_name" ] && [ "$derived_name" != "null" ]; then
                pkginst_package=$(echo "$derived_name" | tr ' ' '-' | tr '[:upper:]' '[:lower:]')
                _echo_info "Derived package name '$pkginst_package' from $pkginst_data_folder/config.json"
            else
                # Use directory name as fallback
                pkginst_package=$(basename "$pkginst_source" | tr ' ' '-' | tr '[:upper:]' '[:lower:]')
                _echo_info "Using directory name as package name: $pkginst_package"
            fi
        fi
    # Case 2: pkginst_source is a parent directory, and pkginst_package is a subdirectory (traditional structure)
    elif [ -d "$pkginst_source" ] && [ ! -z "$pkginst_package" ] && [ -d "$pkginst_source/$pkginst_package/pkginst" ]; then
        pkginst_data_folder="$pkginst_source/$pkginst_package/pkginst"
        _echo_info "Using traditional structure: $pkginst_data_folder"
    # Case 3: pkginst_source is a URL (handled by source.sh, which will set pkginst_package and download to a cache)
    elif [[ "$pkginst_source" == *"://"* ]]; then
        # source.sh will download and place it in a cache like $HOME/.local/share/com.ml4w.packagesinstaller/pkginst/$pkginst_package/pkginst
        # It will also set pkginst_package based on URL or archive contents.
        # For now, we just indicate that source.sh will handle it.
        _echo_info "Remote source specified. Processing will be handled by source module."
        # pkginst_data_folder will be determined *after* source.sh runs.
    else
        _echo_error "Invalid source specified: $pkginst_source"
        _echo_error "If local, ensure it exists and is either a directory with config.json/packages.json OR"
        _echo_error "a parent directory with a [config_package_name]/pkginst/ structure."
        exit 1
    fi
else 
    # No -s source: We are operating on an already installed/cached package configuration name.
    if [ -z "$pkginst_package" ]; then
        _echo_error "No source (-s) specified and no configuration package name provided."
        echo "Run with --help for usage. Or specify a config: packages-installer myconfig"
        exit 1
    fi
    # This is the standard location for installed configurations.
    # source.sh will also use this path if pkginst_source is not set.
    pkginst_data_folder="$HOME/.local/share/com.ml4w.packagesinstaller/pkginst/$pkginst_package/pkginst"
    _echo_info "Operating on installed/cached configuration: $pkginst_package"
fi

# --- Handle -i (INSTALLED_FLAG / Preview Mode) ---
# This now relies on pkginst_data_folder being correctly set above, or determined by source.sh for remote sources.
if [ "$INSTALLED_FLAG" = true ]; then
    if [ -z "$pkginst_data_folder" ] && [[ "$pkginst_source" == *"://"* ]]; then
         _echo_info "Previewing remote source. It will be downloaded first by source.sh."
         # source.sh needs to run to download and set pkginst_data_folder
    elif [ -z "$pkginst_data_folder" ] || ([ ! -d "$pkginst_data_folder" ] && [[ "$pkginst_data_folder" != *"://"* ]]); then 
        _echo_error "Cannot preview. Configuration data folder not found or not determined: $pkginst_data_folder"
        _echo_error "Ensure the package '$pkginst_package' is installed or the source path is correct."
        exit 1
    fi
    # If pkginst_data_folder is not yet set (e.g. remote source), source.sh will handle it then call _showAllPackages
    # If it is set, we can proceed. The actual call to _showAllPackages might be better placed after source.sh
    # to ensure remote sources are processed. For now, this sets it up.
    # The _showAllPackages function itself uses $pkginst_data_folder.
    
    # The actual preview logic (_showAllPackages) will be triggered after source.sh runs if it's a remote source,
    # or can be called here if we ensure source.sh is skipped or handles local paths non-destructively.
    # For simplicity, the main script logic should ensure _showAllPackages is called at the right time.
    # This flag primarily tells other modules (like sudo.sh) to skip certain actions.
    _echo_info "Preview mode enabled. Target data folder (after source processing): ${pkginst_data_folder:-Remote, to be processed}"
    # The actual call to _showAllPackages is usually at the end of the script execution flow in the main script.
    # For now, this flag signals other modules. The main `packages-installer` script should have logic like:
    # source application.sh -> source source.sh -> if INSTALLED_FLAG, _showAllPackages and exit.
fi

# --- Final Preparations ---
# Convert boolean flags to 0 for true, 1 for false, as used by the script
if [ "$assumeyes_flag" -eq 0 ]; then assumeyes=0; else assumeyes=1; fi
if [ "$debug_flag" -eq 0 ]; then debug=0; else debug=1; fi

# Verify system state (only if not help or preview)
if ! $HELP_FLAG && ! $INSTALLED_FLAG ; then
    _verify_system_state
fi

_echo_info "Application module initialized."
_echo_info "Package context: ${pkginst_package:-Not yet set}"
_echo_info "Data folder context: ${pkginst_data_folder:-Not yet set for remote/to be processed}"
_echo_info "Source specified: ${pkginst_source:-None}"

# Note: The main packages-installer script will then source source.sh,
# which will use $pkginst_source and $pkginst_package to prepare $pkginst_data_folder.
# If INSTALLED_FLAG is true, main script should call _showAllPackages after source.sh and then exit.
