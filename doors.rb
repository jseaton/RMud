class Door < Thing
  attr_accessor :room
  def initialize names, description, room
    super names, description
    @room = room
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
  def unlock user, key
    if user.pockets.send(:secret, user, key) == @secret
      @locked = false
      "You unlock the " + names(user)[0].to_s
    else
      "That is not the key"
    end
  end
end
