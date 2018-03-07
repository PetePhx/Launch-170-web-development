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
  case file.split('.').last
  when 'md'
    render_markdown File.read("#{@root}/data/#{file}")
  when 'txt'
    headers["Content-Type"] = "text/plain;charset=utf-8"
    File.read("#{@root}/data/#{file}")
  end
end

def render_markdown(text)
  markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
  markdown.render(text)
end

before do
  @root = "/home/user/Launch/170_web_development/cms_app"
  @files = Dir.entries("#{@root}/data")
              .reject { |f| File.directory? f }
              .sort
end

get "/" do
  erb :index
end

get "/:file" do |file|
  check_exists(file)
  load_file(file)
end

get "/:file/edit" do |file|
  @file = file
  @content = File.read("#{@root}/data/#{@file}")
  check_exists(@file)

  erb :edit
end

post "/:file" do |file|
  new_content = params['content']
  File.open("#{@root}/data/#{file}", "w") do |f|
    f.write new_content
  end
  session[:message] = "#{file} is updated! :)"
  redirect "/"
end

# not_found do
#   "BAD URL."
# end
