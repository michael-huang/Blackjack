require 'rubygems'
require 'sinatra'

set :sessions, true

BLACKJACK_AMOUNT = 21
DEALER_HIT_MIN = 17
INIT_PLAYER_POT = 500

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
    	total -= 10 if total > BLACKJACK_AMOUNT
  	end

  	total
	end

	def card_image(card)
		suit = case card[0]
			when 'S' then 'spades'
			when 'H' then 'hearts'
			when 'D' then 'diamonds'
			when 'C' then 'clubs'
		end

		value = card[1]
		if ['J', 'Q', 'K', 'A'].include?(value)
			value = case card[1]
				when 'J' then 'jack'
				when 'Q' then 'queen'
				when 'K' then 'king'
				when 'A' then 'ace'
			end
		end

		"<img src='/images/cards/#{suit}_#{value}.jpg' class='card_image' />"
	end

	def winner!(msg)
		@show_play_again = true
		@show_hit_or_stay_btn = false
		session[:player_pot] += session[:player_bet].to_i
		@success = "<strong>Congratulations, #{session[:player_name]} won!</strong> <br>#{msg}"
	end

	def loser!(msg)
		@show_play_again = true
		@show_hit_or_stay_btn = false
		session[:player_pot] -= session[:player_bet].to_i
		@error = "<strong>Sorry, #{session[:player_name]} lost.</strong> <br>#{msg}"
	end

	def tie!(msg)
		@show_play_again = true
		@show_hit_or_stay_btn = false
		@success = "<strong>It's tie.</strong> <br>#{msg}"
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
	session[:player_pot] = INIT_PLAYER_POT
	erb :new_player
end

post '/new_player' do
	if params[:player_name].empty?
		@error = "Name is required."
		halt erb :new_player
	end
	session[:player_name] = params[:player_name]
	redirect '/bet'
end

get '/bet' do
	erb :bet
end

post '/bet' do
	if params[:player_bet] == nil || params[:player_bet].to_i <= 0
		@error = "You must make a bet."
		halt erb :bet
	elsif params[:player_bet].to_i > session[:player_pot]
		@error = "Bet amount cannot be greater than what you have ($#{session[:player_pot]})"
		halt erb :bet
	else
		session[:player_bet] = params[:player_bet]
		redirect '/game'
	end
end

get '/game' do
	session[:turn] = session[:player_name]

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
	
	player_total = total(session[:player_cards])
	if player_total == BLACKJACK_AMOUNT
		winner!("You hit blackjack!")
		@show_hit_or_stay_btn = false
	elsif player_total > BLACKJACK_AMOUNT
		loser!("It seems like you busted!")
		@show_hit_or_stay_btn = false
	end
	erb :game
end

post '/game/player/stay' do
	@success = "#{session[:player_name]}, you have chosen to stay."
	@show_hit_or_stay_btn = false
	redirect '/game/dealer'
end

get '/game/dealer' do
	session[:turn] = "dealer"
	@show_hit_or_stay_btn = false

	# decision tree
	dealer_total = total(session[:dealer_cards])
	if dealer_total == BLACKJACK_AMOUNT
		loser!("Dealer hit blackjack.")
	elsif dealer_total > BLACKJACK_AMOUNT
		winner!("Dealer busted!")
	elsif dealer_total >= DEALER_HIT_MIN
		# dealer stay
		redirect '/game/compare'
	else
		# dealer hits
		@show_dealer_hit_btn = true
	end
	erb :game
end

post '/game/dealer/hit' do
	session[:dealer_cards] << session[:deck].pop
	redirect '/game/dealer'
end

get '/game/compare' do
	player_total = total(session[:player_cards])
	dealer_total = total(session[:dealer_cards])

	if dealer_total > player_total
		loser!("Dealer stay at #{dealer_total}, you stay at #{player_total}")
	elsif dealer_total < player_total
		winner!("Dealer stay at #{dealer_total}, you stay at #{player_total}")
	else
		tie!("Both of you stay at #{player_total}")
	end

	erb :game
end

get '/game_over' do
	erb :game_over
end
