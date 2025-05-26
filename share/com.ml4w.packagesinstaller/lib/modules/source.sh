#!/bin/bash

# source.sh - Handles downloading/copying source configurations.
# Repository: https://github.com/AsinaMilic/packages-installer

# This script relies on variables set by application.sh:
# - pkginst_source: The user-provided source (URL or local path)
# - pkginst_package: The name of the package configuration (can be derived)
# - pkginst_data_folder: Will be set by this script to the final location of config data.
# - debug_flag: 0 for debug (true), 1 for no debug (false)

_echo_info "Source module started. Source: '$pkginst_source', Package: '$pkginst_package'"

# Ensure target directory for all configurations exists
GLOBAL_PKG_CACHE_DIR="$HOME/.local/share/com.ml4w.packagesinstaller/pkginst"
mkdir -p "$GLOBAL_PKG_CACHE_DIR"

# If no source is specified, we assume we are operating on an already cached/installed package.
if [ -z "$pkginst_source" ]; then
    if [ -z "$pkginst_package" ]; then
        _echo_error "Source module error: No source specified and no package name provided."
        exit 1
    fi
    pkginst_data_folder="$GLOBAL_PKG_CACHE_DIR/$pkginst_package/pkginst"
    if [ ! -d "$pkginst_data_folder" ]; then
        _echo_error "Source module error: Directory for '$pkginst_package' not found at $pkginst_data_folder"
        _echo_error "It might not be installed, or the name is incorrect."
        exit 1
    fi
    _echo_info "Using already installed/cached configuration for '$pkginst_package' at $pkginst_data_folder"
