require "sinatra"
require "rss"
require "json"

DATA_PATH = File.join File.expand_path(File.dirname(__FILE__)), 'data'

def latest_cost
  latest_file = `ls -tr #{DATA_PATH} | tail -n 1`
  content = `cat #{File.join(DATA_PATH, latest_file)}`
  OpenStruct.new JSON.parse(content)
end

def rss(data)
  RSS::Maker.make("2.0") do |maker|
    last_modified_time = Time.parse data.lastModifiedTime

    maker.channel.language = "en"
    maker.channel.author = "Allen Zheng"
    maker.channel.updated = last_modified_time.to_s
    maker.channel.link = "http://mapclipper.com/feeds/cost.rss"
    maker.channel.title = "AWS Cost Feed"
    maker.channel.description = "AWS Cost Feed"
  
    maker.items.new_item do |item|
      link = "http://mapclipper.com/aws_cost/#{last_modified_time.to_i}"
      item.link = link
      item.guid.content = link
      item.title = "AWS Cost $#{data.totalCost} @ #{last_modified_time}"
      item.updated = last_modified_time.to_s
    end
  end
end

get '/feeds/cost.rss' do
  content_type 'text/xml'
  rss(latest_cost).to_s
end
