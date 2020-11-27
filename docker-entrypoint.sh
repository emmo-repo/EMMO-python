#!/bin/sh
set -e

# Print usage
usage() {
    cat <<EOF
Typical usage: docker run -i -t emmo-python [OPTIONS] [COMMAND] [ARGS...]
EOF
}

# Print help
help() {
    cat <<EOF
EMMO-python docker image.

$(usage)

Runs COMMAND within the image.

OPTIONS:
  -b, --branch   Branch name that --repo checks out.
  -c, --cleanup  Removes repository checked up with --repo option.
  -d, --dir      Directory that --repo checks out to.
  -h, --help     Print this help and exit.
  -r, --repo     If given, the entrypoint will check out this repository
                 and change working directory to its root.
  -v, --version  Print EMMO-python version and exit.


COMMANDS:
  ipy          Start a ipython session with get_ontology() loaded (default)
  emmocheck    Check an ontology; see "emmocheck --help"
  ontodoc      Generate documentation of an ontology; see "ontodoc --help"
  ontograph    Visualize an ontology; see "ontograph --help"
  ontoversion  Print version of an ontology; see "ontoversion --help"
  ontoconvert  Convert ontology file format; see "ontoconvert --help"
  bash         Start a unix shell. "sh" also works
EOF
}

# Print EMMO-python version number
# Assumes that cwd is the EMMO-python root directory
version() {
    sed -n 's/^__version__ *= *.\([0-9a-zA-Z._-]*\).*$/\1/p' emmo/__init__.py
}

# Cleanup function, removes repodir
cleanup() {
    cd
    [ -n "$repodir" ] || rm -rf "$repodir"
}

branchopt=
clean_up=false
repo=
repodir=

# Parse options
while true; do
    case "$1" in
        -b|--branch)            branchopt="--branch $2"; shift 2;;
        -c|--cleanup)           clean_up=true; shift;;
        -d|--dir|--directory)   repodir=$2; shift 2;;
        -h|--help)              help; exit 0;;
        -r|--repo|--repository) repo=$2; shift 2;;
        -v|--version)           version; exit 0;;
        --)                     shift; break;;
        -*)                     echo "Invalid option: $1"; usage; exit 1;;
        *)                      break;
    esac
done


# Clone and enter a repository
if [ -n "$repo" ]; then
    [ -n "$repodir" ] || repodir="$(mktemp -d)"
    git clone $repo --depth=1 --recurse-submodules --shallow-submodules \
        $branchopt "$repodir"
    cd "$repodir"

    # Register cleanup function when exiting the script
    $clean_up && trap cleanup EXIT
fi


# Parse commands
case "$1" in
    ''|ipy)  exec ipython \
                 --colors=LightBG \
                 --autocall=1 \
                 --no-confirm-exit \
                 --TerminalInteractiveShell.display_completions=readlinelike \
                 -i \
                 -c 'from emmo import get_ontology' \
                 "$@";;
    *)       $clean_up && "$@" || exec "$@";;
esac

exit 0
