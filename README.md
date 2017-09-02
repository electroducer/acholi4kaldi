# Acholi for Kaldi

## A complete Kaldi recipe for training an Acholi ASR system

### About

This recipe is based on existing Kaldi recipes and was produced as part of a dissertation project at the University of Edinburgh. The scripts will make baseline ASR systems for Acholi, a language spoken in northern Uganda and South Sudan. A series of two-dimensional experiments are also carried out to compare phoneme-based vs. grapheme-based acoustic models as well as various bottleneck features trained on supplementary datasets from multiple languages.

### Required data

The scripts are designed for proprietary datasets and will not run as is without them. The Acholi and supplementary Luganda radio datasets were obtained from [a third party](http://unglobalpulse.org/kampala) and cannot be acquired without express permission. The supplementary Swahili dataset is from the [GlobalPhone corpus](http://catalog.elra.info/product_info.php?products_id=1258), which can be purchased.

The scripts will expect the source data to be found in a parallel directory called `data`; however, this path can be changed by modifying the `DATA_PATH` variable in the `path.sh` script.

### Required links

Similar to other Kaldi recipes, local symbolic links pointing to the `steps` and `utils` directories from the WSJ Kaldi recipes are required.

### Running the scripts

For all `run*.sh` scripts, it is recommended that they be run line-by-line in order to ensure that they work as expected and to break up the training and decoding process, which may take a considerable amount of time.

- `run_{1,2,3}_gmm_{acholi,swahili,luganda}.sh`: These scripts will train and decode a series of baseline HMM-GMM systems for for Acholi, Swahili, and Luganda, respectively. The scripts are almost identical; however, several fundamental differences in the data among languages, they have been separated into multiple scripts rather than looping over each language in a single script.
- `run_4_advanced.sh`: This script will first train and decode a baseline HMM-DNN system, then it will train various bottleneck DNNs, extract the bottleneck features, and use them for training and decoding further HMM-GMM and HMM-DNN systems.

### Customisation

To adapt the scripts for alternative datasets, you will likely need to modify or skip the data preparation process. Please see the `local/data_prep.sh` script for details
