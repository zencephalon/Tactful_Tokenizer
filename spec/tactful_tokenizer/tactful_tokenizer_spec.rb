# -*- encoding : utf-8 -*-
require 'spec_helper'

describe String do
  describe ".is_upper_case?" do
    it "should be false" do
      "asdfghjk".is_upper_case?.should == false
    end

    it "should be true" do
      "ASDFGHJK".is_upper_case?.should == true
    end
  end

  describe ".is_alphabetic?" do
    it "should be false" do
      "!^?".is_alphabetic?.should == false
    end

    it "should be true" do
      "some text".is_alphabetic?.should == true
    end

    it "should be true for unicode text" do
      "русский текст".is_alphabetic?.should == true
    end    
  end
end

describe TactfulTokenizer::Model do
  describe ".tokenize_text" do
    it "should tokenize correctly" do
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
end