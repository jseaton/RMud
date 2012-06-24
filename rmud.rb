require './world'

def format strs, prefix=-1
  return (" "*prefix)+strs if strs.class == String
  strs.map do |str|
    format str, prefix + 1
  end if strs
end

def format_well strs
  return strs if strs.class == String
  format strs
end

class Server
  def initialize user
    @user  = user
  end

  def serve raw
    message=raw.chomp.split(' ').map {|e| e.to_sym }
    args = [(message[0].to_s+"!").to_sym, @user] + message[1..-1]
    p args
    begin
      reply = [@user.room.send(*args)].flatten.compact
    rescue => m
      return m
    end
    reply != [] ? format_well(reply) : "Could not find " + args[2].to_s
  end
end

server = Server.new user(world)
puts server.serve "look"
print "> "
while message=gets
  puts server.serve message
  print "> "
end
