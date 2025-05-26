# ------------------------------------------------
# GLOBALS
# ------------------------------------------------
pkginst_script_dependencies="$HOME/.local/share/com.ml4w.packagesinstaller/lib/dependencies"
pkginst_download_folder="$HOME/.cache/download"
pkginst_log_folder="$HOME/.local/share/com.ml4w.packagesinstaller/log"

# ----------------------------------------------------------
# Load Library
# ----------------------------------------------------------

# Current Directory
pkginst_script_directory=$(pwd)

# Source Library
source "$pkginst_script_folder/lib/library.sh"

# Source Global Variables
_sourceFilesInFolder "$pkginst_script_folder/global"

# ----------------------------------------------------------
# Set Variables
# ----------------------------------------------------------

# Package Manager
pkginst_manager=""

# Source for pkginst
pkginst_source=""

# Assume Yes
assumeyes=1

# Aur Helper
aur_helper="yay"

# CommandErrorList
pkginst_commanderrors=()

# ----------------------------------------------------------
# Set Language
# ----------------------------------------------------------
pkginst_language="en"
source "$pkginst_script_folder/lang/$pkginst_language.sh"

# ----------------------------------------------------------
# Set Download Folder
# ----------------------------------------------------------
if [ ! -d $pkginst_download_folder ]; then
    mkdir -p $pkginst_download_folder
fi

# ----------------------------------------------------------
# Set Log File and Folder
# ----------------------------------------------------------
pkginst_log_file=$(date '+%Y%m%d%H%M%S')
if [ ! -d $pkginst_log_folder ]; then
    mkdir -p $pkginst_log_folder
fi

# ----------------------------------------------------------
# Set Package Manager
# ----------------------------------------------------------
_echo "Detecting package manager..."

if [ $(_checkCommandExists "pacman") == "0" ]; then
    pkginst_manager="pacman"
    _echo_success "Detected package manager: pacman (Arch-based)"
elif [ $(_checkCommandExists "apt") == "0" ]; then
    pkginst_manager="apt"
    _echo_success "Detected package manager: apt (Debian-based)"
elif [ $(_checkCommandExists "zypper") == "0" ]; then
    pkginst_manager="zypper"
    _echo_success "Detected package manager: zypper (openSUSE)"
elif [ $(_checkCommandExists "dnf") == "0" ]; then
    pkginst_manager="dnf"
    _echo_success "Detected package manager: dnf (Fedora-based)"
else
    _echo_warning "No supported package manager detected automatically"
    pkginst_manager=""
fi

# ----------------------------------------------------------
# Parse command-line options
# ----------------------------------------------------------
OPTS=$(getopt -o s:p:a:hyid --long packagemanager:,aurhelper:,help,assumeyes,debug,installed -- "$@")

if [ $? -ne 0 ]; then
  _echo_error "Failed to parse options" >&2
  exit 1
fi

# Reset the positional parameters to the parsed options
eval set -- "$OPTS"

# Initialize variables
HELP=false
AURHELPER=false
PACKAGEMANAGER=false
ASSUMEYES=false
INSTALLED=false

# Process the options
while true; do
    case "$1" in
        -h | --help)
            HELP=true
            shift
        ;;
        -s | --source)
            if [ ! -z "$2" ]; then
                pkginst_source="$2"
            else
                _echo_error "Invalid mode '$2'. Please define a local path to your project folder or an url to remote .pkginst file." >&2
                exit
            fi
            shift 2
        ;;
        -a | --aurhelper)
            if [ "$2" = "yay" ] || [ "$2" = "paru" ]; then
                aur_helper="$2"
            else
                _echo_error "Invalid mode '$2'. Must be 'yay' or 'paru'." >&2
                exit
            fi
            shift 2
        ;;
        -p | --packagemanager)
            if [ "$2" = "apt" ] || [ "$2" = "dnf" ] || [ "$2" = "pacman" ] || [ "$2" = "zypper" ] || [ "$2" = "flatpak" ]; then
                pkginst_manager="$2"
            else
                _echo_error "Invalid mode '$2'. Must be 'apt','dnf','pacman','flatpak' or 'zypper'." >&2
                exit
            fi
            shift 2
        ;;
        -y | --assumeyes)
            ASSUMEYES=true
            shift
        ;;
        -d | --debug)
            DEBUG=true
            shift
        ;;
        -i | --installed)
            INSTALLED=true
            shift
        ;;
        --)
            shift
            break
        ;;
        *)
            _echo_error "Internal error!"
            exit 1
        ;;
    esac
