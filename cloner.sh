#!/bin/bash

# Load environment variables from .env file
if [ -f .env ]; then
    export $(cat .env | xargs)
else
    echo ".env file not found"
    exit 1
fi

# Function to check and clone repositories
clone_repo() {
    repo_name=$1
    org_name=$2
    repo_url="https://github.com/$org_name/$repo_name.git"

    # Create a folder for the organization if it doesn't exist and it's not the user
    if [ "$org_name" != "$GITHUB_USER" ]; then
        mkdir -p "$org_name"
        cd "$org_name"
    fi

    if [ -d "$repo_name" ]; then
        echo "The repository $org_name/$repo_name is already cloned. Skipping..."
    else
        echo "Cloning $org_name/$repo_name..."
        git clone $repo_url
    fi

    # Return to the parent directory if it's not the user
    if [ "$org_name" != "$GITHUB_USER" ]; then
        cd ..
    fi
}

# Clone personal repositories directly into the user's folder
echo "Cloning personal repositories..."
curl -s -H "Authorization: token $GITHUB_TOKEN" "https://api.github.com/users/$GITHUB_USER/repos?per_page=100" | jq -r ".[].name" | while read repo; do clone_repo $repo $GITHUB_USER; done

# Clone organization repositories into separate folders
echo "Cloning organization repositories..."
ORGANIZATIONS=$(curl -s -H "Authorization: token $GITHUB_TOKEN" "https://api.github.com/user/orgs" | jq -r ".[].login")
for org in $ORGANIZATIONS; do
    if [ "$org" != "$EXCLUDED_ORG" ]; then
        echo "Cloning repositories of the organization $org..."
        curl -s -H "Authorization: token $GITHUB_TOKEN" "https://api.github.com/orgs/$org/repos?per_page=100" | jq -r ".[].name" | while read repo; do clone_repo $repo $org; done
    else
        echo "Skipping the organization $org..."
    fi
done
