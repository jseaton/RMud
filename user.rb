require 'thread'

class Queue
  def to_yaml_properties
    []
  end
end

class User < BasicLook
  attr_accessor :room, :queue
  def initialize names, desc, room
    super names, desc
    @room = room
    @room.things << self
    @queue = Queue.new
  end

  def rebuild user=nil
    @queue = Queue.new
  end

  def say! user, *message
    @queue << user.names(self)[0].to_s + " : " + message.map {|e| e.to_s }.join(" ") if user != self
    nil
  end

  wrap :names do |user,args,cb|
    user == self ? [:pocket,:pockets] : cb.call(user)
  end

  def visible? user
    user != self
  end

  wrap :description! do |user,args,cb|
    user == self ? nil : cb.call(user,*args)
  end

  wrap :look! do |user,args,cb|
    if user == self
      contents = cb.call(user,*args)
      #p contents
      if args.any?
        contents
      else
        ["In your pockets you have", contents[1].flatten.compact.any? ? contents[1] : ["Nothing"]]
      end
    elsif args == []
      description!(user)
    else
      nil
    end
  end

  def inspect
    "<#{self.class} #{@names[0].to_s} in #{@room.instance_variable_get(:@names)[0].to_s} : #{@things.map {|e| e.instance_variable_get(:@names)[0].to_s } }>"
  end
end
