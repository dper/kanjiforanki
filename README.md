KanjiForAnki
============

This program takes a list of kanji and generates Anki flash cards for each them.

Objective
=========

This project is a script that takes a list of kanji as input and outputs a file that can be imported into Anki and used to study the given kanji.

Kanji are Japanese characters.  There are several thousand in existence.  Of those, roughly 2,000 are important for daily life in Japan.  English speakers learning Japanese often use SRS flash card systems to study.  One such program is Anki (<http://ankisrs.net/>).  People have created many different Anki decks for studying, but there are three drawbacks commonly encountered: the information is unreliable, the information is not freely licensed, or the information is not in the format you want.

Using this script, or rather, by modifying this script, you can customize flash card generation and produce cards you feel are particularly efficient for your studying needs.  The default settings are ones the author finds useful, so presumably you can use the script as-is, should you so desire.

Dependencies
============
The code here is under the MIT License but to make the script work, some more restrictive dependencies are needed.  Download the following two files and put them in the same directory as this script.  They are both Creative Commons Attribution-Share Alike 3.0 licensed.

The kanji dictionary is Creative Commons Attribution-Share Alike 3.0 licensed and can be downloaded here.

* <http://www.csse.monash.edu.au/~jwb/kanjidic2/>.
* <http://www.csse.monash.edu.au/~jwb/kanjidic2/kanjidic2.xml.gz>.

The Japanese word dictionary is also Creative Commons Attribution-Share Alike 3.0 licensed and can be downloaded here.

* <http://www.csse.monash.edu.au/~jwb/edict.html>.
* <http://ftp.monash.edu.au/pub/nihongo/edict.gz>.

Sources
=======

The kanji lists themselves are published by the Ministry of Education (MEXT) in Japan.  Other websites copy and paste the data from official MEXT documents.

* <http://www.mext.go.jp/a_menu/shotou/new-cs/youryou/syo/koku/001.htm>.  Elementary school kanji.
* <http://www.imabi.net/joyokanjilist.htm>.  Elementary and junior high school kanji.

The word frequency list is public domain and is included with the source.

* <http://ftp.monash.edu.au/pub/nihongo/00INDEX.html>.
* <http://www.bcit-broadcast.com/monash/wordfreq.README>.
* <http://ftp.monash.edu.au/pub/nihongo/wordfreq_ck.gz>.  Retrieved 2014-01-24.