#!/usr/bin/ruby
# coding: utf-8
#
# == NAME
# wordfreq.rb
#
# == USAGE
# Load as a library.
#
# == DESCRIPTION
# A library that gives information about word frequency.
# A properly formatted distribution.txt file nust be in place.
# 
# == AUTHOR
#   Douglas Perkins - https://dperkins.org - https://microca.st/dper

# Word frequency list.  Words that are too short or too long are excluded.
class Wordfreq
	# The maximum kanji count for a sample word.
	Max_example_word_width = 3

	# Creates a Wordfreq.
	def initialize
		puts 'Parsing distribution.txt ...'
		path = Script_dir + '/dictionaries/distribution.txt'
		wordfreq = IO.readlines path
		wordfreq.keep_if {|line| line =~ /^\d+\t.*/}
		wordfreq.keep_if {|line| line.include? "\t"}
		wordfreq.delete_if {|line|
			word = line.split[4].split('|')[0]
			length = word.scan(/./u).length
			length < 2 or length > Max_example_word_width
		}

		puts 'Usable words in distribution.txt: ' + wordfreq.size.to_s + '.'
	
		@lookup_table = {}
		
		wordfreq.each do |line|
			word = line.split[4].split('|')[0]
			frequency = line.split[1]
			pair = [word, frequency]

			word.scan(/./u).each do |char|
				if not @lookup_table.key? char
					@lookup_table[char] = [pair]
				else
					@lookup_table[char] << pair
				end
			end
		end
	end

	# Returns a list of lines in Wordfreq that contain the kanji.
	# Words in this list are sorted most to least common.
	def lookup kanji
		return @lookup_table[kanji]
	end

	# Returns true if the kanji is in this word list, and false otherwise.
	def include? kanji
		return @lookup_table.key? kanji
	end
end
