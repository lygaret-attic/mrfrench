redis   = require 'redis'
resque 	= require 'coffee-resque'
xmpp 	= require 'simple-xmpp'
logger 	= require 'lib/logger'
config 	= require 'app/config'

# create the queue
rconn = redis.createClient config.redis.port, config.redis.host
rconn.auth(config.redis.password) if config.redis.password?
queue = resque.connect { redis: rconn, timeout: 250 }
worker = {}

handlers =
	online: () ->
		logger.notice "online and listening"
		
		# handle outgoing xmpp traffic
		worker = queue.worker "xmpp-out",
			send: (to, message, callback) ->
				handlers.send to, message
				callback()

			done: (to, callback) ->
				rconn.srem "active.convos", to
				callback()
		.start()
		
	error: (err) ->
		logger.error err
	
	recv: (from, message) ->
		logger.debug "incoming: [#{from}] -> #{message}"
		queue.enqueue "xmpp-incoming-#{from}", 'recv', [from, message]
		rconn.sadd "active.convos", from, (err, added) ->
			logger.debug "added active convos: #{added}, #{err}"
			unless err
				if added == 1
					queue.enqueue "xmpp-incoming", "new", ["xmpp-incoming-#{from}"]
			else
				logger.error "couldn't add to the active list: #{err}"
		
	send: (to, message) ->
		logger.debug "outgoing: [#{to}] <- #{message}"
		xmpp.send to, message
				
# handle incoming xmpp traffic
xmpp.on 'online', handlers.online
xmpp.on 'error', handlers.error
xmpp.on 'chat', handlers.recv
xmpp.connect config.xmpp
