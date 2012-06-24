class Container < Thing
  attr_accessor :things
  
  def initialize names, description, things=[]
    super names, description
    @things = things
  end
  
  def collate message, user, *args
    @things.map do |thing|
      begin
        thing.send message, user, *args
      rescue
        nil
      end
    end.compact.select do |response|
      response != []
    end
  end

  def container user, thing
    if @things.member?(thing)
      self
    else 
      collate(:container, user, thing).select do |thing|
        thing.is_a? Thing
      end[0]
    end
  end

  define_shortcut(:reply_collate) do |name,message|
    define_instance_method name do |user,*args|
      collate message, user, *args
    end
  end

  def delete user, thing
    if @things.member? thing
      true if @things.delete thing
    else
      collate :delete, user, thing
    end
  end

  def forward message, *args
    user = args[0]
    name = args[1]
    forward_method message, user, name, *args[2..-1]
  end

  def get user, name
    @things.select do |th|
      th.names(user).member? name
    end[0]
  end

  def forward_method message, user, name, *args
    #p [self, message, name, user, args]
    thing = get user, name
    return thing.send(message, user, *args) if thing
    @things.map do |thing|
      begin
        reply = thing.forward message, user, name, *args if thing.respond_to? :forward
        return reply if reply
      rescue
        nil
      end
    end
    nil
  end

  def method_missing message, *args
    return "You cannot " + message.to_s[0..-2] if args.length == 1
    forward message, *args
  end

  def inspect
    "<#{self.class} #{@names[0].to_s} #{@things.map {|e| e.instance_variable_get(:@names)[0].to_s } }>"
  end
end

class BasicLook < Container
  reply_collate :look!, :description!
  wrap :look! do |user,args,cb|
    [description!(user), cb.call(user,*args)]
  end
  wrap_pass :look!
end

class Room < BasicLook
  wrap :look! do |user,args,cb|
    vis = args.any? ? [] : @things.select do |thing| 
       thing.respond_to?(:go!) and thing.visible?(user)
     end.map do |thing| 
       thing.names(user).select do |name|
         [:north, :south, :east, :west].member? name
       end
     end.flatten
    cb.call(user,*args) + (vis.any? ? ["There are exits to the " + vis.join(", ")] : [])
  end
end

class Window < Thing
  attr_accessor :room
  wrap :look! do |user,args,cb|
    [description!(user), room.look!(user)]
  end

  def initialize names, description, room
    super names, description
    @room = room
  end
end
