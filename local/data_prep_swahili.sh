#!/bin/bash

# Borrowed mainly from gp data prep

[ -f path.sh ] && . path.sh

L=swahili


# Convert the audio
local/convert_audio_swahili.sh

# Make the file lists
local/make_flists_swahili.sh --work-dir=data --list-dir=conf $L

# Done