done

# HELP
if [ "$HELP" = true ]; then
    echo "Usage: $0 [-h|--help] [-y|--assumeyes] [-i|--installed] [-a|--aurhelper AURHELPER] [-p|--packagemanager PACKAGEMANAGER] [-h|--help] pkginstpackage"
    echo
    echo "pkginst package must be available in $HOME/.local/share/com.ml4w.packagesinstaller/pkginst/"
    echo
    echo "Options:"
    echo "  -s, --source SOURCE                 Path to a local project folder or an url to a remote .pkginst file"
    echo "  -p, --packagemanager PACKAGEMANAGER Set the package manager directly instead of the autodetection. Choose from apt, dnf, pacman, zypper, flatpak"
    echo "  -a, --aurhelper AURHELPER           Define the Aur Helper in case of pacman for Arch based distributions"
    echo "  -i, --installed                     Shows all main packages that will be installed"
    echo "  -y, --assumeyes                     Assume yes for all confirmation dialogs"
    echo "  -d, --debug                         Show console output for debugging"
    echo "  -h, --help                          Display this help message"
    echo
    echo ":: Packages Installer $pkginst_version"
    echo ":: https://github.com/mylinuxforwork/packages-installer"

    exit 0
fi

# ASSUMEYES
if [ "$ASSUMEYES" = true ]; then
    assumeyes=0
fi

# DEBUG
if [ "$DEBUG" = true ]; then
    debug=0
fi

# INSTALLED
if [ "$INSTALLED" = true ]; then
    pkginst_package="$@"
    
    # If no package name provided but source is specified, we'll determine it later
    if [ -z "$pkginst_package" ] && [ ! -z "$pkginst_source" ]; then
        pkginst_package=""
    fi
    
    # For INSTALLED mode, we need to process source first to get the correct path
    # This mirrors the logic in source.sh but simplified for read-only access
    if [ ! -z "$pkginst_source" ]; then
        if [ -f "$pkginst_source/config.json" ] && [ -f "$pkginst_source/packages.json" ]; then
            # Direct pkginst directory
            if [ -z "$pkginst_package" ]; then
                pkginst_package=$(jq -r '.name // .id // "default-package"' "$pkginst_source/config.json" 2>/dev/null | tr ' ' '-' | tr '[:upper:]' '[:lower:]')
                if [ "$pkginst_package" = "null" ]; then
                    pkginst_package="default-package"
                fi
            fi
            pkginst_data_folder="$pkginst_source"
        else
            # Traditional structure
            if [ -z "$pkginst_package" ]; then
                _echo_error "Package name is required when using traditional source structure"
                exit 1
            fi
            pkginst_data_folder="$pkginst_source/$pkginst_package/pkginst"
        fi
    else
        # No source specified, use installed location
        pkginst_data_folder="$HOME/.local/share/com.ml4w.packagesinstaller/pkginst/$pkginst_package/pkginst"
    fi
    
    _showAllPackages
    exit
fi

# Verify system state after parsing arguments (only when needed)
_verify_system_state

pkginst_package="$@"

# If no package name provided but source is specified, we'll determine it later
if [ -z "$pkginst_package" ] && [ ! -z "$pkginst_source" ]; then
    pkginst_package=""
fi
