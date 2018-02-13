require "socket"

def parse_request(req)
  http_method, path_and_params, http_ver = req.split(" ")
  path, params = path_and_params.split("?")

  params = params.split("&")
                 .map { |str| str.split("=")  }
                 .to_h

  [http_method, path, params]
end

server = TCPServer.new("localhost", 3003)

loop do
  client = server.accept
  request_line = client.gets
  next if !request_line || request_line =~ /favicon/
  puts request_line

  http_method, path, params = parse_request(request_line)

  client.puts "HTTP/1.1 200 OK"
  client.puts "Content-Type: text/plain\r\n\r\n"
  client.puts request_line
  params["rolls"].to_i.times do
    client.puts rand(params["sides"].to_i) + 1
  end

  client.close
end
