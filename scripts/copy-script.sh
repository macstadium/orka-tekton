#!/bin/sh

set -u

SCRIPT=$1
BUILD_SCRIPT=$(openssl rand -hex 4)

# If script does not start with shebang, prepend it
[[ ! $(head -c2 $SCRIPT) == \#! ]] && cat > $BUILD_SCRIPT << EOF
#!/bin/sh
set -ex
EOF
cat $SCRIPT >> $BUILD_SCRIPT
chmod 755 $BUILD_SCRIPT

# Save name of build script and print contents to stdout
cat $BUILD_SCRIPT
echo $BUILD_SCRIPT | tee /tekton/results/build-script
