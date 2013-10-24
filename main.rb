require 'rubygems'
require 'sinatra'

set :sessions, true

helpers do
	def total(cards)
		arr = cards.map{|element| element[1]}
		total = 0
		arr.each do |value|
		if value == "A"
      		total += 11
    	elsif value.to_i == 0
      		total += 10
    	else
      		total += value.to_i
      	end
    end

    arr.select{|element| element == "A"}.count.times do
    	total -= 10 if total > 21
  	end

  	total
	end
end

before do
	@show_hit_or_stay_btn = true
end

get '/' do
  if session[:player_name]
  	redirect '/game'
  else
  	redirect '/new_player'
  end
end

get '/new_player' do
	erb :new_player
end

post '/new_player' do
	session[:player_name] = params[:player_name]
	redirect '/game'
end

get '/game' do
	# create a deck and put it in session
	suits = ['S', 'H', 'D', 'C']
	values = ['2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K', 'A']
	session[:deck] = suits.product(values).shuffle!

	# deal cards
	session[:dealer_cards] = []
	session[:player_cards] = []
	session[:dealer_cards] << session[:deck].pop
	session[:player_cards] << session[:deck].pop
	session[:dealer_cards] << session[:deck].pop
	session[:player_cards] << session[:deck].pop

	erb :game
end

post '/game/player/hit' do
	session[:player_cards] << session[:deck].pop
	if total(session[:player_cards]) > 21
		@error = "Sorry, it seems like you busted!"
		@show_hit_or_stay_btn = false
	end
	erb :game
end

post '/game/player/stay' do
	@success = "You have chosen to stay."
	@show_hit_or_stay_btn = false
	erb :game
end
