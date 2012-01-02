resque 	= require 'coffee-resque'
promise	= require 'fibers-promise'
logger 	= require 'lib/logger'
config 	= require 'app/config'
Talker  = require 'app/talker'

queue = resque.connect { host: config.redis.host, port: config.redis.port, timeout: 250 }
chats = {}

say = (to, message) -> 
	logger.debug "sending: [#{to}] -> #{message}"
	queue.enqueue "xmpp-out", "send", [to, message]
	
get = (from) -> 
	logger.debug "reading: [#{from}]"
	chats[from]?.get()
	
done = (to) ->
	logger.debug "conversation over"
	queue.enqueue "xmpp-out", "done", [to]

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
			
			done from			
			delete chats[from]

worker = queue.worker 'xmpp-incoming',
	new: (name, callback) ->
		logger.debug "new owner for #{name}"
		worker.queues.push name
		callback()
		
	recv: (args...) ->
		args.pop()()
		start.apply(@, args)

worker.start()
logger.notice "talker ready"
