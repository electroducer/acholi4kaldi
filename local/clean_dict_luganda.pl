#!/usr/bin/env perl
use warnings; #sed replacement for -w perl parameter

# Based on the gp norm_dict scripts
# This file is not tested very well on the input format.
# It may require further modifications.

my $usage = "Usage: clean_dict_acholi.pl [-l|-m map|-r|-u] -i dictionary > formatted\
Normalises the dict.\
There will probably be duplicates; so pipe the output through sort -u \
Options:\
  -l\tAdd language tag to the phones
  -m FILE\tMapping to a different phoneset
  -r\tKeep words in GlobalPhone-style ASCII (convert to UTF8 by default)\
  -u\tConvert words to uppercase (by default make everything lowercase)\n";

use strict;
use Getopt::Long;
use Unicode::Normalize;

die "$usage" unless(@ARGV >= 1);
my ($in_dict, $lang_tag, $map_file, $keep_rmn, $uppercase);
GetOptions ("l" => \$lang_tag,    # tag phones with language ID.
	    "m=s" => \$map_file,  # map to a different phoneset
            "r" => \$keep_rmn,    # keep words in GlobalPhone-style ASCII (rmn)
	    "u" => \$uppercase,   # convert words to uppercase
            "i=s" => \$in_dict);  # Input lexicon

binmode(STDOUT, ":encoding(utf8)") unless (defined($keep_rmn));

my %phone_map = ();
if (defined($map_file)) {
  warn "Language tag added (-l) while mapping to different phoneset (-m)"
      if (defined($lang_tag));
  open(M, "<$map_file") or die "Cannot open phone mapping file '$map_file': $!";
  while (<M>) {
    next if /^\#/;  # Skip comments
    s/\r//g;  # Since files may have CRLF line-breaks!
    chomp;
    next if /^$/;   # skip empty lines
    # The mapping is assumed to be: 'from-phone' 'to-phone'
    die "Bad line: $_" unless m/^(\S+)\s+(\S+).*$/;
    die "Multiple mappings for phone $1: '$2' and '$phone_map{$1}'"
	if (defined($phone_map{$1}));
    $phone_map{$1} = $2;
  }
}

open(L, "<$in_dict") or die "Cannot open dictionary file '$in_dict': $!";
while (<L>) {
  s/\r//g;  # Since files may have CRLF line breaks!
  chomp;
  next if($_=~/\#/);  # Usually incomplete or empty prons
  $_ =~ m:^\{?(\S*?)\}?\s+\{?(.+?)\}?$: or die "Bad line: $_";
  my $word = $1;
  my $pron = $2;
  next if ($pron =~ /sil/);  # Silence will be added later to the lexicon

  # First, normalize the pronunciation:
  $pron =~ s/\{//g;
  $pron =~ s/^\s*//; $pron =~ s/\s*$//;  # remove leading or trailing spaces
  $pron =~ s/ WB\}//g;
  $pron =~ s/\s+/ /g;  # Normalize spaces
  $pron =~ s/M_//g;    # Get rid of the M_ marker before the phones

  if (defined($map_file)) {
    my (@phones) = split(' ', $pron);
    for my $i (1..$#phones) {
      if (defined($phone_map{$phones[$i]})) {
	$phones[$i] = $phone_map{$phones[$i]};
      } else {
	warn "No mapping found for $phones[$i]: keeping original.";
      }
    }
    $pron = join(' ', @phones);
  }

  $pron =~ s/(\S+)/$1_SP/g if(defined($lang_tag));

  # Next, normalize the word:
  # Customising here for Acholi:
  next if ($word =~ /^\$|^$|^\(|^\)|<|>/);
  $word =~ s/\(.*\)//g;  # Pron variants should have same orthography
  $word =~ s/[=*@#]//g; # Get rid of special symbols
  if (defined($uppercase)) {
    $word = uc($word);
    $pron = uc($pron);
  } else {
    $word = lc($word);
    $pron = uc($pron);
  }

  # Note that this script does not check for duplicate entries!

  print "$word\t$pron\n";
}
