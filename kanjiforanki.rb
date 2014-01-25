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

	# Create a blank Kanji.
	def initialize_blank
		@literal = ' '
		@grade = ' '
		@stroke_count = ' '
		@meanings = []
		@onyomis = []
		@kunyomis = []
		@examples = []
	end

	# Given a character node from nokogiri XML, creates a Kanji.
	def initialize_kanji (node)
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
	end

	# Creates a kanji.  If no arguments are given, creates a blank kanji.
	def initialize *args
		case args.size
			when 0 then initialize_blank
			when 1 then initialize_kanji(args[0])
			else error
		end
	end

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
		@doc = Nokogiri::XML(open(path), nil, 'UTF-8')
	end

	# Returns the nodes of all kanji at the specified grade level.
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

	#TODO Write a function that looks up just one kanji.
end

# Reader for target kanji file.
class Targetkanji
	attr_accessor :kanjilist	# The target kanji.

	def lookup_characters (characters)
		kanjilist = []

		characters.each do |character|
			#TODO Find the kanji in kanjidic.
			kanji = Kanji.new(node)
			kanjilist << kanji
		end

		return kanjilist
	end

	def initialize
		verbose 'Parsing targetkanji.txt ...'
		path = Script_dir + '/targetkanji.txt'
		characters = IO.read path
		verbose 'Target characters: ' + characters

		#TODO Remove unwanted characters.

		verbose 'Looking up kanji ...'
		@kanjilist = lookup_characters(characters)	
	end
end

# For each Kanji, find several examples and add them to it.
def lookup_examples (kanjilist)
	verbose 'Looking up example words ...'
	for kanji in kanjilist
		kanji.lookup_examples
	end
end

# Find the frequencies of word use in the given list.
def find_example_frequencies (kanjilist)
	verbose 'Looking up example frequencies ...'
	millions, hundred_thousands, ten_thousands, thousands, hundreds, tens, ones = 0, 0, 0, 0, 0, 0, 0

	for kanji in kanjilist
		for example in kanji.examples
			case example.frequency
				when 1..9 then ones += 1
				when 10..99 then tens += 1
				when 100..999 then hundreds += 1
				when 1000..9999 then thousands += 1
				when 10000..99999 then ten_thousands += 1
				when 100000..999999 then hundred_thousands += 1
				else millions += 1
			end
		end
	end	

	total = millions + hundred_thousands + ten_thousands + thousands + hundreds + tens + ones

	verbose ' - 1,000,000+ = ' + millions.to_s
	verbose ' -   100,000+ = ' + hundred_thousands.to_s
	verbose ' -    10,000+ = ' + ten_thousands.to_s
	verbose ' -     1,000+ = ' + thousands.to_s
	verbose ' -       100+ = ' + hundreds.to_s
	verbose ' -        10+ = ' + tens.to_s
	verbose ' -         1+ = ' + ones.to_s
	verbose ' -      Total = ' + total.to_s
end

def make_deck
	$edict = Edict.new
	$wordfreq = Wordfreq.new
	$styler = Styler.new
	$kanjidic = Kanjidic.new
	$targetkanji = Targetkanji.new
	
	lookup_examples kanjilist
end

make_deck
