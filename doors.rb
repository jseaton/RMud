class Thing
  define_shortcut(:link) do
    define_instance_method :go! do |user|
      user.parent.things.delete user
      user.parent = room(user)
      room(user).things << user
      room(user).look! user
    end
    define_instance_method :visible? do |user|
      ct = user.parent.container(user, self)
      (not user.parent == room(user)) or (ct == user.parent or ct == user)
    end
  end
end

class Door < Thing
  attr_accessor :room
  def initialize names, description, parent, room
    super names, description, parent
    @room = room
  end
  reply_var :room

  def open! user
    "The door opens"
  end

  link
end

class Doorway < Window
  link
end

class Portal < Door
  attr_accessor :other
  def initialize names, description, parent, other
    super names, description, parent, nil
    @other = other
  end

  takeable
    
  def room user
    @other.parent
  end
end
    

class LockedDoor < Door
  def initialize names, description, parent, room, secret
    super names, description, parent, room
    @locked = true
    @secret = secret
  end

  def go! user
    @locked ? "The " + names(user)[0].to_s + " is locked" : super(user)
  end

  def unlock! user, *args
    return "You unlock a door with a key" if args.length != 1
    keys = user.get_all(user, args[0])
    if not keys.any?
      "You don't have a " + args[0].to_s
    elsif keys[0].secret(user) == @secret
      @locked = false
      "You unlock the " + names(user)[0].to_s
    else
      "That is not the key"
    end
  end

  def lock! user, *args
    return "You lock a door with a key" if args.length != 1
    keys = user.get_all(user, args[0])
    if not keys.any?
      "You don't have a " + args[0]
    elsif keys[0].secret(user) == @secret
      @locked = true
      "You lock the " + names(user)[0].to_s
    else
      "That is not the key"
    end
  end

  def open! user
    @locked ? "You cannot open the door" : super(user)
  end
end

class Key < Thing
  def initialize names, description, parent, secret
    super names, description, parent
    @secret = secret
  end
  reply_var :secret
end
