# Assumes default cluster install
export KALDI_ROOT="/opt/kaldigpu"

# Path to raw data directory (will likely need to change this to relative)
export DATA_PATH="$HOME/asr/data"

# Standard Kaldi path definitions (taken from Kaldi examples)

# Environment variables
[ -f ../tools/env.sh ] && . ../tools/env.sh

# All the basic kaldi vars required
KALDISRC=$KALDI_ROOT/src
KALDIBIN=$KALDISRC/bin:$KALDISRC/featbin:$KALDISRC/fgmmbin:$KALDISRC/fstbin
KALDIBIN=$KALDIBIN:$KALDISRC/gmmbin:$KALDISRC/latbin:$KALDISRC/nnetbin
KALDIBIN=$KALDIBIN:$KALDISRC/sgmm2bin:$KALDISRC/lmbin

FSTBIN=$KALDI_ROOT/tools/openfst/bin
LMBIN=$KALDI_ROOT/tools/irstlm/bin
SCBIN=$KALDI_ROOT/tools/sctk-2.4.10/bin

[ -d $PWD/local ] || { echo "Error: 'local' subdirectory not found."; }
[ -d $PWD/utils ] || { echo "Error: 'utils' subdirectory not found."; }
[ -d $PWD/steps ] || { echo "Error: 'steps' subdirectory not found."; }

export kaldi_local=$PWD/local
export kaldi_utils=$PWD/utils
export kaldi_steps=$PWD/steps
SCRIPTS=$kaldi_local:$kaldi_utils:$kaldi_steps

# Adds these to existing path, so fine. Also adds pwd.
export PATH=$PATH:$KALDIBIN:$FSTBIN:$LMBIN:$SCBIN:$SCRIPTS


[ ! -f $KALDI_ROOT/tools/config/common_path.sh ] && echo >&2 "The standard file $KALDI_ROOT/tools/config/common_path.sh is not present -> Exit!" && exit 1
. $KALDI_ROOT/tools/config/common_path.sh

export LD_LIBRARY_PATH=$KALDI_ROOT/tools/openfst-1.3.4/lib:$KALDI_ROOT/tools/openfst-1.3.4/lib/fst:$KALDI_ROOT/tools/irstlm/lib:$LD_LIBRARY_PATH

export LC_ALL=C
