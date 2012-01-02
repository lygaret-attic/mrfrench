resque 	= require 'coffee-resque'
xmpp 	= require 'simple-xmpp'
logger 	= require 'lib/logger'
config 	= require 'app/config'

handlers =
	online: () ->
		logger.notice "online and listening"
		
	error: (err) ->
		logger.error err
	
	recv: (from, message) ->
		logger.debug "incoming: [#{from}] -> #{message}"
		queue.enqueue "xmpp-in", 'recv', [from, message]
		
	send: (to, message) ->
		logger.debug "outgoing: [#{to}] <- #{message}"
		xmpp.send to, message
				
# handle incoming xmpp traffic
queue = resque.connect config.redis
xmpp.on 'online', handlers.online
xmpp.on 'error', handlers.error
xmpp.on 'chat', handlers.recv
xmpp.connect config.xmpp

# handle outgoing xmpp traffic
queue.worker "xmpp-out",
	send: (to, message, callback) ->
		handlers.send to, message
		callback()
.start()