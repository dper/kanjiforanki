KanjiForAnki
============

This program takes a list of kanji and generates Anki flash cards for each them.

Objective
=========

This project is a script that takes a list of kanji as input and outputs a file that can be imported into Anki and used to study the given kanji.

Kanji are Japanese characters.  There are several thousand in existence.  Of those, roughly 2,000 are important for daily life in Japan.  English speakers learning Japanese often use SRS flash card systems to study.  One such program is Anki (<http://ankisrs.net/>).  People have created many different Anki decks for studying, but there are three drawbacks commonly encountered: the information is unreliable, the information is not freely licensed, or the information is not in the format you want.

Using this script, or rather, by modifying this script, you can customize flash card generation and produce cards you feel are particularly efficient for your studying needs.  The default settings are ones the author finds useful, so presumably you can use the script as-is, should you so desire.

Making the Anki deck
====================

This code is under the MIT License.  However, to make the script work, some more restrictive dependencies are needed.  Download the following files and put them in the same directory as this script.

The kanji dictionary and Japanese word dictionary are Creative Commons Attribution-Share Alike 3.0 licensed and can be downloaded here.

* <https://dperkins.org/2014/2014-01-24.kanjidic2.zip>
* <https://dperkins.org/2014/2014-01-24.edict.zip>

Or do this from the command line.

    wget https://dperkins.org/2014/2014-01-24.kanjidic2.zip
    unzip 2014-01-24.kanjidic2.zip
    wget https://dperkins.org/2014/2014-01-24.edict.zip
    unzip 2014-01-24.edict.zip

Next, modify the file `targetkanji.txt` so that it contains all of the kanji you want to appear in your Anki deck.  The file should consist of entirely kanji with no other characters whatsoever.


Importing the deck into Anki
============================

Once you have a deck you need to import it.

1. Open up Anki, go to `File / Import ...`  A dialog opens.
2. Select the text file you generated above.
3. Choose whatever options you like.  I prefer to create a separate deck for just these cards.
4. Make sure `Allow HTML in fields` is checked.
5. Make sure `Fields separated by: Tab` is displayed.
6. Click `Import`.  A dialog should open telling you everything worked.

To make the deck visually appealing, we need to modify the styling of it.

1. Browse to the deck.
2. Select a card from it.
3. Click on `Cards...`.  A style editing window opens.
4. We need to enter new styling information in the `Styling` box on the left side.  Some styling information is already specified.  Copy the contents of `style.css` below anything that's already there.
5. If you want to change the styling yourself, you can do it here at any time.

You are ready to go.  Have fun studying!


Sources
=======

The source code here is a modification of some code I wrote in 2011 to make paper flash cards for elementary school kanji.  Back then I didn't have a smart phone with SRS, and regardless, paper flash cards have their own strengths and weaknesses. <https://dperkins.org/arc/2011-03-22.kanji%20flashcards.html>

The kanji lists themselves are published by the Ministry of Education (MEXT) in Japan.  Other websites copy and paste the data from official MEXT documents.

* <http://www.mext.go.jp/a_menu/shotou/new-cs/youryou/syo/koku/001.htm>.  Elementary school kanji.
* <http://www.imabi.net/joyokanjilist.htm>.  Elementary and junior high school kanji.

The word frequency list is public domain and is included with the source.

* <http://ftp.monash.edu.au/pub/nihongo/00INDEX.html>.
* <http://www.bcit-broadcast.com/monash/wordfreq.README>.
* <http://ftp.monash.edu.au/pub/nihongo/wordfreq_ck.gz>.  Retrieved 2014-01-24.

The kanji dictionary and Japanese word dictionary are available from their original sources.  The original sources aren't in Unicode, but you can and should check there for updates and make the conversions yourself using a web browser and some copy and pasting.

* <http://www.csse.monash.edu.au/~jwb/kanjidic2/>.
* <http://www.csse.monash.edu.au/~jwb/kanjidic2/kanjidic2.xml.gz>.
* <http://www.csse.monash.edu.au/~jwb/edict.html>.
* <http://ftp.monash.edu.au/pub/nihongo/edict.gz>.
