require "sinatra"
require "sinatra/reloader" if development?
require "sinatra/content_for"
require "tilt/erubis"


before do
  @files = Dir.entries("./data")
              .reject { |f| File.directory? f }
              .sort
end

get "/" do
  erb :index
end

get "/:file" do |file|
  redirect not_found, 301 unless @files.include? file
  headers["Content-Type"] = "text/plain"
  File.read("data/#{file}")
end

not_found do
  "Bad URL."
end
