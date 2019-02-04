require 'bundler'
Bundler.require
require 'discordrb/webhooks'
require 'open-uri'


class TrelloDiscord < Sinatra::Base
  def initialize *args
    Dotenv.load
    init_discord
    super
  end

  def init_discord
    @discord = Discordrb::Webhooks::Client.new(url: ENV['DISCORD_WEBHOOK_URL'])
  end

  get '/' do
    'hi'
  end
  
  post '/' do
    json = JSON.parse request.body.read, symbolize_names: true
    puts JSON.pretty_generate(json)
    action_type = json[:action][:type]
    card_name = json[:action][:data][:card][:name]
    user_name = json[:action][:memberCreator][:username]
    short_link = 'https://trello.com/c/' + json[:action][:data][:card][:shortLink]
    case action_type
    when 'commentCard'
      title = 'コメント'
      list_name = json[:action][:data][:list][:name]
      text = json[:action][:data][:text]
      message = "#{user_name}さんが「#{list_name}」の「#{card_name}」にコメントしました\n#{short_link}"
    when 'createCard'
      title = 'カード作成'
      list_name = json[:action][:data][:list][:name]
      text = card_name
      message = "#{user_name}さんが「#{list_name}」に「#{card_name}」を作成しました\n#{short_link}"
    when 'updateCheckItemStateOnCard'
      if 'complete' == json[:action][:data][:checkItem][:state]
        title = 'チェックボックスON'
      else
        title = 'チェックボックスOFF'
      end
      text = card_name
      checklist = json[:action][:data][:checklist][:name]
      checkitem = json[:action][:data][:checkItem][:name]
      message = "#{user_name}さんが「#{card_name}」のチェックリスト「#{checklist}」の「#{checkitem}」に#{title}しました\n#{short_link}"
    when 'addAttachmentToCard'
      title = 'ファイル添付'
      list_name = json[:action][:data][:list][:name]
      text = json[:action][:data][:attachment][:name]
      message = "#{user_name}さんが「#{list_name}」の「#{card_name}」に「#{text}」を添付しました\n#{short_link}"
    else
      return
    end
    embeds = [Discordrb::Webhooks::Embed.new(
      timestamp: Time.now,
      title: title,
      description: text
    )]
    file = nil
    if action_type == 'addAttachmentToCard'
      open(json[:action][:data][:attachment][:url]) do |file|
        open(text, 'w+b') do |out|
          out.write(file.read)
        end
      end
      file = open(text)
    end
    builder = Discordrb::Webhooks::Builder.new(content: message, embeds: embeds, file: file)
    begin
      @discord.execute(builder)
    rescue RestClient::ExceptionWithResponse => e
      p e.http_body
    end
    if action_type == 'addAttachmentToCard'
      file.close
      File.unlink text
    end
  end
end
