require './lib'
require 'gserver'
require 'thread'
require 'yaml'

def format strs, prefix=-1
  #p strs
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

  end
end

class TelnetServer < GServer
  def initialize(port, world, users, *args)
    super(port, *args)
    @world = world
    @users = users
    @users.each do |user|
      user.room.things.delete user
    end
    Thread.new do
      loop do
        output = open ARGV[0], "w"
        output.write YAML.dump([@world,@users])
        output.flush
        sleep 10
      end
    end
  end
  def serve(io)
    begin
      io.print "Please enter your name: "
      name = io.gets.chomp
      users = @users.select {|u| u.names(nil).member? name.to_sym }
      user = users[0]
      if user
        user.room.things << user
      else
        user = User.new(name.to_sym, "A human called " + name, @world)
        @users << user
      end
        
      process user, io, "look" unless name == "admin"
      Thread.new do
        loop do
          io.puts user.queue.pop
          io.print "> "
        end
      end
      loop do
        io.print "> "
        message = io.gets.chomp
        break if message == "quit"
        next if message == ""
        begin
          if name == "admin"
            admin_process user, io, message
          else
            process user, io, message
          end
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

  def process user, io, message
    splat=message.chomp.split(' ').map {|e| e.to_sym }
    args = [(splat[0].to_s+"!").to_sym, user] + splat[1..-1]

    reply = user.room.send(*args)
    if reply.is_a? Disambiguation
      reply.each_with_index do |thing,i|
        io.puts i.to_s + ": " + format_well(thing.look!(user))
      end
      io.print ">> "
      reply = reply[io.gets.chomp.to_i].send(args[0],user,*args[3..-1])
    end
    io.puts((reply != [] and reply != nil) ? format_well(reply) : "Could not find " + args[2].to_s)
  end

  def admin_process user, io, message
    io.puts eval(message).inspect
  end
end

world, users = YAML.load(open(ARGV[0]).read)
world.rebuild

tserver = TelnetServer.new 2222, world, users
tserver.start
tserver.audit = true

tserver.join
