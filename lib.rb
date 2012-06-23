class Thing
  def self.define_shortcut shortcut_name, &block
    self.send :define_method, shortcut_name, block
    define_singleton_method shortcut_name, block
  end

  def self.define_instance_method name, &block
    self.send :define_method, name, block
  end

  def define_instance_method name, &block
    define_singleton_method name, block
  end

  alias :instance_method :method
    
  define_shortcut(:reply_random) do |name,replies|
    define_instance_method name do |user|
      replies.sample
    end
  end

  define_shortcut(:reply_one) do |name,reply|
    define_instance_method name do |user|
      reply
    end
  end

  define_shortcut(:reply_list) do |name,replies|
    define_instance_method name do |user|
      @reply_list[name] ||= {}
      @reply_list[name][user.hash] ||= -1
      @reply_list[name][user.hash] += 1
      replies[@reply_list[name][user.hash] < replies.length ? @reply_list[name][user.hash] : -1]
    end
  end

  define_shortcut(:link) do
    define_instance_method :go! do |user|
      user.room.things.delete user.avatar
      user.room = @room
      @room.things << user.avatar
      @room.look! user
    end
  end

  def self.wrap name, &wrapper
    wrapee = instance_method name
    define_instance_method name do |user,*args|
      self.instance_exec(user, args, proc do wrapee.bind(self).call(user,*args) end, &wrapper)
    end
  end

  def wrap name, &wrapper
    wrapee = method name
    define_instance_method name do |*args|
      wrapper.call(user, args, proc do wrapee.call(user,*args) end)
    end
  end

  def initialize names, description
    @names       = names.class == Array ? names : [names]
    @description = description
    @reply_list  = {}
  end

  attr_accessor :names

  def description! user 
    @description
  end
  
  alias :look! :description!

  def self.wrap_pass name
    wrap name do |user,args,cb|
      if args.any?
        method_missing name, user, *args
      else
        cb.call name, user, *args
      end
    end
  end

  def wrap_pass name
    wrap name do |user,args,cb|
      if args.any?
        method_missing name, user, *args
      else
        cb.call(name, user, *args)
      end
    end
  end

  def method_missing verb, user, *args
    "You cannot " + verb.to_s[0..-2] + " the " + @names[0].to_s
  end
end

class Container < Thing
  attr_accessor :things
  
  def initialize names, description, things=[]
    super names, description
    @things = things
  end
  
  def collate message, user, *args
    @things.map do |thing|
      begin
        thing.send message, user, *args unless thing == user.avatar
      rescue
        nil
      end
    end.compact
  end

  define_shortcut(:reply_collate) do |name,message|
    define_instance_method name do |user,*args|
      collate message, user, *args
    end
  end

  def method_missing message, *args
    return "You cannot " + message.to_s[0..-2] if args.length == 1
    user = args[0]
    name = args[1]
    thing = @things.select do |thing|
      thing.names.member? name
    end[0]
    thing ? thing.send(message, user, *args[2..-1]) : nil
  end
end

class Room < Container
  reply_collate :look!, :description!
  wrap :look! do |user,args,cb|
    [description!(user), cb.call(user,*args)]
  end
  wrap_pass :look!
end

class Door < Thing
  def initialize names, description, room
    super names, description
    @room = room
  end

  link
end

class Window < Container
  reply_collate :look!, :look!
  wrap :look! do |user,args,cb|
    [description!(user), cb.call(user,*args)]
  end
  def initialize names, description, room
    super names, description, [room]
  end
end

class Doorway < Window
  def initialize names, description, room
    super names, description, room
    @room = room
  end
  link
end

class Avatar < Thing
end

class User
  attr_accessor :avatar, :room
  def initialize avatar, room
    @avatar = avatar
    @room   = room
  end
end
