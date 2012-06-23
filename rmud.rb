require './lib'

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
    reply = @user.room.send *args
    reply ? format_well(reply) : "Could not find " + args[2].to_s
  end
end

avatar = Avatar.new :person, "A person"
room = Room.new :hell, "Hell"
door = Door.new([:door,:self], "A door", room)
room.things << door
user = User.new avatar, room
door.reply_random :what!, ["Hello", "How are you?"]
door.reply_list :fish!, ["What", "???"]

other = Room.new :other, "Another room"
doorway = Doorway.new [:doorway,:west], "Doorway", other
room.things << doorway
other.things << Doorway.new([:doorway,:east], "Doorway", room)
other.things << Thing.new(:spoon, "A spoon")


server = Server.new user
print "> "
while message=gets
  puts server.serve message
  print "> "
end
