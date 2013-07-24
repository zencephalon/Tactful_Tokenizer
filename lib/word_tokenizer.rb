# -*- encoding : utf-8 -*-
module WordTokenizer
  @@tokenize_regexps = [
    # Uniform Quotes
    [/''|``/, '"'],

    # Separate punctuation (except for periods) from words.
    [/(^|[:space:])(')/u, '\1\2'],
    [/(?=[\("`{\[:;&#*@])(.)/, '\1 '],

    [/(.)(?=[?!\)";}\]*:@'])|(?=[\)}\]])(.)|(.)(?=[({\[])|((^|[:space:])-)(?=[^-])/u, '\1 '],

    # Treat double-hyphen as a single token.
    [/([^-])(--+)([^-])/, '\1 \2 \3'],
    [/([:space:]|^)(,)(?=(^[:space:]))/u, '\1\2 '],

    # Only separate a comma if a space follows.
    [/(.)(,)([:space:]|$)/u, '\1 \2\3'],

    # Combine dots separated by whitespace to be a single token.
    [/\.[:space:]\.[:space:]\./u, '...'],

    # Separate "No.6"
    [/(^[:upper]^[:lower:]\.)(\d+)/, '\1 \2'],

    # Md. or MD. for Ruby 1.8 
    [/M[d|D]./, '\1'],

    # Separate words from ellipses
    [/([^\.]|^)(\.{2,})(.?)/, '\1 \2 \3'],
    [/(^|[:space:])(\.{2,})([^\.[:space:]])/u, '\1\2 \3'],
    [/(^|[:space:])(\.{2,})([^\.[:space:]])/u, '\1 \2\3'],

    ##### Some additional fixes.

    # Fix %, $, &
    [/(\d)%/, '\1 %'],
    [/\$(\.?\d)/, '$ \1'],
    [/(^[:lower:]^[:upper:])& (^[:lower:]^[:upper:])/u, '\1&\2'],
    [/(^[:lower:]^[:upper:]+)&(^[:lower:]^[:upper:]+)/u, '\1 & \2'],

    # Fix (n 't) -> ( n't)
    [/n 't( |$)/, " n't\\1"],
    [/N 'T( |$)/, " N'T\\1"],

    # Treebank tokenizer special words
    [/([Cc])annot/, '\1an not']

  ];

  def tokenize(s)
    rules = []
    @@tokenize_regexps.each {|rules| s.gsub!(rules[0], rules[1])}
  end
end
