require "sinatra"
require "sinatra/reloader"
require "tilt/erubis"

helpers do
  def in_pargraphs(str)
    str.split("\n\n")
       .map.with_index { |e, idx| "<p, id=#{idx}>#{e}</p>" }
       .join("\n")
  end

  def paragraph_highlight(par, word)
    par.gsub(word, "<strong>#{word}</strong>")
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
  @query = params['query']
  chapters_matching
  erb :search
end

not_found do
  redirect to("/")
end

def chapters_matching
  @results = []
  return @results unless !@query.nil? && !@query.empty? && @query.match(/\w/)
  (1..@contents.size).each do |chp|
    File.read("data/chp#{chp}.txt").split("\n\n")
        .each_with_index do |par, idx|
          @results << [chp, idx, par] if par.match(@query)
        end
  end
  @results
end
