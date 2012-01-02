logger  = require "app/logger"
adaptor = new (require "lib/xmpp")()

exit = () ->
	adaptor.end () ->
		logger.notice "shutdown complete"
		process.exit()

# exit gracefully
process.on 'SIGHUP', exit
process.on 'SIGINT', exit

# go!
adaptor.start()
