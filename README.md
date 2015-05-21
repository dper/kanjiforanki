KanjiForAnki
============

This program takes a list of kanji and generates Anki flash cards for each them.


Objective
=========

This project is a script that takes a list of kanji as input and outputs a file that can be imported into Anki and used to study the given kanji.

Kanji are Japanese characters.  There are several thousand in existence.  Of those, roughly 2,000 are important for daily life in Japan.  English speakers learning Japanese often use SRS flash card systems to study.  One such program is [Anki](http://ankisrs.net/).  People have created many different Anki decks for studying, but there are three drawbacks commonly encountered: the information is unreliable, the information is not freely licensed, or the information is not in the format you want.

Using this script, or rather, by modifying this script, you can customize flash card generation and produce cards you feel are particularly efficient for your studying needs.  The default settings are ones the author finds useful, so presumably you can use the script as-is, should you so desire.


Getting Dependencies
====================

This code is under the MIT License.  However, to make the script work, some more restrictive dependencies are needed.  Download the following files and put them in the same directory as this script.

The kanji dictionary and Japanese word dictionary are Creative Commons Attribution-Share Alike 3.0 licensed and can be downloaded here.

* <http://www.edrdg.org/kanjidic/kanjidic2.xml.gz>
* <http://ftp.monash.edu.au/pub/nihongo/edict.zip>
* <ftp://ftp.edrdg.org/pub/Nihongo/wordfreq_ck.gz>

More simply, run `dictionaries/update_dictionaries.sh`.


Running the Script
==================

Modify the file `targetkanji.txt` so that it contains all of the kanji you want to appear in your Anki deck.  The file should consist of entirely kanji with no other characters whatsoever.  If you're looking for kanji lists, see `Joyo Kanji.txt`, which contains lists for all the elementary and junior high school kanji.

To run the script, simply call `kanjiforanki.rb`.  Here's an example of generating cards for first grade elementary school level kanji.

    $ ./kanjiforanki.rb 
    Parsing edict.txt ...
    Parsing wordfreq_ck.txt ...
    Parsing kanjidic2.xml ...
    Characters in kanjidic2: 13108.
    Parsing targetkanji.txt ...
    Target kanji count: 80.
    Target characters: 一右雨円王音下火花貝学気九休玉金空月犬見五口校左三山子四糸字耳七車手十出女小上森人水正生青夕石赤千川先早草足村大男竹中虫町天田土二日入年白八百文木本名目立力林六.
    Looking up kanji ...
    Found 80 kanji in kanjidic.
    Making the deck ...
    Writing the deck to anki.txt...
    Done writing.


Creating the Note Type
======================

Before importing the deck into Anki, it may be necessary to tell Anki what information it should be looking for during the import.  This is a little technical, but nothing tricky is going on, so have no fear.

* Click on `Tools / Manage Note Types...`.
* Create a new note type and call it "Kanji".  This can be done using `Add` followed by `Rename`.
* Click on `Fields` and create the following fields in the following order.  No other fields are desired.  Rename or remove them as necessary.
	* Literal
	* Strokes
	* Grade
	* Meaning
	* Meanings
	* Onyomis
	* Kunyomis
	* Examples
* That's all.  You now have a note type with eight fields: one for each piece of information that shows up on a kanji flash card.


Importing the Deck into Anki
============================

Once you have a deck you need to import it.

* Open up Anki.  Go to `File / Import ...`.  A dialog opens.
* Select the text file you generated above.
* Choose whatever options you like.  I prefer to create a separate deck for just these cards.
* Make sure `Allow HTML in fields` is checked.
* Make sure `Fields separated by: Tab` is displayed.
* There should be eight fields, and each should be mapped to one of the fields created above.  You should see the following.
````
Field 1 of file is: mapped to Literal
Field 2 of file is: mapped to Strokes
Field 3 of file is: mapped to Grade
Field 4 of file is: mapped to Meaning 
Field 5 of file is: mapped to Meanings
Field 6 of file is: mapped to Onyomis
Field 7 of file is: mapped to Kunyomis
Field 8 of file is: mapped to Examples
````
* Click `Import`.  A dialog should open telling you everything worked.

That's all it takes to import the cards.



Styling the Deck
================
To make the deck visually appealing, we need to modify the styling of it.

* Browse to the deck.
* Select a card from it.
* Click on `Cards...`.  A style editing window opens.
* We need to enter new styling information in the `Styling` box on the left side.
* By default, only two of the eight information fields are displayed.  We need to enable the other six....
* In `Front Template`, enter the following.
````HTML
<span class="literal">{{Literal}}</span>
<span class="strokes">{{Strokes}}</span>
<span class="grade">{{Grade}}</span>
````
* In `Styling`, enter the following.
````CSS
.card {
font-family: arial;
font-size: 30px;
text-align: center;
color: black;
background-color: white;
}

.literal {
color: blue;
font-size: 200%;
}

.strokes {
float: left;
font-size: 75%;
color: #ff66ff;
}

.grade {
float: right;
font-size: 75%;
color: gray;
}

.meaning {
color: green;
}

.meanings {
color: #6699cc;
}

.onyomis {
color: orange;
font-size: 75%;
}

.kunyomis {
color: red;
font-size: 75%;
}

.examples {
font-size: 75%;
}
````
* In `Back Template`, enter the following.
````HTML
{{FrontSide}}

<hr id=answer>

<div class="meaning">{{Meaning}}</div>
<div class="meanings">{{Meanings}}</div>
<div class="onyomis">{{Onyomis}}</div>
<div class="kunyomis">{{Kunyomis}}</div>
<div class="examples">{{Examples}}</div>
````
You are ready to go.  Have fun studying!


Source
======

* Browse: <https://dperkins.org/git/gitlist/kanjiforanki.git/>.
* Clone: <https://dperkins.org/git/public/kanjiforanki.git/>.
* GitHub: <https://github.com/dper/kanjiforanki/>.


Contact
=======

If you want to contact the author, here are some ways.  Bug reports and improvements are always welcome.

* <https://microca.st/dper>
* <https://twitter.com/dpp0>
* <https://dperkins.org/tag/contact.html>


Kanji Lists
===========

The kanji lists themselves are published by the Ministry of Education (MEXT) in Japan.  Other websites copy and paste the data from official MEXT documents.

* <http://www.mext.go.jp/a_menu/shotou/new-cs/youryou/syo/koku/001.htm>.  Elementary school kanji.
* <http://www.imabi.net/joyokanjilist.htm>.  Elementary and junior high school kanji.

The word frequency list is public domain and is included with the source.

* <ftp://ftp.edrdg.org/pub/Nihongo/00INDEX.html>.
* <ftp://ftp.edrdg.org/pub/Nihongo/wordfreq.README>.
* <ftp://ftp.edrdg.org/pub/Nihongo/wordfreq_ck.gz>.  Retrieved 2014-01-24.

The kanji dictionary and Japanese word dictionary are available from their original sources.  The original sources aren't in Unicode, but you can and should check there for updates and make the conversions yourself using a web browser and some copy and pasting.

* <ftp://ftp.edrdg.org/pub/Nihongo/kanjidic2_ov.html>.
* <ftp://ftp.edrdg.org/pub/Nihongo/kanjidic2.xml.gz>.
* <ftp://ftp.edrdg.org/pub/Nihongo/edict_doc.html>.
* <ftp://ftp.edrdg.org/pub/Nihongo/edict.gz>.


Contributions
=============

Thanks to **jfsantos** for the regular expressions that remove hiragana and katakana.
