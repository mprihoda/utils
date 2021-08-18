#!/usr/bin/env nix-shell
#!nix-shell -i bash -p stdenv

NAME=${1:-IntelliJ}
CDIR=~/.projector/configs/${NAME}
CONFIG=${CDIR}/config.ini
RUN=${CDIR}/run.sh
IDEA=$(awk -F "=" '/path/ {print $2}' ${CONFIG} | sed -e 's/^[ \t]*//')
INTERP=$(cat $NIX_CC/nix-support/dynamic-linker)
E2FSLIB=$(dirname $(nix-locate --top-level libe2p.so | head -1 | awk '{print $4}'))

BINS="bin/fsnotifier jbr/bin/java jbr/bin/javac jbr/bin/keytool"

fail () {
    echo $1
    exit 1
}

patch () {
    for i in $BINS
    do
        patchelf --set-interpreter "${INTERP}" "${IDEA}/$i"
    done
}

fix_run () {
    sed -i.bak "2i\\
export PATH=/run/current-system/sw/bin:~/.nix-profile/bin:~/.local/bin:\$PATH\\
export LD_LIBRARY_PATH=~/.nix-profile/lib:$NIX_CC/lib:$E2FSLIB\\
" $RUN
}

if [ ! -x "$INTERP" ]
then
    fail "Interpreter '$INTERP' does not exist."
fi

if [ ! -d "$IDEA" ]
then
   fail "IDEA dir '$IDEA' does not exist."
fi

patch && fix_run
