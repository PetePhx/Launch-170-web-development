require "sinatra"
require "sinatra/reloader" if development?
require "sinatra/content_for"
require "tilt/erubis"
require "redcarpet"

configure do
  enable :sessions
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
  unless @files.include? file
    session[:error] = "#{file} does not exist. :)"
    redirect "/"
  end

  case file.split('.').last
  when 'md'
    render_markdown File.read("#{@root}/data/#{file}")
  when 'txt'
    headers["Content-Type"] = "text/plain;charset=utf-8"
    File.read("#{@root}/data/#{file}")
  end
end

# not_found do
#   "BAD URL."
# end
