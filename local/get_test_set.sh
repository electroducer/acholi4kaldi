DATA_DIR=$DATA_PATH/acholi

for f in $(ls $DATA_DIR/trans/*.trans); do
  grep -v JUNK $f | wc -l >> utt_counts
done
