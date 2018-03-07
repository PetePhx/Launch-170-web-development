require "sinatra"
require "sinatra/reloader" if development?
require "sinatra/content_for"
require "tilt/erubis"
require "redcarpet"

configure do
  enable :sessions
end

def check_exists(file)
  return if @files.include?(file)
  session[:message] = "#{file} does not exist. :("
  redirect "/"
end

def load_file(file)
  case File.extname(file)
  when '.md'
    erb render_markdown File.read File.join(data_path, file)
  when '.txt'
    headers["Content-Type"] = "text/plain;charset=utf-8"
    File.read("#{data_path}/#{file}")
  end
end

def render_markdown(text)
  Redcarpet::Markdown.new(Redcarpet::Render::HTML).render(text)
end

def data_path
  if ENV["RACK_ENV"] == "test"
    File.expand_path("../test/data", __FILE__)
  else
    File.expand_path("../data", __FILE__)
  end
end

before do
  @files = Dir.entries(data_path)
              .reject { |f| File.directory? f }
              .sort
  @title = "CMS"
end

get "/" do
  erb :index
end

get "/:file" do |file|
  check_exists(file)
  load_file(file)
end

get "/:file/edit" do |file|
  check_exists(file)
  @title += " | #{file}"
  @file = file
  @content = File.read File.join(data_path, @file)

  erb :edit
end

post "/:file" do |file|
  check_exists(file)
  File.open(File.join(data_path, file), "w") do |f|
    f.write params['content']
  end
  session[:message] = "#{file} is updated! :)"
  redirect "/"
end

# not_found do
#   "BAD URL."
# end
