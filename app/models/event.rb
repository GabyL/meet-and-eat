require 'twilio-ruby'
require 'dotenv'

class Event < ActiveRecord::Base

  belongs_to :user

  has_many :venues, -> {order("id ASC")}
  has_many :guests, -> {order("id ASC")}
  has_many :votes

  scope :events_without_user, -> {where(user_id: nil)}

  def check_winning_venue(event)
    event.venues.each do |venue|
      @winning_venue ||= venue 
      if venue.votes.count > @winning_venue.votes.count        
        @winning_venue = venue 
      end
    end
    event.twilio_send_text(event, @winning_venue)
    event.sent_text = true
    event.save
  end

  def self.check_votes
    events = Event.where(sent_text: false)
    events.each do |event|
      if event.votes.count == event.guests.count
        check_winning_venue(event)
      end
    end
  end

  def self.check_time
    upcoming_events = Event.where(time: 90.minutes.ago..Time.now )
    upcoming_events.each do |event|
      if event.sent_text == false
        check_winning_venue(event)
      end
    end
  end

# => dude this is sensitive info... hide that shit
  def twilio_send_text(event, winning_venue)
    account_sid = ENV['TWILIO_SID']
    auth_token = ENV['TWILIO_TOKEN']
    client = Twilio::REST::Client.new account_sid, auth_token

    from = ENV['TWILIO_NUMBER']

    message_body = ""

    event.guests.each do |guest|
      client.account.messages.create(
        :from => from, 
        :to => guest.phone, 
        :body => "Hey #{guest.name}, the finalized venue for #{event.title} is #{winning_venue.name}. See you at #{event.correct_time}!"
      )
    end
  end
  
end







