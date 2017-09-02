# Converts and splits audio files

# Check for sox
which sox

# Pass the language as an argument
DATA_DIR="$DATA_PATH/$1"
[ -d $DATA_DIR ] || exit 1

# Create a new directory for wav files
mkdir -p $DATA_DIR/wav
mkdir -p $DATA_DIR/tmpwav


# Convert all files to wavs
for afile in `ls $DATA_DIR/mp3`; do
  base=`basename $afile .mp3`
  # Decode the mp3 files to wav
  lame --decode $DATA_DIR/mp3/${base}.mp3 $DATA_DIR/tmpwav/${base}.wav

  # Adjust sample rate and split according start and end points
  nutts=0
  # Iterate over durations (filenames correspond)
  while read dur; do
    let "nutts+=1"
    [ $nutts -lt 100 ] && ind=0$nutts || ind=$nutts
    [ $nutts -lt 10 ] && ind=0$ind
    echo "Creating segment ${ind}"
    sox $DATA_DIR/tmpwav/${base}.wav -r 16000 -e signed-integer -b 16 \
        -t wav $DATA_DIR/wav/${base}_${ind}.wav trim ${dur// / =}
    if [ $? -ne 0 ]; then
      echo "Error for ${base}: exit status = $?";
      let "nsoxerr+=1"
    else
      nsamples=`soxi -s "$DATA_DIR/wav/${base}_${ind}.wav"`;
      if [[ "$nsamples" -lt 1000 ]]; then
        echo "Error for ${base}: samples = $nsamples";
        let "nsoxerr+=1"
      fi
    fi
  done < $DATA_DIR/trans/time_${base}
done


[[ "$nsoxerr" -gt 0 ]] && \
  echo "sox: error converting $nsoxerr file(s)" >&2
