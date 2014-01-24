# coding: utf-8
#!/usr/bin/ruby
#
# == NAME
# kanjiforanki.rb
#
# == USAGE
#  ./kanjiforanki.rb [ -h | --help ]
#                    [ -v | --verbose ]
#                    [ -l | --letter ]
#                    [ -g | --grade ] grade level
#                    [ -j | --jlpt ] jlpt level
#                    [ -a | --all ]
#
# == DESCRIPTION
# Takes a list of kanji as input and outputs a file that can be imported into
# Anki and used to study the given kanji.
# 
# This script depends on several files having proper formatting located
# in the same directory.  See COPYING for file source information.
#
# == OPTIONS
#  -h,--help::		Show help.
#  -l,--letter::	Use letter paper (default: A4).
#  -i,--input::	The input kanji file.
#
# == EXAMPLES
#   This is how to generate flashcards for the contents of "kanji.txt".
#     cardmaker.rb --input kanji.txt
#
# == AUTHOR
#   Douglas P Perkins - https://dperkins.org - https://microca.st/dper

require 'benchmark'
require 'nokogiri'
require 'singleton'

$verbose = true

# Displays an error message if the verbose tag is specified.
def verbose (message)
	if $verbose
		puts message
	end
end

Script_dir = File.dirname(__FILE__)

# A few extra functions for Arrays.
class Array
	# Splits an Array into smaller Arrays of size n.
	def chunk n
		each_slice(n).reduce([]) {|x,y| x += [y] }
	end

	# Returns the array minus the lead element, or [] if not possible.
	def rest
		case self.size
			when 0..1 then []
			else self[1..-1]
		end
	end
end

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

