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
        return false if [/\./, /\?/, /!/].none? {|punct| punct.match word}
        c = unannotate(word)
        return true if [/\.$/, /\?$/, /!$/].any? {|punct| punct.match c}
        return true if c.match(/.*[\.\!\?]["')\]}*$/, c)
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
                    frag = Frag(curr_words.join(' '))
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
                    frag = Frag(curr_words.join(' '))
                    frag_list ? prev.next = frag : frag_list = frag
                    # Get label and tokenize.
                    frag.tokenized = tokenize(frag.org).gsub(/(<A>)|(<E>)|(<S>)/g, '')
                    frag_index += 1;
                    prev = frag;
                    curr_words = []
                end
                word_index += 1
            end
        end
        Doc(frag_list)
    end

    class Model
        def initialize(feats, lower_words, non_abbrs)
            
        end
    
    
    end



end
