# Need to fix this as it is not fast at all. Probably convert to perl.
TRANS=$1

for tfile in $(ls $DATA_PATH/$L/trl/*); do
  while read line; do
    if [[ "$line" =~ ID ]]; then
      spk_id=$(echo $line | cut -d " " -f2 \
        | sed -e 's/[^0-9]//' -e 's/[^0-9]$//')
      echo $spk_id and $tfile
    elif [[ "$line" =~ \;\ [0-9] ]]; then
      utt_id=$(echo $line | cut -d " " -f2 \
        | sed -e 's/[^0-9]//' -e 's/[^0-9]$//')
    elif [[ "$line" =~ ^[A-Za-z] ]]; then
      utt=$(echo $line | sed -e 's/^[^A-Za-z]//' -e 's/[^A-Za-z]$//')
      echo "${spk_id}_${utt_id} ${utt}" >> $TRANS
    fi
  done < $tfile
done
