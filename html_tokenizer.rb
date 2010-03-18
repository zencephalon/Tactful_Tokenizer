require 'tactful_tokenizer'
require 'hpricot'
require 'rdiscount'
require 'digest'

$m = Model.new

def tokenize_discount(s)
    html = RDiscount.new(s).to_html
    html.gsub!(/\s+/, ' ')
    doc = Hpricot(html)
    enc = nil
    repl = {}
    doc.search("//code").each do |code|
        enc = Digest.hexencode(code.to_html) + "_CODE"
        repl[enc] = code.to_html
        code.swap(enc)
    end
    doc.search("//a").each do |link|
        enc = Digest.hexencode(link.to_html) + "_" + link.inner_html
        repl[enc] = link.to_html
        link.swap(enc)
    end

    doc = Hpricot(doc.to_html)
    k = ''
    doc.search("//p").each do |paragraph|
        k << paragraph.inner_html << "\n"
    end
    puts k.inspect
    sent_arr = $m.tokenize_text(k)
    #sent_arr = $m.tokenize_text(doc.search("*").grep(Hpricot::Text).each {|x| x.to_html.strip!}.join("\n"))
    puts h = doc.to_html
    puts "Array:"
    puts sent_arr.inspect
    sent_arr.each do |value|
         h.gsub!(value.strip, "<span>#{value}</span>") unless value == ""
    end
    repl.each_pair do |key, value|
        h.gsub!(key, value)
    end
    h
    #doc
end

def tokenize_plain(s)
    k = ''
    ht = ''
    s.each_line do |paragraph|
        k << paragraph << "\n"
        ht << "<p>#{paragraph}</p>"
    end
    puts k.inspect
    sent_arr = $m.tokenize_text(k)
    sent_arr.each do |value|
         ht.gsub!(value.strip, "<span>#{value}</span>") unless value == ""
    end
    ht = RDiscount.new(ht, :smart).to_html
end
