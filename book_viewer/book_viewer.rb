require "sinatra"
require "sinatra/reloader"
require "tilt/erubis"

helpers do
  def in_pargraphs(str)
    str.split("\n\n").map { |e| "<p>#{e}</p>" }.join("\n")
  end
end

before do
  @contents = File.readlines("data/toc.txt")
end

get "/" do
  @title = "The Adventures of Sherlock Holmes"
  erb :home
end

get "/chapters/:number" do
  @number = params['number'].to_i
  @title = "Chapter #{@number}: #{@contents[@number - 1]}"
  @chapter = File.read("data/chp#{@number}.txt")
  erb :chapter
end
