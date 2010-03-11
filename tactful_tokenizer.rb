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
        File.open(feats) do |f|
            @feats = Marshal.load(f.read)
        end
        File.open(lower_words) do |f|
            @lower_words = Marshal.load(f.read)
        end
        File.open(non_abbrs) do |f|
            @non_abbrs = Marshal.load(f.read)
        end
        @p0 = feats('0,<prior>') ** 4
        @p1 = feats('1,<prior>') ** 4 
    end

    def normalize(counter)
        total = (counter.inject(0) { |s, i| s += i }).to_f
        counter.map! { |value| value / total }
    end

    def classify_single(frag)
        probs = [@p0, @p1]

        for label in (0..1) do
            frag.features.each_pair do |feat, val|
                probs[label] *= (feats("#{label},#{feat.to_s}_#{val.to_s}") or 1)
            end
        end

        normalize(probs)
        probs[1]
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

    def classify(doc)
        doc.frags.each do |frag|
            frag.pred = classify_single(frag)
        end
    end

    def tokenize_text(text)
        data = get_text_data(text)
        data.featurize(self)
        classify(data)
        return data.segment
    end
end

class Doc
    attr_accessor :frags
    def initialize(frags)
        @frags = frags
    end

    def featurize(model)
        @frags.each do |frag|
            frag.features = get_features(frag, model)
        end
    end

    # Normalizes numbers and discards ambiguous punctuation.
    def clean(token)
        token.gsub(/[.,\d]*\d/, '<NUM>')
        .gsub(/[^a-zA-Z0-9,.;:<>\-'\/$% ]/, '')
        .gsub('--', ' ')
    end

    def get_features(frag, model)
        words1 = clean(frag.tokenized).split
        w1 = words1.empty? ? '' : words1[-1]
        if frag.next
            words2 = clean(frag.next.tokenized).split
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

def is_sbd_hyp(word)
    return false if ['.', '?', '!'].none? {|punct| word.include?(punct)}
    return true if ['.', '?', '!'].any? {|punct| word.end_with?(punct)}
    return true if word.match(/.*[.!?]["')\]]}*$/)
    return false
end

def get_text_data(text)
    frag_list = []
    curr_words = []
    lower_words, non_abbrs = {}, {};

    text.lines.each do |line|
        # Deal with blank lines.
        if line.strip.empty?
            t = curr_words.join(' ')
            frag = Frag.new(t, tokenize(t), true)
            frag_list.last.next = frag if frag_list.last
            frag_list.push frag

            curr_words = []
        end
        line.split.each do |word|
            curr_words.push(word)

            if is_sbd_hyp word
                t = curr_words.join(' ')
                frag = Frag.new(t, tokenize(t).gsub(/(<A>)|(<E>)|(<S>)/, ''))
                frag_list.last.next = frag if frag_list.last
                frag_list.push frag

                curr_words = []
            end
        end
    end
    Doc.new(frag_list)
end

