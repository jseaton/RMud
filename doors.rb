class Door < Thing
  attr_accessor :room
  def initialize names, description, room
    super names, description
    @room = room
  end

  def open! user
    "The door opens"
  end

  link
end

class Doorway < Window
  link
end

class LockedDoor < Door
  def initialize names, description, room, secret
    super names, description, room
    @locked = true
    @secret = secret
  end

  wrap :go! do |user,args,cb|
    @locked ? "The " + names(user)[0].to_s + " is locked" : cb.call(user,*args)
  end

  def unlock! user, *args
    return "You unlock a door with a key" if args.length != 1
    if user.all_forward(:secret, user, args[0]).member? @secret
      @locked = false
      "You unlock the " + names(user)[0].to_s
    else
      "That is not the key"
    end
  end

  def lock! user, *args
    return "You lock a door with a key" if args.length != 1
    if user.all_forward(:secret, user, args[0]).member? @secret
      @locked = true
      "You lock the " + names(user)[0].to_s
    else
      "That is not the key"
    end
  end

  wrap :open! do |user,args,cb|
    @locked ? "You cannot open the door" : cb.call(*args)
  end
end

class Key < Thing
  def initialize names, description, secret
    super names, description
    @secret = secret
  end
  reply_var :secret
end
