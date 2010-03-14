require "word_tokenizer.rb"
require "andand"
include WordTokenizer

####### Performance TODOs.
# TODO: Use inline C where necessary?
# TODO: Use RE2 regexp extension.

String.class_eval do
    # Simple regex to check if a string is alphabetic.
    def is_alphabetic?
        return !/[^A-Z]/i.match(self)
    end
    # Simple regex to check if a string is in uppercase.
    def is_upper_case?
        self == self.upcase ? 'True' : 'False'
    end
end

# A model stores normalized probabilities of different features occuring.
class Model
    # Initialize the model. feats, lower_words, and non_abbrs
    # indicate the locations of the respective Marshal dumps.
    def initialize(feats="feats_s.mar", lower_words="lower_words_s.mar", non_abbrs="non_abbrs_s.mar")
        @feats, @lower_words, @non_abbrs = [feats, lower_words, non_abbrs].map do |file|
            File.open(file) do |f|
                Marshal.load(f.read)
            end
        end
        @p0 = @feats["<prior>"] ** 4  
    end

    # feats = {feature => normalized probability of feature}
    # lower_words = {token => log count of occurences in lower case}
    # non_abbrs = {token => log count of occurences when not an abbrv.}
    attr_accessor :feats, :lower_words, :non_abbrs

    # This function is the only one that'll end up being used.
    # m = Model.new
    # m.tokenize_text("Hey, are these two sentences? I bet they should be.")
    # => ["Hey, are these two sentences?", "I bet they should be."]
    def tokenize_text(text)
        data = Doc.new(text)
        featurize(data)
        classify(data)
        return data.segment
    end

    # Assign a prediction (probability, to be precise) to each sentence fragment.
    # For each feature in each fragment we hunt up the normalized probability and
    # multiply. This is a fairly straightforward Bayesian probabilistic algorithm.
    def classify(doc)
        frag = nil
        probs = 1
        feat = ''
        doc.frags.each do |frag|
            probs = @p0
            frag.features.each do |feat|
                probs *= @feats[feat]
            end
            frag.pred = probs / (probs + 1)
        end
    end

    # Get the features of every fragment.
    def featurize(doc)
        frag = nil
        doc.frags.each do |frag|
            get_features(frag, self)
        end
    end

    # Finds the features in a text fragment of the form:
    # ... w1. (sb?) w2 ...
    # Features listed in rough order of importance:
    # * w1: a word that includes a period.
    # * w2: the next word, if it exists.
    # * w1length: the number of alphabetic characters in w1.
    # * both: w1 and w2 taken together.
    # * w1abbr: logarithmic count of w1 occuring without a period.
    # * w2lower: logarithmiccount of w2 occuring lowercased.
    # * w1w2upper: true if w1 and w2 are capitalized.
    def get_features(frag, model)
        w1 = (frag.cleaned.last or '')
        w2 = (frag.next or '')

        frag.features = ["w1_#{w1}", "w2_#{w2}", "both_#{w1}_#{w2}"]

        if not w2.empty?
            if w1.chop.is_alphabetic? 
                frag.features.push "w1length_#{[10, w1.length].min}"
                frag.features.push "w1abbr_#{model.non_abbrs[w1.chop]}"
            end

            if w2.chop.is_alphabetic?
                frag.features.push "w2cap_#{w2[0].is_upper_case?}"
                frag.features.push "w2lower_#{model.lower_words[w2.downcase]}"
            end
        end
    end
end

# A document represents the input text. It holds a list of fragments generated
# from the text.
class Doc
    attr_accessor :frags

    # Receives a text, which is then broken into fragments.
    # A fragment ends with a period, quesetion mark, or exclamation mark followed
    # possibly by right handed punctuation like quotation marks or closing braces
    # and trailing whitespace. Failing that, we'll accept something like "I hate cheese\n"
    # No, it doesn't have a period, but it's pretty likely to be a sentence.
    def initialize(text)
        @frags = []
        res = nil

        text.scan(/(.*?\w[.!?]["')\]}]*)\s+|(.*)\s*/) do |res|
            if res[0]
                frag = Frag.new(res[0])
            else
                frag = Frag.new(res[1], true)
            end
            @frags.last.next = frag.cleaned.first unless @frags.empty?
            @frags.push frag
        end
    end

    # Segments the text. More accurately, it reassembles the fragments into sentences.
    # We call something a sentence whenever it is more likely to be a sentence than not.
    def segment
        sents, sent = [], []
        thresh = 0.5

        frag = nil
        @frags.each do |frag|
            sent.push(frag.orig)
            if frag.pred > thresh or frag.ends_seg
                break if frag.orig.nil?
                sents.push(sent.join(' '))
                sent = []
            end
        end
        sents
    end
end

# A fragment is a potential sentence, but is based only on the existence of a period.
# The text "Here in the U.S. Senate we prefer to devour our friends." will be split
# into "Here in the U.S." and "Senate we prefer to devour our friends.", but will later
# be correctly merged into a single sentence (because 'U.S.' and 'Senate' frequently
# follow each other in sentences, according to the data model). The algorithm does
# not employ any sort of "Hey, look, that fragment has no subject"-voodoo. If only.
class Frag
    attr_accessor :orig, :next, :ends_seg, :cleaned, :pred, :features
    def initialize(orig='', ends_seg=false)
        @orig = orig
        clean(orig)
        @next, @pred, @features = nil, nil, nil
        @ends_seg = ends_seg
    end

    # Normalizes numbers and discards ambiguous punctuation. And then splits into an
    # array, because realistically only the last and first words are ever accessed.
    def clean(s)
        @cleaned = String.new(s)
        tokenize(@cleaned)
        @cleaned.gsub!(/[.,\d]*\d/, '<NUM>')
        @cleaned.gsub!(/[^a-zA-Z0-9,.;:<>\-'\/$% ]/, '')
        @cleaned.gsub!('--', ' ')
        @cleaned = @cleaned.split
    end
end
