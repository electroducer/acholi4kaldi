# Parses TextGrid files to get starts, ends, and transcriptions

# Get directory containing textgrid files
TG_PATH=$1

# Make a new directory for parsed data
TR_PATH=`dirname $TG_PATH`/trans
mkdir -p $TR_PATH


# Loop over textgrid files
nfiles=0
for line in `ls $TG_PATH/*.TextGrid`; do
  # Set up new data files
  base=`basename $line .TextGrid`
  TIME=$TR_PATH/time_${base}
  TEXT=$TR_PATH/${base}.trans
  [ -e $TIME ] && rm $TIME
  [ -e $TEXT ] && rm $TEXT
  # Loop over lines in textgrid file
  go=false
  utt=0
  while read p; do
    if [ "$go" == false ]; then
      if [ "$(echo $p | grep ^intervals)" ]; then
        go=true
      fi
    fi
    if [ "$go" == true ]; then
      case "$p" in
        xmin*)
          START=`echo $p | cut -d" " -f3`
          ;;
        xmax*)
          echo "$START `echo $p | cut -d" " -f3`" >> $TIME
          ;;
        text*)
          let "utt+=1"
          [ $utt -lt 100 ] && ind=0$utt || ind=$utt
          [ $utt -lt 10 ] && ind=0$ind
          tp=${p:8}
          echo "${base}_${ind} ${tp::-3}" >> $TEXT
          ;;
      esac
    fi
  done < $line
  let "nfiles+=1"
  echo $nfiles completed
done
