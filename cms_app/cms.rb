require "sinatra"
require "sinatra/reloader" if development?
require "sinatra/content_for"
require "tilt/erubis"


get "/" do
  @files = Dir.entries("./data")
              .reject { |f| File.directory? f }
              .sort
  erb :home
end
