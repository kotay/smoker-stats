require 'webrick'
require 'json'
require_relative './host'

module Server
  INDEX = File.read File.expand_path '../index.html', __FILE__

  class Index < WEBrick::HTTPServlet::AbstractServlet
    def initialize server, name
      super server
      @name = name
    end

    def do_GET request, response
      body = INDEX % [@name]

      response.status = 200
      response['Content-Type'] = 'text/html'
      response.body = body
    end
  end

  class Events < WEBrick::HTTPServlet::AbstractServlet
    attr_accessor :hosts

    def initialize server, hosts
      super server
      @hosts = hosts
    end

    def do_GET request, response
      response.status = 200
      response.chunked = true
      response['Content-Type'] = 'text/event-stream'
      rd, rw = IO.pipe
      response.body = rd
      Thread.abort_on_exception = true
      
      Thread.new {
        begin
          host = Host.new(@hosts.first)
          rw.write "event: hosts\n"
          rw.write "data: #{JSON.dump(hosts)}\n\n"
          rw.flush
          host.monitor(1) do |data|
            rw.write "event: update\n"
            rw.write "data: #{JSON.dump(data)}\n\n"
            rw.flush
          end
        ensure
          rw.close
        end
      }
    end
  end
end



server = WEBrick::HTTPServer.new :Port => 3334, :OutputBufferSize => 256
if ARGV.empty?
  hosts = ["84.45.120.152"]
else
  hosts = ARGV
end
server.mount '/',            Server::Index,  hosts
server.mount '/events.json', Server::Events, hosts

trap('INT') { server.shutdown }
Signal.trap(2) {
  server.shutdown
}
server.start

