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
  redirect to("/"), 301 unless (1..@contents.size).cover? @number
  @chapter = File.read("data/chp#{@number}.txt")
  erb :chapter
end

get "/search" do
  erb :search
end

not_found do
  redirect to("/")
end
