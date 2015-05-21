#!/bin/sh

# This script generates lists for elementary and junior high school kanji study.

for list in 'elementary.1.txt' 'elementary.2.txt' 'elementary.3.txt' 'elementary.4.txt' 'elementary.5.txt' 'elementary.6.txt' 'elementary.txt' 'jhs.txt'
do
	echo '------------------------------------------'
	echo "Generating deck for ${list}..."
	cp lists/$list targetkanji.txt
	nice ./kanjiforanki.rb
	cp anki.txt decks/$list
done
