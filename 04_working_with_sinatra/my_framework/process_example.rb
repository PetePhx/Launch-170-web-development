require 'erb'

template_file = File.read('example.erb')
erb = ERB.new(template_file)
puts erb.result

# <html>
#   <body>
#     <h4>Hello, my name is bob</h4>
#   </body>
# </html>
