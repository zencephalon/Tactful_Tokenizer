require 'rubygems'
require 'sinatra'
require 'tempfile'
require 'html_tokenizer'
require 'rdiscount'

get '/' do
  @title = "Enter your text here."
  erb :home
end

post '/' do
  @title = "Critique Page"
  markdown = params[:phrase] #RDiscount.new(params[:phrase]).to_html
  @text = tokenize_plain(markdown)
  erb :reverse
end
