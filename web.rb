require 'bundler'
Bundler.require
require 'discordrb/webhooks'


class TrelloDiscord < Sinatra::Base
  def initialize *args
    Dotenv.load
    init_discord
    super
  end

  def init_discord
    p ENV
    @discord = Discordrb::Webhooks::Client.new(url: ENV['DISCORD_WEBHOOK_URL'])
  end

  get '/trello-discord' do
    'hi'
  end
  
  post '/trello-discord' do
    json = JSON.parse request.body.read, symbolize_names: true
    puts json
    action_type = json[:action][:type]
    list_name = json[:action][:data][:list][:name]
    card_name = json[:action][:data][:card][:name]
    user_name = json[:action][:memberCreator][:username]
    short_link = 'https://trello.com/c/' + json[:action][:data][:card][:shortLink]
    case action_type
    when 'commentCard'
      title = 'コメント'
      text = json[:action][:data][:text]
      message = "#{user_name}さんが#{list_name}の#{card_name}にコメントしました\n#{short_link}"
    when 'createCard'
      title = 'カード作成'
      text = card_name
      message = "#{user_name}さんが#{list_name}に#{card_name}を作成しました\n#{short_link}"
    else
      return
    end
    @discord.execute do |builder|
      builder.content = message
      builder.add_embed do |embed|
        embed.title = title
        embed.description = text
        embed.timestamp = Time.now
      end
    end
  end
end
