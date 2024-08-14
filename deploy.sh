# Get a timestamp to identify this release:
DATE="$(date +'%Y-%m-%d--%H%M%S')" # -> 2023-01-01--123456

# Define paths we’ll be working with:
SHARED="$WORKING/shared"
WORKING="/var/www"                 # Root deploy directory
RELEASE="$WORKING/releases/$DATE"  # New release directory
CURRENT="$WORKING/current"         # Live release “link”

# Shallow-clone a fresh copy of the latest project files into our release directory:
git clone --depth=1 git@github.com/organization/repo $RELEASE

# Move into the release directory:
pushd $RELEASE

# Install Composer packages:
composer install --no-interaction

# Build other artifacts:
npm install
npm run build

# Move back out to the main directory:
popd

# Create links to persistent files:
ln -s "$RELEASE/.env" "$SHARED/.env"
ln -s "$RELEASE/web/uploads" "$SHARED/web/uploads"


php $RELEASE/craft up --interactive=0

# Create a symbolic link to the new release:
ln -sf $RELEASE $CURRENT
