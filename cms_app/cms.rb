require "sinatra"
require "sinatra/reloader" if development?
require "sinatra/content_for"
require "tilt/erubis"
require "redcarpet"

configure do
  enable :sessions
end

helpers do
  def signed_in?
    session[:signed_in] == true
  end

  def user
    session[:user]
  end
end

def authenticated?(username: "", password: "")
  username.downcase == 'admin' && password == 'secret'
end

def sign_out
  session[:signed_in] = false
  session[:user] = nil
end

def check_exists(file)
  return if @files.include?(file)
  session[:message] = "\"#{file}\" does not exist. :("
  redirect "/"
end

def load_file(file)
  case File.extname(file)
  when '.md'
    erb render_markdown File.read File.join(data_path, file)
  when '.txt'
    headers["Content-Type"] = "text/plain;charset=utf-8"
    File.read("#{data_path}/#{file}")
  else
    session[:message] = "Can't display \"#{file}\" (sorry not sorry)!"
    redirect "/"
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
  @title = "cms"
end

get "/" do
  erb :index
end

get "/users/signin" do
  if signed_in?
    session[:message] = "You are already signed in, mate! ;)"
    redirect "/"
  else
    erb :signin
  end
end

post "/users/signin" do
  if authenticated?(username: params['username'], password: params['password'])
    session[:signed_in] = true
    session[:user] = 'admin'
    session[:message] = "Welcome!"
    redirect "/"
  else
    session[:message] = "Invalid Credentials. TRY HARDER!"
    status 422
    erb :signin
  end
end

post "/users/signout" do
  if signed_in?
    session[:signed_in] = false
    session.delete(:user)
    session['message'] = "You have been signed out! buh-bye."
    redirect "/"
  else
    session[:message] = "You are already signed out, bud! ;)"
    redirect "/"
  end
end

get "/new" do
  @title += " | new file"
  erb :new
end

post "/create" do
  if (filename = params['filename'].strip).empty?
    session[:message] = "A name is required! :|"
    status 422
    erb :new
  else
    File.open(File.join(data_path, filename), "w") {}
    session[:message] = "\"#{filename}\" is created! (yay)"
    redirect "/"
  end
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

post "/:file/destroy" do |file|
  check_exists(file)
  case File.delete File.join(data_path, file)
  when 1 then session[:message] = "\"#{file}\" is deleted! (buh-bye)"
  else session[:message] = "Hmmm... something ain't right!"
  end
  redirect "/"
end

post "/:file" do |file|
  check_exists(file)
  File.open(File.join(data_path, file), "w") do |f|
    f.write params['content']
  end
  session[:message] = "\"#{file}\" is updated! :)"
  redirect "/"
end


# not_found do
#   "BAD URL."
# end
