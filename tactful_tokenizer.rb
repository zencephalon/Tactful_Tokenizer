require "word_tokenizer.rb"
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
    def initialize(feats="feats.mar", lower_words="lower_words.mar", non_abbrs="non_abbrs.mar")
        @feats, @lower_words, @non_abbrs = [feats, lower_words, non_abbrs].map do |file|
            File.open(file) do |f|
                Marshal.load(f.read)
            end
        end
        @p0 = feats('0,<prior>') ** 4
        @p1 = feats('1,<prior>') ** 4 
    end

    def feats(arr)
        t = @feats[arr]
        t.to_f if t
    end
    def lower_words(arr)
        t = @lower_words[arr]
        t.to_f if t
    end
    def non_abbrs(arr)
        t = @non_abbrs[arr]
        t.to_f if t
    end

    def normalize(counter)
        total = (counter.inject(0) { |s, i| s += i }).to_f
        counter.map! { |value| value / total }
    end

    def classify_single(frag)
        probs = [@p0, @p1]

        frag.features.each_pair do |feat, val|
            probs[0] *= (feats("0,#{feat.to_s}_#{val.to_s}") or 1)
            probs[1] *= (feats("1,#{feat.to_s}_#{val.to_s}") or 1)
        end

        normalize(probs)
        probs[1]
    end

    def classify(doc)
        doc.frags.each do |frag|
            frag.pred = classify_single(frag)
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
        words1 = frag.clean.split
        w1 = words1.empty? ? '' : words1[-1]
        if frag.next
            words2 = frag.next.clean.split
            w2 = words2.empty? ? '' : words2[0]
        else
            words2, w2 = [], ''
        end

        c1 = w1.gsub(/(^.+?\-)/, '')
        c2 = w2.gsub(/(\-.+?)$/, '')

        feats = {}
        feats['w1'], feats['w2'] = c1, c2
        feats['both'] = "#{c1}_#{c2}"

        len1 = [10, c1.gsub(/\W/, '').length].min

        if not c2.empty? and c1.gsub('.', '').is_alphabetic? 
            feats['w1length'] = len1
            begin
                feats['w1abbr'] = Math.log(1 + model.non_abbrs(c1.chop())).to_i
            rescue Exception => e
                feats['w1abbr'] = 0
            end
        end

        if not c2.empty? and c2.gsub('.', '').is_alphabetic?
            feats['w2cap'] = c2[0].is_upper_case?.to_s.capitalize
            begin
                feats['w2lower'] = Math.log(1 + model.lower_words(c2.downcase)).to_i
            rescue Exception => e
                feats['w2lower'] = 0
            end
        end
        feats
    end

    def featurize(doc)
        doc.frags.each do |frag|
            frag.features = get_features(frag, self)
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
        get_text_data(text)
    end

    def get_text_data(text)
        @frags = []
        curr_words = []
        lower_words, non_abbrs = {}, {};

        text.lines.each do |line|
            # Deal with blank lines.
            if line.strip.empty?
                t = curr_words.join(' ')
                frag = Frag.new(t, tokenize(t), true)
                @frags.last.next = frag if @frags.last
                @frags.push frag

                curr_words = []
            end
            line.split.each do |word|
                curr_words.push(word)

                if is_hyp word
                    t = curr_words.join(' ')
                    frag = Frag.new(t, tokenize(t).gsub(/(<A>)|(<E>)|(<S>)/, ''))
                    @frags.last.next = frag if @frags.last
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
    attr_accessor :orig, :next, :ends_seg, :tokenized, :pred, :features
    def initialize(orig='', tokenized=false, ends_seg=false)
        @orig = orig
        @next = nil
        @ends_seg = ends_seg
        @tokenized = tokenized
        @pred = nil
        @features = nil
    end

    # Normalizes numbers and discards ambiguous punctuation.
    def clean()
        @tokenized.gsub(/[.,\d]*\d/, '<NUM>')
        .gsub(/[^a-zA-Z0-9,.;:<>\-'\/$% ]/, '')
        .gsub('--', ' ')
    end
end
