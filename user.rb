require 'thread'

class Queue
  def to_yaml_properties
    []
  end
end

class User < BasicLook
  attr_accessor :queue
  def initialize names, desc, parent
    super names, desc, parent
    @queue = Queue.new
  end

  def rebuild user=nil
    super user
    @queue = Queue.new
  end

  def whisper! user, *message
    @queue << user.names(self)[0].to_s + " : " + message.map {|e| e.to_s }.join(" ") if user != self
    ""
  end

  def names user
    user == self ? [:pocket,:pockets] : super(user)
  end

  def visible? user
    user != self
  end

  def description! user
    user == self ? nil : super(user)
  end

  def look! user,*args
    if user == self or user.parent == self
      contents = super(user,*args)
      if args.any?
        contents
      else
        [user.parent == self ? "It's quite dark in here" : "In your pockets you have", contents[1].flatten.compact.any? ? contents[1] : ["Nothing"]]
      end
    elsif args == []
      description!(user)
    else
      nil
    end
  end

  def inspect
    "<#{self.class} #{@names[0].to_s} in #{@parent.instance_variable_get(:@names)[0].to_s} : #{@things.map {|e| e.instance_variable_get(:@names)[0].to_s } }>"
  end
end
