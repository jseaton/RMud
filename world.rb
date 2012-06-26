require './lib'
require 'yaml'

room = Room.new :hell, "Hell", nil
door = LockedDoor.new [:door,:self], "A door", room, room, "password"
key  = Key.new :key, "A key", room, "password"
key.takeable
door.takeable
fish = User.new(:fish, "A fish", room)
ham = User.new(:ham, "A ham", room)
ham.takeable
fish.takeable
door.reply_random :what!, ["Hello", "How are you?"]
door.reply_list :fish!, ["What", "???"]
  
other = Room.new :other, "Another room", nil
doorway = Doorway.new [:doorway,:west], "Doorway", room, other

doorway2 = Doorway.new [:doorway,:east], "Doorway", other, room
spoon = Thing.new :spoon, "A spoon", other

portal = Portal.new :portal, "A portal", room, nil
portal2 = Portal.new :portal2, "Another portal", room, portal
portal.other = portal2

doorway.define_method(:jam!, %q{ |user|
  "WAAAAAA"
})

open(ARGV[0],"w").write YAML.dump([room,[fish,ham]])
