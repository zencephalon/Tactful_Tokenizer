require 'tactful_tokenizer'
require 'test/unit'

class TactfulTokenize < Test::Unit::TestCase
    def test_simple
        m = Model.new
        File.open("sample.txt") do |f|
            text = f.read
            text = tokenize_text(m, text)
            File.open("test_out.txt","w+") do |g|
                text.each do |line|
                    g.puts line unless line.empty?
                end
            end
        end
        t1 = File.open("verification_out.txt").read
        t2 = File.open("test_out.txt").read
        assert_equal(t1, t2)
    end
end
