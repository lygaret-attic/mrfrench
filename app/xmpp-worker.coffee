resque 	= require 'coffee-resque'
promise	= require 'fibers-promise'
logger 	= require 'lib/logger'
config 	= require 'app/config'
Talker  = require 'app/talker'

queue = resque.connect config.redis
chats = {}

say = (to, message) -> 
	logger.debug "sending: [#{to}] -> #{message}"
	queue.enqueue "xmpp-out", "send", [to, message]
	
get = (from) -> 
	logger.debug "reading: [#{from}]"
	chats[from]?.get()

start = (from, message) ->
	if chats[from]?
		logger.debug "continuing: [#{from}] -> #{message}"
		chats[from].set(message)
	else
		promise.start ->
			logger.notice "new convo: [#{from}] -> #{message}"

			_say = (args...) -> 
				args.unshift(from)
				say.apply(@, args)
			_get = (args...) -> 
				args.unshift(from)
				get.apply(@, args)

			chats[from] = promise()
			talker = new Talker _say, _get
			talker.talk()
			logger.notice "convo over: [#{from}]"			
			delete chats[from]

worker = queue.worker 'xmpp-in', 
	recv: (args...) ->
		args.pop()()
		logger.debug "beep", args
		start.apply(@, args)
		logger.debug "boop"

worker.start()
logger.notice "talker ready"