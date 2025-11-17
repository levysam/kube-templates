read -p "this operation erease all the drives listed, are you sure you want to proceed? [y/N] " -n 1 -r REPLY
echo # (optional) Move to a new line after input

if [[ "$REPLY" =~ ^[Yy]$ ]]; then
    echo "Proceeding with the operation."
    kubectl directpv init drives.yaml --dangerous
    # Add commands to execute if confirmed
else
    echo "Operation cancelled."
    # Add commands to execute if cancelled (or simply exit)
    exit 1 # Exit with an error code
fi

