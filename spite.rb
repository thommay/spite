require 'rubygems'
require 'sinatra'
require 'redis'
require 'haml'
require 'parsedate'
require 'yajl'

# spite is a very simple todo list
# things are either done or not, they have a due date, tags and a description.
#

set :haml, {:format => :html5, :escape_html => true}

configure :production do
  set :haml, {:ugly => true}
end

before do
  @redis = Redis.new
end

def load_items(ids)
  ids.map do |i|
    Yajl.load(@redis["spite-#{i}"] )
  end
end

helpers do
  def partial(name, opts={})
    haml name, opts.merge!(:layout=>false)
  end
  
  def tag_link(t)
    partial("%a{:href=>'/tags/#{t}', :title=>'View posts tagged #{t}'}> #{t}")
  end
end

get '/new/?' do
  haml :new
end

get '/tags/*' do
  @tag = params[:splat].first
  redirect '/' if @tag.empty?
  @spite = load_items @redis.set_diff("tags-#{@tag}", 'done-spite')
  haml :index
end

post '/create' do
  tags = params[:tags].gsub(/\s+/,'').split(',')
  spite_id = @redis.incr(:spite_counter)
  d = Time.local(*ParseDate.parsedate(params[:duedate]))
  @redis["spite-#{spite_id}"] = Yajl.dump({ :contents => params[:contents], :duedate => d.to_i, :tags =>tags, :id=>spite_id})
  @redis.set_add("all-spite", spite_id)
  
  tags.each{ |t| @redis.set_add("tags-#{t}", spite_id) }
  redirect '/'
end

post '/done' do
  id = params[:id]
  @redis.set_add("done-spite", id)
  redirect '/'
end

get '/done/?' do
  @spite = load_items @redis.set_members('done-spite')
  @done = true
  haml :index
end

get '/' do
  @spite = load_items(
    begin
      @redis.set_diff('all-spite', 'done-spite')
    rescue RedisError
      []
    end
  )
  haml :index
end


