#!/usr/bin/env perl
use warnings; #sed replacement for -w perl parameter

# Based on the gp normalisation scripts

# Main tasks:
# 1. Strip the ending symbols
# 2. Get rid of English indicators
# 3. Drop all other indicators and symbols

my $usage = "Usage: clean_trans_acholi.pl [-r|-u] transcript > formatted\
Input format assumed to be acholi with special annotations and symbols. \
\n";

use strict;
binmode(STDOUT, ":encoding(utf8)");

die "$usage" unless(@ARGV == 1);
my $in_trans = $ARGV[0];  # Input transcription
my $uppercase;

open(T, "<$in_trans") or die "Cannot open transcription file '$in_trans': $!";
while (<T>) {
  s/\r//g;  # Since files may have CRLF line-breaks!
  chomp;
  $_ =~ m:^(\S+)\s+(.+): or die "Bad line: $_";
  my $utt_id = $1;
  my $trans = $2;

  $trans =~ s/\"/ /g;  # Remove quotation marks.
  $trans =~ s/&.{1,2}&//g; # Remove language tags
  $trans =~ s/[=#@\*]//g; # Remove tags indicating language?
  $trans =~ s/[\,\?\!\:]/ /g; # Remove remaining punctuation (but leave the dot)


  $trans =~ s/\[-\]-/ /g; # Remove stutters
  $trans =~ s/\[(.+)\/-\]/$1/g; # Remove guesses
  $trans =~ s/\[(.+)\/(.+)\]/$2/g; # Remove pronunciations


  $trans =~ s/%[A-Z]/ /g; # Remove speaker tags
  # $trans =~ s/\<fil\>/ /g; # Remove fills (keeping this in to force noise)
  # Normalize spaces
  $trans =~ s/^\s*//; $trans =~ s/\s*$//; $trans =~ s/\s+/ /g;

  # $trans = &rmn2utf8_FR($trans);
  if (defined($uppercase)) {
    $trans = uc($trans);
  } else {
    $trans = lc($trans);
  }

  print "$utt_id $trans\n";
}
