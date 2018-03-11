ENV["RACK_ENV"] = "test"

require "minitest/autorun"
require "rack/test"
require "fileutils"

require_relative "../cms"

def create_document(name, content = "")
  File.open(File.join(data_path, name), "w") do |file|
    file.write(content)
  end
end

class AppTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def setup
    FileUtils.mkdir_p(data_path)
  end

  def teardown
    FileUtils.rm_rf(data_path)
  end

  def session
    last_request.env["rack.session"]
  end

  def admin_session
    { "rack.session" => { signed_in: true, username: "admin" } }
  end

  def test_index
    create_document "about.md"
    create_document "changes.txt"
    create_document "history.txt"

    get "/"
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "about.md"
    assert_includes last_response.body, "changes.txt"
    assert_includes last_response.body, "history.txt"
  end

  def test_about_changes_history
    create_document "about.md", "Platypus"
    create_document "changes.txt", "the Quaternary period"
    create_document "history.txt", "Matsumoto dreams..."

    get "/about.md"
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "<p>Platypus</p>"

    get "/changes.txt"
    assert_equal 200, last_response.status
    assert_equal "text/plain;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "the Quaternary period"

    get "/history.txt"
    assert_equal 200, last_response.status
    assert_equal "text/plain;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "Matsumoto dreams"
  end

  def test_document_not_found
    get "/virus.exe"
    assert_equal 302, last_response.status
    assert_equal "\"virus.exe\" does not exist or can't be displayed. :(",
      session[:message]
  end

  def test_viewing_markdown_document
    create_document "about.md", "#Platypus..."

    get "/about.md"
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "<h1>Platypus...</h1>"
  end

  def test_editing_document
    create_document "changes.txt", "the Quaternary period"

    get "/changes.txt/edit", {}, admin_session

    assert_equal 200, last_response.status
    assert_includes last_response.body, "<textarea"
    assert_includes last_response.body, "<button type=\"submit\""
  end

  def test_editing_document_signed_out
    create_document "changes.txt"

    get "/changes.txt/edit"

    assert_equal 302, last_response.status
    assert_equal "You must be signed in to do that. ;)", session[:message]
  end

  def test_updating_document
    create_document "changes.txt"

    post "/changes.txt", {content: "the Quaternary period"}, admin_session
    assert_equal 302, last_response.status

    assert_equal "\"changes.txt\" is updated! :)", session[:message]

    get "/changes.txt"
    assert_equal 200, last_response.status
    assert_includes last_response.body, "the Quaternary period"
  end

  def test_updating_document_signed_out
    post "/changes.txt", {content: "new content"}

    assert_equal 302, last_response.status
    assert_equal "You must be signed in to do that. ;)", session[:message]
  end

  def test_view_new_document_form
    get "/new", {}, admin_session

    assert_equal 200, last_response.status
    assert_includes last_response.body, "<input"
    assert_includes last_response.body, %q(<button type="submit")
  end

  def test_view_new_document_form_signed_out
    get "/new"

    assert_equal 302, last_response.status
    assert_equal "You must be signed in to do that. ;)", session[:message]
  end

  def test_create_new_document
    post "/create", {filename: "test.txt"}, admin_session
    assert_equal 302, last_response.status

    assert_equal "\"test.txt\" is created! (yay)", session[:message]

    get "/"
    assert_includes last_response.body, "test.txt"
  end

  def test_create_new_document_signed_out
    post "/create", {filename: "test.txt"}

    assert_equal 302, last_response.status
    assert_equal "You must be signed in to do that. ;)", session[:message]
  end

  def test_create_new_document_without_filename
    post "/create", {filename: ""}, admin_session
    assert_equal 422, last_response.status
    assert_includes last_response.body, "A name is required"
  end

  def test_deleting_document
    create_document("test.txt")

    post "/test.txt/destroy", {}, admin_session

    assert_equal 302, last_response.status

    assert_equal "\"test.txt\" is deleted! (buh-bye)", session[:message]

    2.times { get "/" }
    refute_includes last_response.body, "test.txt"
  end

  def test_deleting_document_signed_out
    create_document("test.txt")

    post "/test.txt/destroy"
    assert_equal 302, last_response.status
    assert_equal "You must be signed in to do that. ;)", session[:message]
  end

  def test_signin_form
    get "/users/signin"

    assert_equal 200, last_response.status
    assert_includes last_response.body, "<input"
    assert_includes last_response.body, %q(<button type="submit")
  end

  def test_signin
    post "/users/signin", username: "admin", password: "secret"
    assert_equal 302, last_response.status
    assert_equal "Welcome!", session[:message]
    assert_equal "admin", session[:username]

    get last_response["Location"]
    assert_includes last_response.body, "Signed in as admin"
  end

  def test_signin_with_bad_credentials
    post "/users/signin", username: "guest", password: "shhhh"
    assert_equal 422, last_response.status
    assert_nil session[:username]
    assert_includes last_response.body, "Invalid Credentials"
  end

  def test_signout
    get "/", {}, {"rack.session" => { username: "admin", signed_in: true } }
    assert_includes last_response.body, "Signed in as admin"

    post "/users/signout"
    assert_equal "You have been signed out! buh-bye.", session[:message]
    get last_response["Location"]

    assert_nil session[:username]
    assert_includes last_response.body, "sign in"
  end
end
