resque = require 'coffee-resque'
cuckoo = require 'app/cuckoo'
config = require 'app/config'

clock = new cuckoo.Clock
queue = resque.connect config.redis

clock.every { minutes: 5 }, "say_hello", ->
	queue.enqueue "xmpp-out", 'send', ["jonraphaelson@gmail.com", "Good Morning, sir!"]
	
clock.start()