require "word_tokenizer.rb"
require "andand"
include WordTokenizer

# TODO: More documentation.
# TODO: DRY up accessors.
####### Performance TODOs.
# Use inline C where necessary?

String.class_eval do
    def is_alphabetic?
        return !/[^A-Z]/i.match(self)
    end
    def is_upper_case?
        return !/[^A-Z]/.match(self)
    end
end

class Model
    def initialize(feats="feats_s.mar", lower_words="lower_words_s.mar", non_abbrs="non_abbrs_s.mar")
        @feats, @lower_words, @non_abbrs = [feats, lower_words, non_abbrs].map do |file|
            File.open(file) do |f|
                Marshal.load(f.read)
            end
        end
        @p0, @p1 = @feats[:"0,<prior>"] ** 4, @feats[:"1,<prior>"] ** 4  
    end

    attr_accessor :feats, :lower_words, :non_abbrs

    def normalize(counter)
        total = (counter.inject(0) { |s, i| s += i }).to_f
        counter.map! { |value| value / total }
    end

    def classify_single(frag)
        probs = [@p0, @p1]
        feat = ''
        frag.features.each do |feat|
            probs[0] *= (@feats[:"0,#{feat}"] or 1)
            probs[1] *= (@feats[:"1,#{feat}"] or 1)
        end
        normalize(probs)
        frag.pred = probs[1]
    end

    def classify(doc)
        doc.frags.each do |frag|
            classify_single frag
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
        w2 = (frag.next.andand.first or '')

        frag.features = [:"w1_#{w1}", :"w2_#{w2}", :"both_#{w1}_#{w2}"]

        len1 = [10, w1.gsub(/\W/, '').length].min

        if not w2.empty? and w1.gsub('.', '').is_alphabetic? 
            frag.features.push :"w1length_#{len1}"
            begin
                frag.features.push :"w1abbr_#{Math.log(1 + model.non_abbrs[w1.chop]).to_i}"
            rescue Exception => e
                frag.features.push :"w1abbr_0"
            end
        end

        if not w2.empty? and w2.gsub('.', '').is_alphabetic?
            frag.features.push :"w2cap_#{w2[0].is_upper_case?.to_s.capitalize}"
            begin
                frag.features.push :"w2lower_#{Math.log(1 + model.lower_words[w2.downcase]).to_i}"
            rescue Exception => e
                frag.features.push :"w2lower_0"
            end
        end
    end

    def featurize(doc)
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
        curr_words = []
        lower_words, non_abbrs = {}, {};

        text.lines.each do |line|
            # Deal with blank lines.
            if line.strip.empty?
                t = curr_words.join(' ')
                frag = Frag.new(t, true)
                @frags.last.andand.next = frag.cleaned.split
                @frags.push frag

                curr_words = []
            end
            line.split.each do |word|
                curr_words.push(word)

                if is_hyp word
                    t = curr_words.join(' ')
                    frag = Frag.new(t)
                    @frags.last.andand.next = frag.cleaned.split
                    @frags.push frag

                    curr_words = []
                end
            end
        end
    end

    def is_hyp(word)
        return false if ['.', '?', '!'].none? {|punct| word.include?(punct)}
        return true if ['.', '?', '!'].any? {|punct| word.end_with?(punct)}
        return true if word.match(/.*[.!?]["')\]]}*$/)
        return false
    end

    def segment
        sents, sent = [], []
        thresh = 0.5

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
