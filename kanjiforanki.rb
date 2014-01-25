# coding: utf-8
#!/usr/bin/ruby
#
# == NAME
# kanjiforanki.rb
#
# == USAGE
# ./kanjiforanki.rb
#
# == DESCRIPTION
# Takes a list of kanji as input and outputs a file that can be imported into
# Anki and used to study the given kanji.
# 
# This script depends on several files having proper formatting located
# in the same directory.  See COPYING for file source information.
#
# == AUTHOR
#   Douglas P Perkins - https://dperkins.org - https://microca.st/dper

require 'nokogiri'

$verbose = true

# Displays an error message if the verbose tag is specified.
def verbose (message)
	if $verbose
		puts message
	end
end

Script_dir = File.dirname(__FILE__)

# Fixes style quirks in Edict.
class Styler
	def initialize
		# For readability here, sort by lower case, then by initial
		# letter capitalized, then by all caps, then by phrases to
		# remove.
		@lookup_table = {
			'acknowledgement' => 'acknowledgment',
			'aeroplane' => 'airplane',
			'centre' => 'center',
			'colour' => 'color',
			'defence' => 'defense',
			'e.g. ' => 'e.g., ',
			'economising' => 'economizing',
			'electro-magnetic' => 'electromagnetic',
			'favourable' => 'favorable',
			'favourite' => 'favorite',
			'honour' => 'honor',
			'i.e. ' => 'i.e., ',
			'judgement' => 'judgment',
			'lakeshore' => 'lake shore',
			'metre' => 'meter',
			'neighbourhood' => 'neighborhood',
			'speciality' => 'specialty',
			'storeys' => 'stories',
			'theatre' => 'theater',
			'traveller' => 'traveler',
			'Ph.D' => 'PhD',
			'Philipines' => 'Philippines',
			'JUDGEMENT' => 'JUDGMENT',
			'(kokuji)' => 'kokuji',
			' (endeavour)' => '',
			' (labourer)' => '',
			' (theater, theater)' => '(theater)',
			' (theatre, theater)' => '(theater)',
		}
	end

	# Returns re-styled text.
	def fix_style text
		@lookup_table.keys.each do |key|
			text = text.sub(key, @lookup_table[key])
		end

		return text
	end
end

# Word frequency list.  Words that are too short or too long are excluded.
class Wordfreq
	# The maximum kanji count for a sample word.
	Max_example_word_width = 3

	# Creates an Edict.
	def initialize
		verbose 'Parsing wordfreq_ck.txt ...'
		path = Script_dir + '/wordfreq_ck.txt'
		wordfreq = IO.readlines path
		wordfreq.delete_if {|line| line.start_with? '#'}
		wordfreq.delete_if {|line| not line.include? "\t"}
		wordfreq.delete_if {|line|
			word = line.split[0]
			length = word.scan(/./u).length
			length < 2 or length > Max_example_word_width
		}

		@lookup_table = {}
		
		wordfreq.each do |line|
			line.split[0].scan(/./u).each do |char|
				if not @lookup_table.key? char
					@lookup_table[char] = [line]
				else
					@lookup_table[char] << line
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

# Looks up words in Edict.
class Edict
	# Creates an Edict.  Parsing the edict file takes a long time,
	# so it is desirable to only make one of this.
	def initialize
		verbose 'Parsing edict.txt ...'
		path = Script_dir + '/edict.txt'
		edict = IO.readlines path
		@lookup_table = {}
		
		edict.each do |line|
			# Lines with definitions start with the word, followed
			# by a blank line, followed by the definition.  If
			# there is more than one definition, the first one is
			# used.
			next unless line.include? " "
			word, blank, definition = line.partition " "
			next if @lookup_table.key? word
			@lookup_table[word] = definition
		end
	end

	# Looks up a word, returning its kana and definition.  Returns nil iff
	# the word is not in the dictionary.
	def define word
		# Definitions are stored in @lookup_table, which is indexed by
		# the words.  The definition starts with the reading in
		# parentheses, followed by one or more definitions, as well as
		# grammatical terms.  Only the first definition is used here.
		definition = @lookup_table[word]
		if not definition then return nil end
		kana = definition.partition('[')[2].partition(']')[0]
		meaning = definition.partition('/')[2]
		meaning = meaning.partition('/')[0].lstrip
		while meaning.start_with? '('
			meaning = meaning.partition(')')[2].lstrip
		end

		meaning = $styler.fix_style meaning
		return [kana, meaning]
	end
end

# An example word, written in kanji (plus kana), kana, and English.
class Example
	attr_accessor :word      # Word, using kanji and maybe kana.
	attr_accessor :kana      # Kana.
	attr_accessor :meaning   # English meaning.
	attr_accessor :frequency # Word frequency.

	# Creates an Example for a given word.
	def initialize (word, frequency)
		@word = word
		@frequency = Integer(frequency)
	end
	
	# Looks up the kana and English for the kanji word.
	# Returns true if the definition is found, and false otherwise.
	def lookup_definition
		definition = $edict.define @word
		if not definition then return false end
		@kana, meaning = definition
		meaning = $styler.fix_style meaning
		@meaning = meaning
		return true
	end
