# Packages Installer

Create an enhanced and multiplatform installation script for your favorite package collection, dependencies for your dotfiles configuration or for a single flatpak app. This is possible with the Packges Installer script.

The script will detect automatically your available Linux package manager and will install the packages directly or with a custom installation command for full flexibility.

![image](https://github.com/user-attachments/assets/c05677e6-33e5-4bce-9e0b-7dbade67c87d)

In addition, you can offer an optional set of packages where the user can choose from, e.g. browsers, terminals, file managers, etc.

You can provide installation configurations with compressed .pkginst file on your webserver or remote Git Repository like GitHub or GitLab or can install and test a local configuration.

You can find examples here: https://github.com/mylinuxforwork/packages-installer/tree/main/examples

The following package managers are currently supported:
- apt (e.g. for Ubuntu)
- dnf (e.g. for Fedora)
- pacman (e.g. for Arch Linux)
- zypper (e.g. for openSuse)
- flatpak

> With custom installations you can also use yay, paru, add repos for dnf, etc.

Is your package manager currently not supported, your can export a list of packages from the configuration and suggest to install the packages manually.

You can find more information in the Wiki. https://github.com/mylinuxforwork/packages-installer/wiki

> The Packages Installer Editor will support you with an UI to create your installation configurations even faster. The Packages Installer Editor is currently in development and a first BETA will be available soon.

## Stability & Reliability

The packages installer now includes comprehensive stability improvements:

- **Robust Error Handling**: Graceful handling of network failures, missing dependencies, and installation errors
- **Automatic Retry Mechanism**: Failed operations are automatically retried with exponential backoff
- **Rollback Support**: Failed installations can be rolled back to maintain system consistency
- **Input Validation**: All inputs are validated before processing to prevent unexpected failures
- **Comprehensive Logging**: Detailed logging for troubleshooting and monitoring
- **System State Verification**: Pre-installation checks ensure system compatibility

Run the stability test suite to verify your environment:

```bash
./dev/test-stability.sh
```

## Installation

You can install a local developement environment with the following command:

```
bash <(curl -s https://raw.githubusercontent.com/mylinuxforwork/packages-installer/main/install.sh)
```

You can add the packages-installer binary to your path with
# export PATH=$PATH:~/.cargo/bin/
export PATH=$PATH:~/.local/bin/

## Usage

The packages installer supports multiple usage patterns:

### 1. Install from Remote URL

```bash
packages-installer -s https://example.com/mypackages.pkginst
```

### 2. Install from Local pkginst Directory

```bash
# Direct pkginst directory (contains config.json and packages.json)
packages-installer -s /path/to/pkginst/directory

# Example with this repository's examples
packages-installer -s ./examples/com.ml4w.hyprlandsettings/pkginst
```

### 3. Install from Traditional Project Structure

```bash
# Traditional structure: source/package-name/pkginst/
packages-installer -s /path/to/source package-name
```

### 4. Install from Compressed Archive

```bash
# From .pkginst file (compressed tar.gz or zip)
packages-installer -s https://example.com/package.pkginst
```

### Directory Structure

Your package configuration should follow this structure:

```
your-package/
├── pkginst/
│   ├── config.json          # Package metadata
│   ├── packages.json        # Package definitions
│   ├── scripts/
│   │   ├── pre.sh          # Pre-installation script (optional)
│   │   └── post.sh         # Post-installation script (optional)
│   └── [distro]/           # Custom installers (optional)
│       ├── custom-package
│       └── another-package
```

### Additional Options

```bash
# Show packages without installing
packages-installer -s /path/to/config -i

# Auto-confirm all prompts
packages-installer -s /path/to/config -y

# Enable debug output
packages-installer -s /path/to/config -d

# Force specific package manager
packages-installer -s /path/to/config -p pacman

# Set AUR helper for Arch Linux
packages-installer -s /path/to/config -a yay
```
