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
      puts "go " + names(user)[0].to_s
      user.room.things.delete user
      user.room = @room
      @room.things << user
      @room.look! user
    end
    define_instance_method :visible? do |user|
      ct = user.room.container(user, self)
      p ct
      p self
      p user.room
      (not user.room == @room) or (ct == user.room or ct == user)
    end
  end

  define_shortcut(:takeable) do
    define_instance_method :take! do |user|
      user.things << self
      [user.room.delete(user,self)].flatten.compact.any? ? "You put the " + names(user)[0].to_s + " in your pocket" : "You cannot take the " + names(user)[0].to_s
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

  def initialize names, description
    @names       = names.class == Array ? names : [names]
    @description = description
    @reply_list  = {}
  end

  def names user
    @names
  end

  def description! user 
    @description #+ "\n" + self.inspect
  end
  
  alias :look! :description!

  def method_missing verb, user, *args
    "You cannot " + verb.to_s.chomp("!") + " the " + names(user)[0].to_s
  end

  def visible? user
    true
  end
end