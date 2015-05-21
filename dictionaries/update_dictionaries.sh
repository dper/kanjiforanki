#!/bin/sh

# Get the kanji dictionary.
rm kanjidic2.xml
wget http://www.edrdg.org/kanjidic/kanjidic2.xml.gz
gunzip kanjidic2.xml.gz

# Get the word dictionary.
rm edict.txt
wget http://ftp.monash.edu.au/pub/nihongo/edict.zip
unzip edict.zip
iconv -f EUC-JP -t UTF-8 edict > edict.txt
rm edict edict.zip edict_doc.html edict.jdx

# Get the word frequency file.
rm wordfreq_ck.txt
wget ftp://ftp.edrdg.org/pub/Nihongo/wordfreq_ck.gz
gunzip wordfreq_ck.gz
iconv -f EUC-JP -t UTF-8 wordfreq_ck > wordfreq_ck.txt
rm wordfreq_ck

# Get the frequency file.

rm distribution.txt
wget ftp://ftp.edrdg.org/pub/Nihongo/edict_dupefree_freq_distribution.gz
gunzip edict_dupefree_freq_distribution.gz
mv edict_dupefree_freq_distribution distribution.txt
