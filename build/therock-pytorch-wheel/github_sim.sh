# Simulate github action environments
[ -f $GITHUB_ENV ] || touch $GITHUB_ENV
[ -f $GITHUB_PATH ] || touch $GITHUB_PATH
eval $(grep = $GITHUB_ENV | sed 's/^/GITHUB_ENV_/')
export PATH=$(tr '\n' ':' < $GITHUB_PATH)$PATH