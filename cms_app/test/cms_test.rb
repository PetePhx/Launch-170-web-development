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

    get last_response["Location"]
    assert_equal 200, last_response.status
    assert_includes last_response.body, "\"virus.exe\" does not exist. :("
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

    get "/changes.txt/edit"

    assert_equal 200, last_response.status
    assert_includes last_response.body, "<textarea"
    assert_includes last_response.body, "<button type=\"submit\""
  end

  def test_updating_document
    create_document "changes.txt"

    post "/changes.txt", content: "the Quaternary period"
    assert_equal 302, last_response.status

    get last_response["Location"]
    assert_includes last_response.body, "\"changes.txt\" is updated! :)"

    get "/changes.txt"
    assert_equal 200, last_response.status
    assert_includes last_response.body, "the Quaternary period"
  end

  def test_view_new_document_form
    get "/new"

    assert_equal 200, last_response.status
    assert_includes last_response.body, "<input"
    assert_includes last_response.body, %q(<button type="submit")
  end

  def test_create_new_document
    post "/create", filename: "test.txt"
    assert_equal 302, last_response.status

    get last_response["Location"]
    assert_includes last_response.body, "\"test.txt\" is created"

    get "/"
    assert_includes last_response.body, "test.txt"
  end

  def test_create_new_document_without_filename
    post "/create", filename: ""
    assert_equal 422, last_response.status
    assert_includes last_response.body, "A name is required"
  end

  def test_deleting_document
    create_document("test.txt")

    post "/test.txt/destroy"

    assert_equal 302, last_response.status

    get last_response["Location"]
    assert_includes last_response.body, "\"test.txt\" is deleted! (buh-bye)"

    get "/"
    refute_includes last_response.body, "test.txt"
  end
end