# Given a bunch of kanji, produces an odg flashcard file.
class Odg_maker
	Cards_per_page = 12   # This must match blankcard.fodg.
	Max_reading_size = 55 # Max character width for onyomi and kunyomi lines.
	Max_meaning_size = 50 # Max character width for the meaning line.

	# Creates an odg maker for this kanjiset.  The options should be a hash
	# with entries for:
	# 'type' => 'jlpt' or 'grade'
	# --- If 'type' => 'jlpt', then 'level' => '1', '2', '4', or '5'
	# --- If 'type' => 'grade', then 'grade' => '1' ... '9'
	# 'paper' => 'a4' or 'letter'
	def initialize (kanjilist, card_options)
		@kanjilist = kanjilist
		@card_type = card_options['card_type']
		@paper = card_options['paper']

		case @paper
		when 'a4' then blankcard = 'blankcard.a4.fodg' 
		when 'letter' then blankcard = 'blankcard.letter.fodg'
		else raise 'Invalid paper.'
		end
			
		@doc = Nokogiri::XML(open(Script_dir + '/' + blankcard), nil, 'UTF-8')
		drawing = @doc.at_xpath '//office:body/office:drawing'

		# The template pages.
		@front = drawing.at_xpath './draw:page[@draw:name = "Front"]'
		@back = drawing.at_xpath './draw:page[@draw:name = "Back"]'
		@license = drawing.at_xpath './draw:page[@draw:name = "License"]'

		case @card_type
		when 'jlpt'
			@level = card_options['level']
			if @level.to_i > 5 then raise 'Invalid level: ' + @level + '.' end
			if @level.to_i < 1 then raise 'Invalid level: ' + @level + '.' end
		when 'grade'
			@grade = card_options['grade']
			if @grade.to_i > 9 then raise 'Invalid grade: ' + @grade + '.' end
			if @grade.to_i < 1 then raise 'Invalid grade: ' + @grade + '.' end
		else
			raise "Error: Type must be 'jlpt' or 'school'."
		end
	end

	# Writes the file.	
	def write_file
		verbose 'Writing the fodg file ...'

		ending = '.' + @paper + '.fodg'
		case @card_type
		when 'grade'
			dir = Script_dir + '/grade/'
			path = dir + 'flashcards.grade_' + @grade.to_s + ending
		when 'jlpt'
			dir = Script_dir + '/jlpt/'
			path = dir + 'flashcards.jlpt_' + @level.to_s + ending
		end

		File.open(path, 'w') do |file|
			@doc.write_xml_to file
		end
	end

	# Writes the actual literal where L is.
	def write_literal (card, literal)
		query = "./draw:frame/svg:title[text()='literal']"
		title = card.at_xpath query
		node = title.parent.at_xpath './draw:text-box/text:p'
		new_node = node.clone()
		new_node.content = literal
		node.replace new_node
	end

	# Writes the (JLPT or grade) level where L is.
	def write_level (card, literal)
		if literal != ' '
			case @card_type
			when 'grade'
				if Integer(@grade) <= 6
					level = '小' + @grade
				else
					level = 'G' + @grade
				end
			when 'jlpt'
				level = 'N' + @level
			end
		end

		query = "./draw:frame/svg:title[text()='level']"
		title = card.at_xpath query
		node = title.parent.at_xpath './draw:text-box/text:p'
		new_node = node.clone()
		new_node.content = level
		node.replace new_node
	end

	# Writes the actual stroke count where S is.
	def write_stroke_count (card, stroke_count)
		query = "./draw:frame/svg:title[text()='stroke_count']"
		title = card.at_xpath query
		node = title.parent.at_xpath './draw:text-box/text:p'
		new_node = node.clone()
		new_node.content = stroke_count
		node.replace(new_node)
	end

	# Makes the front of the page.
	def make_front (page_kanji)
		page_front = @front.dup
		
		page_kanji.each_with_index {|kanji, i|
			card_query = "./draw:g/svg:title[text()='front" + (i + 1).to_s + "']"
			card = page_front.at_xpath(card_query).parent
			write_literal(card, kanji.literal)
			write_level(card, kanji.literal)
			write_stroke_count(card, kanji.stroke_count)		
		}

		return page_front
	end

	# Writes the actual English word where ENGLISH is.
	def write_english (card, english)
		if not english then english = ' ' end
		query = "./draw:frame/svg:title[text()='english']"
		title = card.at_xpath(query)
		node = title.parent.at_xpath('./draw:text-box/text:p')
		new_node = node.clone()
		new_node.content = english.upcase
		node.replace(new_node)
	end

	# Writes the actual meanings where MEANING is.
	def write_meaning (card, meanings)
		s = ''

		meanings.each do |meaning|
			if s.size + meaning.size > Max_meaning_size
				s += '…'
				break
			end
			s += meaning + ' - '
		end
		s.chomp!(' - ')
		if s.size == 0 then s = ' ' end

		query = "./draw:frame/svg:title[text()='meaning']"
		title = card.at_xpath(query)
		node = title.parent.at_xpath('./draw:text-box/text:p')
		new_node = node.clone()
		new_node.content = s
		node.replace(new_node)
	end

	# Writes the actual onyomi readings where ONYOMI is.
	def write_onyomi (card, onyomis)
		s = ''
		
		onyomis.each do |onyomi|
			if s.size + onyomi.size > Max_reading_size
				s += '…'
				break
			end
			s += onyomi + '　'
		end
		if s.size == 0 then s = ' ' else s.chomp!('　') end

		query = "./draw:frame/svg:title[text()='onyomi']"
		title = card.at_xpath query
		node = title.parent.at_xpath './draw:text-box/text:p'
		new_node = node.clone
		new_node.content = s
		node.replace new_node
	end

	# Writes the actual kunyomi readings where KUNYOMI is.
	def write_kunyomi (card, kunyomis)
		s = ''
		
		for kunyomi in kunyomis
			if s.size + kunyomi.size > Max_reading_size
				s += '…'
				break
			end
			s += kunyomi + '　'
		end
		if s.size == 0 then s = ' ' else s.chomp!('　') end

		query = "./draw:frame/svg:title[text()='kunyomi']"
		title = card.at_xpath query
		node = title.parent.at_xpath './draw:text-box/text:p'
		new_node = node.clone
		new_node.content = s
		node.replace new_node

	end

	# Writes the actual examples where EXAMPLES is.
	def write_examples (card, examples)
		lines = []

		examples.each do |ex|
			lines << ex.word + ' (' + ex.kana + ') - ' + ex.meaning
		end
		
		query = "./draw:frame/svg:title[text()='examples']"
		title = card.at_xpath(query)
		node = title.parent.at_xpath('./draw:text-box/text:p')
		
		lines.reverse.each do |line|
			new_node = node.clone()
			new_node.content = line
			node.add_next_sibling new_node
		end

		node.remove
	end

	def make_back (page_kanji)
		page_back = @back.dup
		
		page_kanji.each_with_index do |kanji, i|
			card_query = "./draw:g/svg:title[text()='back" + (i + 1).to_s + "']"
			card = page_back.at_xpath(card_query).parent
			english = kanji.meanings.first
			write_english(card, english)
			write_meaning(card, kanji.meanings.rest)
			write_onyomi(card, kanji.onyomis)		
			write_kunyomi(card, kanji.kunyomis)		
			write_examples(card, kanji.examples)		
		end

		return page_back
	end

	# Makes pages for the fodg file.
	def make_pages
		verbose 'Making fodg pages ...'

		# Pad the list to make it a multiple of Cards_per_page.
		while (@kanjilist.size % Cards_per_page) > 0
			@kanjilist << Kanji.new
		end

		# Split into pages and make each page separately.
		for page_kanji in @kanjilist.chunk(Cards_per_page)
			@license.add_previous_sibling(make_front(page_kanji))
			@license.add_previous_sibling(make_back(page_kanji))	
		end

		# Remove the template pages.
		@front.remove
		@back.remove
	end
	
	# Makes an fodg file with flashcards.
	def make_flashcards
		verbose 'Making fodg file ...'
		make_pages
		write_file
	end
end

# Reader for kanjidic2.
class Kanjidic2
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
	#TODO Load the kanji list.
	kanjilist = ''
	
	lookup_examples kanjilist
	odg_maker = Odg_maker.new(kanjilist, card_options)
	odg_maker.make_flashcards
	if $verbose then find_example_frequencies kanjilist end
end

# Parse the input and do something with it.
options = OpenStruct.new()
opts = OptionParser.new()
opts.on('-h', '--help', 'Display the usage information') {RDoc::usage}
opts.on('-i', '--input', '=INPUT", "Input') { |argument| options.input = argument }
opts.parse! rescue RDoc::usage('usage')

if options.input
	$edict = Edict.new
	$wordfreq = Wordfreq.new
	$styler = Styler.new
	$kanjidic2 = Kanjidic2.new

	#TODO Do stuff here.

else
	RDoc::usage()
end