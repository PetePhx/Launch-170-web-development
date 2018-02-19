=begin

Requirements

  1. When a user visits the root path, /, they should be presented with a
  listing of all of the files in the public directory. The listing for a file
  should only display the file's name and not the names of any directories.

  2. When a user clicks one of the filenames in the list, they should be taken
  directly to that file. Take advantage of Sinatra's built-in serving of the
  public directory.

  3. Create at least 5 files in the public directory to test the listing page.

  4. Add a parameter that controls the sort order of the files on the page. They
  should be sorted in an ascending (A-Z) order by default, or descending (Z-A)
  if the parameter has a certain value.

  5. Display a link to reverse the order. The text of the link should reflect
  the order that will be displayed if it is clicked: "Sort ascending" or "Sort
  descending".

=end

=begin
  steps:
    1. challenge.rb: route for /
      - read the file listing in the public directory
      - pass in the array to an instance var @files_arr
      - set the value of @order to :ascending (if not set)

    2. views folder, home.erb:
      - check the parameter @order.
      - sort the array of files, display them, along with the url
        - depending on @order, display in ascending/descending order
      - display a link to change the order.
        - depending on @order, link displays descending/ascending
        - when clicked, @order should be changed. then, "/" displayed.
        - change @order by passing ?order=... parameter in teh url
=end

require "sinatra"
require "sinatra/reloader"
require "tilt/erubis"

get "/" do
  @files = Dir.entries("./public").reject { |f| File.directory? f }
  @order = params['order'] ? params['order'].to_sym : :ascending
  @files = case @order
           when :ascending then @files.sort
           when :descending then @files.sort.reverse
           end
  erb :home
end
