require 'spec_helper'

describe TactfulTokenizer::Model do
  it "should tokenize text correctly" do
    m = TactfulTokenizer::Model.new
    File.open('spec/files/sample.txt') do |f|
      text = f.read
      text = m.tokenize_text(text)
      File.open("spec/files/test_out.txt", "w+") do |g|
        text.each do |line|
          g.puts line unless line.empty?
        end   
        g.rewind 
        t2 = g.read
        t1 = File.open("spec/files/verification_out.txt").read
        t1.should == t2
      end
    end
  end
end