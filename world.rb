require './lib'
require 'yaml'

room = Room.new :hell, "Hell"
door = LockedDoor.new([:door,:self], "A door", room, "password")
key  = Key.new(:key, "A key", "password")
room.things << key
key.takeable
door.takeable
room.things << door
fish = User.new(:fish, "A fish", room)
ham = User.new(:ham, "A ham", room)
ham.takeable
door.reply_random :what!, ["Hello", "How are you?"]
door.reply_list :fish!, ["What", "???"]
  
other = Room.new :other, "Another room"
doorway = Doorway.new [:doorway,:west], "Doorway", other

room.things << doorway
other.things << Doorway.new([:doorway2,:east], "Doorway", room)
other.things << Thing.new(:spoon, "A spoon")

open(ARGV[0],"w").write YAML.dump([room,[fish,ham]])
