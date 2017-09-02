# Get the acholi data organised to match the standard setup
# The script assumes that the data source files are in a specified directory

LANGUAGE=luganda

DATA_DIR="$DATA_PATH/$LANGUAGE"

# Unpack the source
mkdir -p $DATA_PATH/$LANGUAGE
unzip -d $DATA_PATH/$LANGUAGE $DATA_PATH/data_sources/$LANGUAGE-transcribed.zip

# Make new directories
mkdir $DATA_DIR/mp3
mkdir $DATA_DIR/TextGrid

FILE_DIR=$DATA_DIR/${LANGUAGE}-transcribed

for dtype in mp3 TextGrid; do
  fcount=0
  for data_file in $(ls $DATA_DIR/luganda-transcribed/*.$dtype); do
    [ -f ]
    let "fcount+=1"
    pretty_id=$(printf "%03d" $fcount)
    mv $data_file $DATA_DIR/$dtype/${pretty_id}.${dtype}
  done
done

[ "$(find $FILE_DIR -type f)" ] \
  && echo "Warning: $FILE_DIR not empty" \
  || rm -rf $FILE_DIR

# There is a typo (extra new line) in some of the transcriptions.
for fnum in 028 052 057 063 127; do
  cat $DATA_DIR/TextGrid/${fnum}.TextGrid \
    | sed -r '$!N;s/(text = ").*\nJUNK"/\1JUNK"/;P;D' \
    > $DATA_DIR/TextGrid/${fnum}_new.TextGrid
  mv $DATA_DIR/TextGrid/${fnum}_new.TextGrid $DATA_DIR/TextGrid/${fnum}.TextGrid
done
