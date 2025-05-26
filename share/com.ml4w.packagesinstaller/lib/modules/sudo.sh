# sudo permissions - only request when needed for installation
if [ "$HELP" != true ] && [ "$INSTALLED" != true ] && [ ! -z "$pkginst_package" ]; then
    sudo -v
fi