end

# A kanji character and all relevant details.
class Kanji
	attr_accessor :literal      # The character.
	attr_accessor :grade        # School grade level.
	attr_accessor :stroke_count # Stroke count.
	attr_accessor :meanings     # One or more meanings.
	attr_accessor :onyomis      # Zero or more kunyomi readings.
	attr_accessor :kunyomis     # Zero or more onyomi readings.
	attr_accessor :examples     # Example list.

	Max_example_count = 3 # The maximum number of examples to store.
	Max_example_size = 50 # Max example width.

	# Look up examples of word use and record them.
	def lookup_examples
		@examples = []
		return unless $wordfreq.include? @literal
		$wordfreq.lookup(@literal).each do |line|
			word,frequency = line.split
			ex = Example.new(word, frequency.strip)
		
			# Only keep examples that are in the dictionary.
			next unless ex.lookup_definition
			ex_size = (ex.word + ex.kana + ex.meaning).size
			next if ex_size > Max_example_size
			@examples << ex
			break if @examples.size == Max_example_count
		end
	end

	# Given a character node from nokogiri XML, creates a Kanji.
	def initialize (node)
		@literal = node.css('literal').text
		@grade = node.css('misc grade').text
		@stroke_count = node.css('misc stroke_count')[0].text

		rmgroup = node.css('reading_meaning rmgroup')

		# Parse the meanings.
		@meanings = []
		rmgroup.css('meaning').each do |meaning|
			if !meaning['m_lang']
				@meanings << ($styler.fix_style meaning.text)
			end
		end

		# Parse the readings.
		@onyomis = []
		@kunyomis = []
		rmgroup.css('reading').each do |reading|
			if reading['r_type'] == 'ja_on'
				onyomis << reading.text
			elsif reading['r_type'] == 'ja_kun'
				kunyomis << reading.text
			end
		end
		
		lookup_examples
	end
end

# Reader for kanjidic2.
class Kanjidic
	def initialize
		verbose 'Parsing kanjidic2.xml ...'
		path = Script_dir + '/kanjidic2.xml'
		@doc = Nokogiri::XML(open(path), nil, 'UTF-8')
	end

	# Returns the nodes of all kanji at the specified grade level.
	#TODO Replace this function with a better one.
	def get_grade (grade)
		verbose 'Filtering kanjidic2 for grade ' + grade + ' ...'
		kanjilist = []
		@doc.xpath('kanjidic2/character').each do |node|
			# If it's the right grade keep it.
			if node.css('misc grade').text == grade
				kanjilist << Kanji.new(node)
			end
		end
		return kanjilist
	end
end

# Reader for kanjidic2.
class Kanjidic
	def initialize
		verbose 'Parsing kanjidic2.xml ...'
		path = Script_dir + '/kanjidic2.xml'
		doc = Nokogiri::XML(open(path), nil, 'UTF-8')
		@characters = {}
		doc.xpath('kanjidic2/character').each do |node|
			character = node.css('literal').text
			@characters.store(character, node)
		end
		
		verbose "Characters in kanjidic2: " + @characters.size.to_s + "."
	end

	# Returns a node for the specified characters.
	# If any characters are not in the dictionary, they are skipped.
	def get_kanji (characters)
		kanjilist = []
		
		characters.split("").each do |c|
			if @characters[c]
				kanjilist << Kanji.new(@characters[c])
			else
				verbose "Character not found in kanjidic: " + c + "."
			end	
		end
		
		return kanjilist		
	end
end

# Reader for target kanji file.
class Targetkanji
	attr_accessor :kanjilist	# The target kanji.

	def lookup_characters (characters)
		@kanjilist = $kanjidic.get_kanji(characters)
		verbose 'Found ' + @kanjilist.size.to_s + ' kanji in kanjidic.'
	end

	# Removes unwanted characters from the list.
	# This is a rather weak filter, but it catches the most obvious problems.
	def remove_unwanted_characters(characters)
		characters = characters.gsub(/[[:ascii:]]/, '')
		characters = characters.gsub(/[[:blank:]]/, '')
		characters = characters.gsub(/[[:cntrl:]]/, '')
		characters = characters.gsub(/[[:punct:]]/, '')
		return characters	
	end

	def initialize
		verbose 'Parsing targetkanji.txt ...'
		path = Script_dir + '/targetkanji.txt'
		characters = IO.read path

		characters = remove_unwanted_characters(characters)

		verbose 'Target kanji count: ' + characters.size.to_s + '.'
		verbose 'Target characters: ' + characters + '.'
		verbose 'Looking up kanji ...'
		lookup_characters(characters)	
	end
end

def make_deck
	# Read all of the files and data.
	$edict = Edict.new
	$wordfreq = Wordfreq.new
	$styler = Styler.new
	$kanjidic = Kanjidic.new
	$targetkanji = Targetkanji.new
	
	#TODO Do something here.
end

make_deck
