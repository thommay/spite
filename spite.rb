require 'rubygems'
require 'sinatra'
require 'redis'
require 'haml'

# spite is a very simple todo list
# things are either done or not, they have a due date, tags and a description.
#

set :haml, :format => :html5
before do
  @redis = Redis.new
end
def load_items(ids)
  ids.map do |i|
    y = Marshal.load(@redis["spite-#{i}"] )
    y[:id] = i
    y
  end
end
  
get '/new/' do
  haml :new
end

post '/create' do
  tags = params[:tags].gsub(/\s+/,'').split(',')
  spite_id = @redis.incr(:spite_counter)
  @redis["spite-#{spite_id}"] = Marshal.dump({ :contents => params[:contents], :duedate => params[:duedate], :tags =>tags})
  @redis.set_add("all-spite", spite_id)
  
  tags.each{ |t| @redis.set_add("tags-#{t}", spite_id) }
  redirect '/'
end

get '/' do
  @spite = load_items(
    begin
      @redis.set_members('all-spite')
    rescue RedisError
      []
    end
  )
  haml :index
end


