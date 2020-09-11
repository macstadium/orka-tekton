#!/bin/sh

set -u

SCRIPT=$1
BUILD_SCRIPT=$(basename $SCRIPT)

# If script does not start with shebang, prepend it
[[ ! $(head -c2 $SCRIPT) == \#! ]] && cat > $BUILD_SCRIPT << EOF
#!/bin/sh
set -ex
EOF
cat $SCRIPT >> $BUILD_SCRIPT
chmod 755 $BUILD_SCRIPT

# Save name of build script and print contents to stdout
cat $BUILD_SCRIPT
echo ---
echo $BUILD_SCRIPT | tee /tekton/results/build-script
