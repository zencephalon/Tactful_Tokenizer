require '../lib/tactful_tokenizer'
require 'test/unit'

class TactfulTokenize < Test::Unit::TestCase
    def test_simple
        m = TactfulTokenizer::Model.new
        File.open("sample.txt") do |f|
            text = f.read
            text = m.tokenize_text(text)
            File.open("test_out.txt","w+") do |g|
                text.each do |line|
                    g.puts line unless line.empty?
                end   
                g.rewind 
                t2 = g.read
                t1 = File.open("verification_out.txt").read
                assert_equal(t1, t2)
            end
        end
    end
end
