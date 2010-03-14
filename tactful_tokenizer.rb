require "word_tokenizer.rb"
require "andand"
include WordTokenizer

# TODO: More documentation.
####### Performance TODOs.
# Use inline C where necessary?

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

    # Feats is a huge dictionary of feature probabilities.
    # lower_words and non_abbrs are word occurences counted logarithmically.
    attr_accessor :feats, :lower_words, :non_abbrs

    # Assign a prediction (probability, to be precise) to each
    # sentence fragment.
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
        w1 = (frag.cleaned.split.last or '')
        w2 = (frag.next or '')

        frag.features = ["w1_#{w1}", "w2_#{w2}", "both_#{w1}_#{w2}"]

        if not w2.empty? and w1.chop.is_alphabetic? 
            frag.features.push "w1length_#{[10, w1.length].min}"
            frag.features.push "w1abbr_#{model.non_abbrs[w1.chop]}"
        end

        if not w2.empty? and w2.chop.is_alphabetic?
            frag.features.push "w2cap_#{w2[0].is_upper_case?}"
            frag.features.push "w2lower_#{model.lower_words[w2.downcase]}"
        end
    end

    def featurize(doc)
        frag = nil
        doc.frags.each do |frag|
            get_features(frag, self)
        end
    end

    def tokenize_text(text)
        data = Doc.new(text)
        featurize(data)
        classify(data)
        return data.segment
    end
end

class Doc
    attr_accessor :frags
    def initialize(text)
        @frags = []
        res = nil

        text.scan(/(.*?\w[.!?]["')\]}]*)\s+|(.*$)/) do |res|
            if res[1].nil?
                frag = Frag.new(res[0])
            else
                frag = Frag.new(res[1])
                frag.ends_seg = true
            end
            @frags.last.next = frag.cleaned.split.first unless @frags.empty?
            @frags.push frag
        end
    end

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

class Frag
    attr_accessor :orig, :next, :ends_seg, :cleaned, :pred, :features
    def initialize(orig='', ends_seg=false)
        @orig = orig
        clean(orig)
        @next, @pred, @features = nil, nil, nil
        @ends_seg = ends_seg
    end

    # Normalizes numbers and discards ambiguous punctuation.
    def clean(s)
        @cleaned = String.new(s)
        tokenize(@cleaned)
        @cleaned.gsub!(/[.,\d]*\d/, '<NUM>')
        @cleaned.gsub!(/[^a-zA-Z0-9,.;:<>\-'\/$% ]/, '')
        @cleaned.gsub!('--', ' ')
    end
end
