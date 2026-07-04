#!/bin/bash

# Function to delete a user by username
function delete_user() {
    local username="$1"
    if [[ "$username" =~ ^nixbld[1-9][0-9]?$ ]]; then
        sudo userdel "$username"
        echo "Deleted user: $username"
    else
        echo "User $username does not match the Nix build user pattern."
    fi
}

# Get the list of users from /etc/passwd
users=$(cut -d: -f1 /etc/passwd)

# Iterate through the users and delete those matching the pattern
for user in $users; do
    delete_user "$user"
done
