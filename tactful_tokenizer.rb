require "word_tokenizer.rb"
include WordTokenizer

# TODO: More documentation.
# TODO: Link up with Marshal to load data models.
# TODO: Test coverage.
####### Performance TODOs.
# TODO: Use string interpolation.
# TODO: Use destructive methods were possible.
# TODO: Use an array for frags instead of a linked list.

module TactfulTokenizer
    # Removes annotations from words.
    def unannotate(token)
        token.gsub(/(<A>)?(<E>)?(<S>)?$/, '')
    end

    # Normalizes numbers and discards ambiguous punctuation.
    def clean(token)
        token.gsub(/[.,\d]*\d/, '<NUM>')
            .gsub(/[^a-zA-Z0-9,.;:<>\-'\/$% ]/, '')
            .gsub('--', ' ')
    end

    class String
        def is_alphabetic?
            return !/[^A-Z]/i.match(self)
        end
        def is_upper_case?
            return !/[^A-Z]/.match(self)
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
        words1 = clean(frag.tokenized).split(/\s+/)
        w1 = words1 ? words1[-1] : ''
        if frag.next
            words2 = clean(frag.next.tokenized).split(/\s+/)
            w2 = words2 ? words2[0] : ''
        else
            words2, w2 = [], ''
        end

        c1 = w1.gsub(/(^.+?\-)/, '')
        c2 = w2.gsub(/(\-.+?)$/, '')

        feats = {}
        feats['w1'] = c1
        feats['w2'] = c2
        feats['both'] = c1 + "_" + c2

        len1 = [10, c1.gsub(/\W/, '').length].min

        if not c2.empty? and c1.gsub('.', '').is_alphabetic? 
            feats['w1length'] = len1.to_s
            begin
                feats['w1abbr'] = Math.log(1 + model.non_abbrs[c1.chop()]).to_s
            rescue Exception => e
                feats['w1abbr'] = '0'
            end
        end

        if not c2.empty? and c2.gsub('.', '').is_alphabetic?
            feats['w2cap'] = c2[0].is_upper_case?.to_s
            begin
                feats['w2lower'] = Math.log(1 + model.lower_words[c2.downcase]).to_s
            rescue Exception => e
                feats['w2lower'] = '0'
            end
        end
        feats
    end

    def is_sbd_hyp(word)
        return false if ['.', '?', '!'].none? {|punct| word.include?(punct)}
        c = unannotate(word)
        return true if ['.', '?', '!'].any? {|punct| word.end_with?(punct)}
        return true if c.match(/.*[.!?]["')\]]}*$/)
        return false
    end

    def get_text_data(text)
        frag_list = nil
        curr_words = []
        frag_index, word_index = 0, 0
        lower_words, non_abbrs = {}, {};

        text.lines.each do |line|
            # Deal with blank lines.
            if frag_list and not line.trim.empty?
                if curr_words
                    frag = Frag.new(curr_words.join(' '))
                    prev.next = frag
                    frag.tokenized = WordTokenizer.tokenize(frag.orig)
                    frag_index += 1
                    prev = frag
                    curr_words = []
                end
                frag.ends_seg = true
            end
            line.split.each do |word|
                curr_words.push(word)

                if is_sbd_hyp word
                    frag = Frag.new(curr_words.join(' '))
                    frag_list ? prev.next = frag : frag_list = frag
                    # Get label and tokenize.
                    frag.tokenized = tokenize(frag.orig).gsub(/(<A>)|(<E>)|(<S>)/, '')
                    frag_index += 1;
                    prev = frag;
                    curr_words = []
                end
                word_index += 1
            end
        end
        Doc.new(frag_list)
    end

    class Model
        attr_accessor :feats, :lower_words, :non_abbrs
        def initialize(feats, lower_words, non_abbrs)
            @feats = feats
            @lower_words = lower_word
            @non_abbrs = non_abbrs
        end

        def classify_single(frag)
            probs = {}
            probs[0] = @feats[[0, '<prior>']] ** 4
            probs[1] = @feats[[1, '<prior>']] ** 4

            probs.each_key do |label|
                frag.features.each_pair do |feat, val|
                    probs[label] *= (@feats[[label,feat+"_"+val]] or 1)
                end
            end
    
            normalize(probs)
            probs[1]
        end

        def classify(doc)
            frag = doc.frag
            while frag
                frag.pred = classify_single(frag)
                frag = frag.next
            end
        end
    end

    class Doc
        attr_accessor :frag
        def initialize(frag)
            @frag = frag
        end

        def featurize(model)
            frag = @frag
            while frag
                frag.features = get_features(frag, model)
                frag = frag.next
            end
        end

        def segment
            sents, sent = [], []
            thresh = 0.5
            frag = @frag

            while frag
                sent.push(frag.orig)
                if frag.pred > thresh or frag.ends_seg
                    break if frag.orig.nil?
                    sents.push(sent.join(' '))
                    sent []
                end
                frag = frag.next
            end
            sents
        end
    end

    class Frag
        attr_accessor :orig, :next, :ends_seg, :tokenized, :pred, :label, :features
        def initialize(orig)
            @orig = orig
            @next = nil
            @ends_seg = false
            @tokenized = false
            @pred = nil
            @label = nil
            @features = nil
        end
    end

    def normalize(counter)
        total = counter.inject(0) { |s, i| s += i }.to_f
        counter.map! { |value| value / total }
    end
    
    def tokenize_text(model, text)
        data = get_text_data(text)
        data.featurize(model)
        model.classify(data)
        return data.segment
    end
end
