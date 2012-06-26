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
      user.parent.things.delete user
      user.rebuild
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
        user.parent.things << user
        user.rebuild
      else
        user = User.new(name.to_sym, "A human called " + name, @world)
        @users << user
      end
      puts "here"
      process(user,io,"look") unless name == "god"
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
          if name == "god"
            god_process user, io, message
          elsif name == "admin"
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
      user.parent.things.delete user
      io.close
    end
  end

  def process user, io, message
    splat=message.chomp.split(' ').map {|e| e.to_sym }
    args = [(splat[0].to_s+"!").to_sym, user] + splat[1..-1]
    p args
    
    reply = user.parent.send(*args)
    if reply.is_a? Disambiguation
      reply.each_with_index do |thing,i|
        io.puts i.to_s + ": " + format_well(thing.look!(user))
      end
      io.print ">> "
      reply = reply[io.gets.chomp.to_i].send(args[0],user,*args[3..-1])
    end
    io.puts (reply != [] and reply != nil) ? format_well(reply) : "Could not find " + args[2].to_s
  end

  def admin_process user, io, message
    splat=message.chomp.split(' ').map {|e| e.to_sym }
    obj = user.parent
    if splat[0][-1] == ":"
      p splat[0][0..-2].to_sym
      obj = user.parent.get_all(user, splat[0][0..-2].to_sym)[0]
      splat.shift
    end
    p splat
    if splat[0][-1] == "?"
      splat[0] = splat[0][0..-2].to_sym
    else
      splat.insert 1, user
    end
    reply = obj.send(*splat)
    io.puts reply.inspect
    io.puts (reply != [] and reply != nil) ? format_well(reply) : "Could not find " + splat[2].to_s
  end
    

  def god_process user, io, message
    io.puts eval(message).inspect
  end
end

world, users = YAML.load(open(ARGV[0]).read)
world.rebuild

tserver = TelnetServer.new 2222, world, users
tserver.start
tserver.audit = true

tserver.join
