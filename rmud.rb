require './world'
require 'gserver'
require 'thread'

def format strs, prefix=-1
  return (" "*prefix)+strs if strs.class == String
  strs.map do |str|
    format str, prefix + 1 if str
  end if strs
end

def format_well strs
  return strs if strs.class == String
  format strs
end

class Server < GServer
  def initialize user
    @user  = user
  end

  def serve raw
    message=raw.chomp.split(' ').map {|e| e.to_sym }
    args = [(message[0].to_s+"!").to_sym, @user] + message[1..-1]
    begin
      reply = @user.room.send(*args)
    rescue => m
      return m
    end
    reply != [] ? format_well(reply) : "Could not find " + args[2].to_s
  end
end

class TelnetServer < GServer
  def initialize(port, world, *args)
    super(port, *args)
    @world = world
  end
  def serve(io)
    begin
      io.print "Please enter your name: "
      name = io.gets.chomp
      user = User.new name.to_sym, "A human called " + name, @world
      server = Server.new user
      io.puts server.serve "look"
      Thread.new do
        loop do
          puts "in"
          io.puts user.queue.pop
          io.print "> "
          puts "out"
        end
      end
      loop do
        io.print "> "
        message = io.gets.chomp
        break if message == "quit"
        next if message == ""
        begin 
          io.puts server.serve(message)
        rescue => m
          log "ERROR: " + name + " : " + m.to_s
          puts m.backtrace
          io.puts "An error occurred, sorry."
        end
        log name + " : " + message
      end
    rescue => m
      log "FATAL ERROR: " + name + " : " + m
      puts m.backtrace
      io.puts "A fatal error occurred. Sorry."
    ensure
      user.room.things.delete user
      io.close
    end
  end
end


tserver = TelnetServer.new 2222, world
tserver.start
tserver.audit = true
tserver.join
