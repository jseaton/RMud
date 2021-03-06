class Disambiguation < Array
end

class Container < Thing
  attr_accessor :things
  
  def initialize names, description, parent, things=[]
    super names, description, parent
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

  def rebuild user=nil
    super user
    collate :rebuild, user
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

  def get user, name
    @things.select do |th|
      th.names(user).member? name
    end
  end

  def dis_forward message, user, name, *args
    p [:forward, message, user, name, args]
    all = get_all(user, name)
    p all
    if all.length == 1
      all[0].send message, user, *args
    elsif all.length == 0
      nil
    else
      Disambiguation.new all
    end
  end

  def all_forward message, user, name, *args
    get_all(user, name).map do |thing|
      thing.send message, user, *args[2..-1]
    end
  end

  def get_all user, name
    #p [self, name, user]
    ret = get user, name
    @things.each do |thing|
      begin
        ret += thing.get_all user, name if thing.respond_to? :get_all
      rescue
      end
    end.compact
    ret
  end

  def method_missing message, user, *args
    return "You cannot " + message.to_s[0..-2] + " the " + names(args[0])[0].to_s if args.length == 0
    dis_forward message, user, *args
  end

  def inspect
    "<#{self.class} #{@names[0].to_s} #{@things.map {|e| e.instance_variable_get(:@names)[0].to_s } }>"
  end

  def inventory! user
    user.look! user
  end 
end

class BasicLook < Container
  reply_collate :look!, :description!
  wrap :look! do |user,args,cb|
    [description!(user), cb.call]
  end
  wrap_pass :look!
end

class Room < BasicLook
  def look! user, *args
    vis = args.any? ? [] : @things.select do |thing| 
       thing.respond_to?(:go!) and thing.visible?(user)
     end.map do |thing| 
       thing.names(user).select do |name|
         [:north, :south, :east, :west].member? name
       end
     end.flatten
    vis.any? ? [super(user,*args), "There are exits to the " + vis.join(", ")] : super(user,*args)
  end

  def method_missing message, user, *args
    return "You cannot " + message.to_s[0..-2] if args.length == 0
    dis_forward message, user, *args
  end
end

class Window < Thing
  reply_var :room
  def look! user
    [description!(user), room(user).look!(user)]
  end

  def initialize names, description, parent, room
    super names, description, parent
    @room = room
  end
end