else
    # Source is specified (URL or local path)
    
    # --- Handle Remote URL Source ---
    if [[ "$pkginst_source" == *"://"* ]]; then
        _echo_info "Processing remote source: $pkginst_source"
        if [[ $(_checkCommandExists "wget") == 1 ]] || [[ $(_checkCommandExists "unzip") == 1 ]] || [[ $(_checkCommandExists "tar") == 1 ]]; then
            _echo_error "wget, unzip, and tar are required for remote sources."
            exit 1
        fi

        TMP_DOWNLOAD_DIR="$(mktemp -d)"
        DOWNLOADED_FILE="$TMP_DOWNLOAD_DIR/downloaded_source"

        _echo_info "Downloading to $DOWNLOADED_FILE..."
        if ! _execute_with_retry "wget --quiet -O \"$DOWNLOADED_FILE\" \"$pkginst_source\"" 3 "download remote source"; then
            _echo_error "Failed to download remote source: $pkginst_source"
            rm -rf "$TMP_DOWNLOAD_DIR"
            exit 1
        fi

        # Determine package name from URL if not set
        if [ -z "$pkginst_package" ]; then
            pkginst_package_derived_from_url=$(basename "$pkginst_source")
            pkginst_package_derived_from_url=${pkginst_package_derived_from_url%.pkginst}
            pkginst_package_derived_from_url=${pkginst_package_derived_from_url%.zip}
            pkginst_package_derived_from_url=${pkginst_package_derived_from_url%.tar.gz}
            pkginst_package_derived_from_url=${pkginst_package_derived_from_url%.tgz}
            pkginst_package="${pkginst_package_derived_from_url:-remote-package}"
            _echo_info "Derived package name from URL: $pkginst_package"
        fi

        # Destination for this specific package configuration
        CURRENT_PKG_DIR="$GLOBAL_PKG_CACHE_DIR/$pkginst_package"
        rm -rf "$CURRENT_PKG_DIR" # Clean up old version
        mkdir -p "$CURRENT_PKG_DIR/pkginst" # Ensure pkginst subdir exists
        pkginst_data_folder="$CURRENT_PKG_DIR/pkginst"

        _echo_info "Extracting to $pkginst_data_folder..."
        # Try unzip, then tar - expecting a flat structure or a single dir containing pkginst/
        if unzip -q "$DOWNLOADED_FILE" -d "$TMP_DOWNLOAD_DIR/extracted" >/dev/null 2>&1; then
            _echo_info "Successfully unzipped."
        elif tar -xzf "$DOWNLOADED_FILE" -C "$TMP_DOWNLOAD_DIR/extracted" >/dev/null 2>&1; then
            _echo_info "Successfully untarred (tar.gz)."
        else 
            _echo_error "Failed to extract: not a valid zip or tar.gz archive, or unsupported format."
            rm -rf "$TMP_DOWNLOAD_DIR"
            exit 1
        fi
        
        # Logic to find the actual config files (config.json, packages.json)
        # They could be directly in extracted/, or in extracted/some-dir/ or extracted/some-dir/pkginst/
        extracted_content_path="$TMP_DOWNLOAD_DIR/extracted"
        if [ -f "$extracted_content_path/config.json" ] && [ -f "$extracted_content_path/packages.json" ]; then
            cp -r "$extracted_content_path"/* "$pkginst_data_folder/"
        elif [ -d "$extracted_content_path/$pkginst_package/pkginst" ] && [ -f "$extracted_content_path/$pkginst_package/pkginst/config.json" ]; then # common structure like project/pkgname/pkginst/
             cp -r "$extracted_content_path/$pkginst_package/pkginst"/* "$pkginst_data_folder/"
        elif [ -d "$extracted_content_path/$pkginst_package" ] && [ -f "$extracted_content_path/$pkginst_package/config.json" ]; then # common structure like project/pkgname/
             cp -r "$extracted_content_path/$pkginst_package"/* "$pkginst_data_folder/"
        else 
            # Try to find the first directory inside extracted that might contain the files
            # This is a bit heuristic for less standard archives
            found_config=false
            for item in "$extracted_content_path"/*; do
                if [ -d "$item" ]; then # Check if item is a directory
                    if [ -f "$item/config.json" ] && [ -f "$item/packages.json" ]; then # Files directly in subdir
                        cp -r "$item"/* "$pkginst_data_folder/"
                        found_config=true; break
                    elif [ -d "$item/pkginst" ] && [ -f "$item/pkginst/config.json" ]; then # Files in subdir/pkginst/
                        cp -r "$item/pkginst"/* "$pkginst_data_folder/"
                        found_config=true; break
                    fi
                fi
            done
            if ! $found_config; then
                 _echo_error "Could not find config.json/packages.json in the extracted archive."
                 _echo_error "Expected files directly, or in a subdir, or in a subdir/pkginst/."
                 rm -rf "$TMP_DOWNLOAD_DIR"
                 exit 1
            fi
        fi
        rm -rf "$TMP_DOWNLOAD_DIR"
        _echo_success "Remote source processed and copied to $pkginst_data_folder"

    # --- Handle Local Path Source ---
    else 
        _echo_info "Processing local source: $pkginst_source"
        # pkginst_source is already an absolute path from application.sh
        if [ ! -e "$pkginst_source" ]; then # Check if it exists (file or directory)
            _echo_error "Local source path does not exist: $pkginst_source"
            exit 1
        fi

        # If pkginst_data_folder was already set by application.sh (direct config directory case)
        if [ ! -z "$pkginst_data_folder" ] && [ "$pkginst_data_folder" = "$pkginst_source" ]; then
            # Direct config directory case - already handled by application.sh
            # We just need to copy it to cache for consistency
            CURRENT_PKG_DIR="$GLOBAL_PKG_CACHE_DIR/$pkginst_package"
            rm -rf "$CURRENT_PKG_DIR"
            mkdir -p "$CURRENT_PKG_DIR/pkginst"
            cp -r "$pkginst_source"/* "$CURRENT_PKG_DIR/pkginst/"
            pkginst_data_folder="$CURRENT_PKG_DIR/pkginst"
            _echo_success "Copied direct local source to cache: $pkginst_data_folder"
        
        # If pkginst_package is not set, it means application.sh couldn't determine the structure
        elif [ -z "$pkginst_package" ]; then 
            # This shouldn't happen as application.sh should have handled it
            _echo_error "Local source '$pkginst_source' provided, but no package name determined."
            exit 1
        else
            # Traditional structure case: $pkginst_source/$pkginst_package/pkginst/
            pkginst_data_folder_candidate_trad="$pkginst_source/$pkginst_package/pkginst"
            pkginst_data_folder_candidate_flat="$pkginst_source/$pkginst_package"

            if [ -d "$pkginst_data_folder_candidate_trad" ] && [ -f "$pkginst_data_folder_candidate_trad/config.json" ]; then
                pkginst_data_folder="$pkginst_data_folder_candidate_trad"
            elif [ -d "$pkginst_data_folder_candidate_flat" ] && [ -f "$pkginst_data_folder_candidate_flat/config.json" ]; then
                 pkginst_data_folder="$pkginst_data_folder_candidate_flat" # if config is flat in pkgname dir
            else
                _echo_error "Could not find configuration for '$pkginst_package' under source '$pkginst_source'"
                _echo_error "Checked: $pkginst_data_folder_candidate_trad and $pkginst_data_folder_candidate_flat"
                exit 1
            fi            
            # Now copy this resolved local structure to the cache
            CURRENT_PKG_DIR="$GLOBAL_PKG_CACHE_DIR/$pkginst_package"
            rm -rf "$CURRENT_PKG_DIR"
            mkdir -p "$CURRENT_PKG_DIR/pkginst" # Final resting place is always .../pkginst/$pkg_name/pkginst/
            cp -r "$pkginst_data_folder"/* "$CURRENT_PKG_DIR/pkginst/"
            pkginst_data_folder="$CURRENT_PKG_DIR/pkginst" # Update to point to cache
            _echo_success "Copied local source to cache: $pkginst_data_folder"
        fi
    fi
fi

# --- Final Validation of pkginst_data_folder ---
if [ -z "$pkginst_data_folder" ]; then
    _echo_error "Source module critical error: pkginst_data_folder was not set."
    exit 1
fi
if [ ! -d "$pkginst_data_folder" ]; then
    _echo_error "Source module critical error: pkginst_data_folder is not a directory: $pkginst_data_folder"
    exit 1
fi
if [ ! -f "$pkginst_data_folder/config.json" ] || [ ! -f "$pkginst_data_folder/packages.json" ]; then
    _echo_error "Source module critical error: Missing config.json or packages.json in $pkginst_data_folder"
    ls -la "$pkginst_data_folder"
    exit 1
fi

_echo_info "Source module finished. Final pkginst_data_folder: $pkginst_data_folder"

# Set Log Folder based on final pkginst_package name
if [ ! -z "$pkginst_package" ]; then
    log_dir_for_package="$pkginst_log_folder/$pkginst_package"
    mkdir -p "$log_dir_for_package" # Ensure it exists
fi

# If INSTALLED_FLAG (preview) is true, call _showAllPackages now that data_folder is confirmed
if [ "$INSTALLED_FLAG" = true ]; then
    _echo_info "Preview mode: Showing packages from $pkginst_data_folder"
    _showAllPackages # This function uses $pkginst_data_folder implicitly
    exit 0 # Exit after preview
fi
