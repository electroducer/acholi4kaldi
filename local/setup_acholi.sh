# Get the acholi data organised to match the standard setup
# The script assumes that the data source files are in a specified directory

LANGUAGE=acholi

DATA_DIR="$DATA_PATH/$LANGUAGE"

# Unpack the source
unzip -d $DATA_PATH $DATA_PATH/data_sources/acholi-transcribed.zip

# Move the word lists out
mv $DATA_DIR/batch9/updated_wordlist $DATA_DIR

# Flatten the batch directories

# Get the list of batch dirs
batch_dirs=`ls -1d $DATA_DIR/b*`
# Make new directories
mkdir $DATA_DIR/mp3
mkdir $DATA_DIR/TextGrid
mkdir $DATA_DIR/txt

# We'll need to allow filenames with spaces to be handled
OIFS=$IFS
IFS=$'\n'

for dir in $batch_dirs; do
  echo Doing $dir ...
  for dtype in mp3 TextGrid txt; do
    for data_file in $(find $dir -name "*.${dtype}"); do
      base=$(basename $data_file ".${dtype}")
      batch=$(basename $dir)
      mv $data_file $DATA_DIR/$dtype/${batch}_${base}.$dtype
    done
  done
  [ "$(find $dir -type f)" ] && echo "Warning: $dir not empty" \
    || rm -rf $dir
done

mv $DATA_DIR/txt $DATA_DIR/speakers

# One of the speaker ID files is incorrectly named. This is fixed here.
mv $DATA_DIR/speakers/batch3_101_4_2015-05-13T07_35_43.txt \
  $DATA_DIR/speakers/batch3_101_4_1970-01-05T03_55_09.txt

# Rename files for simplicity
# We need to loop through the files and check to make sure that the IDs match
# Then we can number them from 1 to 64

for dtype in mp3 speakers TextGrid; do
  fcount=0
  echo "Making IDs for files in $dtype directory..."
  for data_file in $(ls -1 $DATA_DIR/$dtype); do
    let "fcount+=1"
    pretty_id=$(printf "%02d" $fcount)
    [ $dtype == "speakers" ] && ext="txt" || ext=$dtype
    mv $DATA_DIR/$dtype/$data_file $DATA_DIR/$dtype/${pretty_id}.${ext}
  done
  echo "Done"
done

# Reset the IFS
IFS=$OIFS
