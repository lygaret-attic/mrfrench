class Talker
	constructor: (@say, @get) ->
		
	talk: (from) ->
		@say "Good morning, sir."
		@say "May I ask your name?"
		
		name = @get()
		@say "Thank you, #{name}. I'll remember that."
		
		###
		@say "From here on out, I'm simply a parrot."
		loop
			text = @get()
			@say "#{name} said: #{text}"
		###
			
module.exports = Talker