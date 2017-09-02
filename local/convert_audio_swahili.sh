# Converts and splits audio files

# Check for sox
which sox

# Pass the language as an argument
DATA_DIR="$DATA_PATH/$1"
[ -d $DATA_DIR ] || exit 1

# Create a new directory for wav files
mkdir -p $DATA_DIR/wav
mkdir -p $DATA_DIR/tmpwav

OLIST=${OLIST:-/dev/null}
nsoxerr=0;

# Convert all files to wavs
for afile in `ls $DATA_DIR/adc/*/*`; do
  base=`basename $afile .adc`

  sox -t raw -r 16000 -e signed-integer -b 16 $afile \
      -t wav $DATA_DIR/wav/${base}.wav
  if [ $? -ne 0 ]; then
    echo "${afile}: exit status = $?" >> $soxerr;
    let "nsoxerr+=1"
  else
    # Just in case there are empty files! Setting the cutoff at 1000 samples,
    # which, assuming 16KHz sampling, is 0.0625 seconds.
    nsamples=`soxi -s "$DATA_DIR/wav/${base}.wav"`;
    if [[ "$nsamples" -gt 1000 ]]; then
	    echo "$DATA_DIR/wav/${base}.wav" >> $OLIST;
    else
	    echo "${afile}: #samples = $nsamples" >> $soxerr;
	    let "nsoxerr+=1"
    fi
  fi
done


[[ "$nsoxerr" -gt 0 ]] && \
  echo "sox: error converting $nsoxerr file(s)" >&2
