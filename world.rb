require './lib'

def world
  room = Room.new :hell, "Hell"
  door = LockedDoor.new([:door,:self], "A door", room, "ham")
  door.takeable
  room.things << door
  User.new(:fish, "A fish", room).takeable
  User.new(:ham, "A ham", room).takeable
  #door.reply_random :what!, ["Hello", "How are you?"]
  #door.reply_list :fish!, ["What", "???"]
  
  other = Room.new :other, "Another room"
  doorway = Doorway.new [:doorway,:west], "Doorway", other
  doorway.takeable
  room.things << doorway
  other.things << Doorway.new([:doorway2,:east], "Doorway", room)
  other.things << Thing.new(:spoon, "A spoon")
  room
end

def user room
  User.new :person, "A person", room
end
