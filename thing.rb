require './sproc'

class Thing
  attr_accessor :parent, :pmethods
  def self.define_shortcut shortcut_name, &block
    self.send :define_method, shortcut_name do |*args|
      self.instance_eval do
        @pmethods << [shortcut_name, :shortcut, args] if not @pmethods.select {|e| e[0] == shortcut_name }.any?
      end
      self.instance_exec(*args, &block)
    end
    define_singleton_method shortcut_name, &block 
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

  define_shortcut(:takeable) do
    define_instance_method :take! do |user|
      user.things << self
      if [user.parent.delete(user,self)].flatten.compact.any?
        @names -= [:north, :south, :east, :west]
        @parent = user
        user.parent.collate :whisper!, user, "Takes the " + names(user)[0].to_s
        "You put the " + names(user)[0].to_s + " in your pocket"
      else
        "You cannot take the " + names(user)[0].to_s
      end
    end
    define_instance_method :put! do |user|
      if user.things.delete self
        user.parent.things << self
        @parent = user.parent
        user.parent.collate :say!, user, "Puts down the " + names(user)[0].to_s
        "You put the " + names(user)[0].to_s + " down"
      else
        "You don't have the " + names(user)[0].to_s
      end
    end
  end

  define_shortcut(:reply_var) do |name|
    define_instance_method name do |user|
      instance_variable_get ("@"+name.to_s).to_sym
    end
  end

  def self.wrap name, &wrapper
    wrapee = instance_method name
    define_instance_method name do |user,*args|
      self.instance_exec(user, args, proc do wrapee.bind(self).call(user,*args) end, &wrapper)
    end
  end

  def wrap name, wrapper_s, record=true
    wrapper = wrapper_s.respond_to?(:call) ? wrapper_s : SProc.new(wrapper_s)
    if record
      @pmethods << [name, :wrapping, wrapper]
    end
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
        cb.call
      end
    end
  end

  def wrap_pass name
    wrap(name, %q{ |user,args,cb|
           if args.any?
             method_missing name, user, *args
           else
             cb.call
           end
         })
  end

  def define_method name, proc
    aproc = proc.respond_to?(:call) ? proc : SProc.new(proc)
    @pmethods << [name, :method, aproc]
    define_instance_method name, &aproc
  end

  def initialize names, description, parent
    @names       = names.class == Array ? names : [names]
    @description = description
    @parent      = parent
    @pmethods    = []
    @reply_list  = {}
    @parent.things << self if @parent
  end

  def rebuild user=nil
    @pmethods.each do |name,type,args|
      case type
      when :shortcut
        send name, *args
      when :method
        define_instance_method name, &args
      when :wrapping
        wrap name, args, false
      end
    end
  end

  def names user
    @names
  end

  def look! user 
    @description
  end
  
  def description! user
    @description if visible? user
  end

  def method_missing verb, user, *args
    "You cannot " + verb.to_s.chomp("!") + " the " + names(user)[0].to_s
  end

  def visible? user
    true
  end

  def inspect
    "<#{self.class} #{@names[0].to_s}>"
  end
end
