redis   = require 'redis'
resque 	= require 'coffee-resque'
logger 	= require 'app/logger'
config 	= require 'app/config'
consts  = require 'app/constants'

###

Resque queues and their methods:

	consts.user_queue
		this queue is a communication channel for workers to recieve 
		notifications about users which do not yet have an assigned worker via
		the sticky workers strategy.

		#new(username)
			sent when a new user is connected and awaiting handling.

	consts.write_queue
		this queue is a outward bound communication channel to request that the
		frontend send a message to a user.

		#send(username, message)
			sent to request a message be sent.

		#complete(username)
			sent to notify that the user is no longer active, and hence we can
			clean up anything related to that user.

	consts.read_queue(username)
		this queue is a inward bounhcommunication channel to notify the worker
		which is processing a particular users canversation, that a new message 
		has arrived that needs to be processed.

		#receive(username, message)
			sent to request a message be sent.

###

class XMPPAdapter

	# public
	constructor: () ->
		@rconn 	= @connectToRedis()
		@queue 	= @connectToQueue(@rconn)
		@xmpp  	= require('simple-xmpp')

	start: () ->
		@xmpp.on 'online', 	@online
		@xmpp.on 'chat', 	@receive
		@xmpp.on 'error', 	@error
		@xmpp.connect config.xmpp

	end: (callback) ->
		# shut down our services, except the redis connection
		@worker?.end()
		@queue.end()
		@xmpp.conn.end()
		@rconn.end()

		callback()

	# event handlers

	finished: () =>
		@rconn.del consts.actives_key(), (err, removed) ->
			logger.error "Couldn't clean up redis keys; please run `redis-cli rem #{consts.actives_key()}."
			logger.error err

	error: (err) =>
		logger.error err

	online: () =>
		logger.notice "online and listening"

		# now that we're online, start the worker
		debugger
		@worker = @createWorker(@queue)
		@worker.start()

	receive: (jid, message) =>
		logger.debug "incoming: [#{jid}] -> #{message}"

		# first, place the message on the recipients queue
		@queue.enqueue consts.read_queue(jid), "receive", [jid, message]

		# now, it will only get picked up if a worker is working with 
		# that user already. to get the user to a worker, if it's not
		# already, place the user on the new_user queue
		@rconn.sadd consts.actives_key(), jid, (err, added) =>
			unless err
				if added == 1
					logger.debug "unknown user: #{jid}, making available to workers..."
					@queue.enqueue consts.user_queue(), "new", [consts.read_queue(jid)]
			else
				logger.error "problem adding to active user set: #{err}"

	send: (jid, message) =>
		logger.debug "outgoing: [#{jid}] <- #{message}"
		@xmpp.send jid, message

	# private

	connectToRedis: () ->
		client = redis.createClient config.redis.port, config.redis.host
		client.auth(config.redis.password) if config.redis.password?
		client

	connectToQueue: (conn) ->
		resque.connect { redis: conn, timeout: config.xmpp.poll || 250 }

	createWorker: (queue) ->
		queue.worker consts.write_queue(),
			send: (jid, message, callback) ->
				@outgoing jid, message
				callback()

			complete: (jid, callback) ->
				@rconn.srem consts.actives_key(), jid
				callback()

module.exports = XMPPAdapter