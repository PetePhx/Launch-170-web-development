require "sinatra"
require "sinatra/reloader" if development?
require "sinatra/content_for"
require "tilt/erubis"
require "redcarpet"
require "yaml"
require "bcrypt"

configure do
  enable :sessions
end

helpers do
  def signed_in?
    session[:signed_in] == true
  end

  def user
    session[:username]
  end
end

def authenticate(username: "", password: "")
  creds = YAML.load_file File.expand_path(case ENV["RACK_ENV"]
                                               when "test"
                                                 "../test/users.yml"
                                               else
                                                 "../users.yml"
                                               end, __FILE__)

  if creds.key?(username.to_sym) &&
     BCrypt::Password.new(creds[username.to_sym]) == password
    session[:signed_in] = true
    session[:username] = username
  end
end

def request_sign_in
  session[:message] = "You must be signed in to do that. ;)"
  redirect "/"
end

def sign_out
  session[:signed_in] = false
  session[:username] = nil
  session['message'] = "You have been signed out! buh-bye."
  redirect "/"
end

def check_exists(file)
  return if @files.include?(file)
  session[:message] = "\"#{file}\" does not exist or can't be displayed. :("
  redirect "/"
end

def data_path
  File.expand_path(case ENV["RACK_ENV"]
                   when "test" then "../test/data"
                   else "../data"
                   end, __FILE__)
end

def load_file(file)
  case File.extname(file)
  when '.md'
    erb render_markdown File.read File.join(data_path, file)
  when '.txt'
    headers["Content-Type"] = "text/plain;charset=utf-8"
    File.read File.join(data_path, file)
  else
    session[:message] = "Can't display \"#{file}\" (sorry not sorry)!"
    redirect "/"
  end
end

def render_markdown(text)
  Redcarpet::Markdown.new(Redcarpet::Render::HTML).render(text)
end

def valid_extention?(file)
  File.extname(file) == '.txt' || File.extname(file) == '.md'
end

before do
  # .reject { |f| File.directory? f }
  @files = Dir.entries(data_path)
              .select { |f| valid_extention? f }
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
  if authenticate(username: params['username'], password: params['password'])
    session[:message] = "Welcome!"
    redirect "/"
  else
    session[:message] = "Invalid Credentials. TRY HARDER!"
    status 422
    erb :signin
  end
end

post "/users/signout" do
  unless signed_in?
    session[:message] = "You are already signed out, bud! ;)"
    redirect "/"
  end
  sign_out
end

get "/new" do
  request_sign_in unless signed_in?
  @title += " | new file"
  erb :new
end

post "/create" do
  request_sign_in unless signed_in?
  filename = params['filename'].strip
  if filename.empty?
    session[:message] = "A name is required! :|"
    status 422
    erb :new
  elsif !valid_extention?(filename)
    session[:message] = "Valid extensions are: \".txt\" and \".md\"."
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
  request_sign_in unless signed_in?
  check_exists(file)
  @title += " | #{file}"
  @file = file
  @content = File.read File.join(data_path, @file)

  erb :edit
end

post "/:file/destroy" do |file|
  request_sign_in unless signed_in?
  check_exists(file)
  case File.delete File.join(data_path, file)
  when 1 then session[:message] = "\"#{file}\" is deleted! (buh-bye)"
  else session[:message] = "Hmmm... something ain't right!"
  end
  redirect "/"
end

post "/:file" do |file|
  request_sign_in unless signed_in?
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
