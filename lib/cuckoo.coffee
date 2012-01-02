_		= require 'underscore'
moment 	= require 'moment'
logger 	= require 'lib/logger'

doEvery = (ms, cb) -> setInterval cb, ms
noMore  = (id) -> clearInterval(id)

debugger

class Clock
	constructor: (@base = moment(), @resolution = { seconds: 1 }, @events = []) ->
		@base = moment(@base)
		@resolution = to_ticks(@resolution)

	every: (period, callbacks...) ->
		logger.note "registering new event: #{e}"
		e = new Event(to_ticks(period), callbacks)
		@events.push e
	
	start: () ->
		logger.note "started running every #{@resolution/1000.0} seconds"
		stop() if @running?
		@tank = doEvery @resolution, () => @tick()
		
	stop: () ->
		logger.note "stopped running"
		noMore @task if @running?
		delete @running
		
	tick: (now = moment()) ->
		e.run now for e in @events when e.isTime now
		return
		
class Event
	constructor: (@ticks, @callbacks) ->
		part = if _.isFunction @callbacks[0] then _.uniqueId() else @callbacks.shift()
		@name = "job:#{part}" 
		
	isTime: (now) ->
		not @last? or now.diff(@last) >= @ticks
	
	run: (@last) ->
		logger.alert @name
		for callback in @callbacks
			try
				callback(@last)
			catch error
				logger.error "Error running job: ", @name
				console.trace()
	
to_ticks = (p) ->
	ticks = (p.years ?= 0) * 365 * 30 * 24 * 60 * 60 * 1000
	ticks += (p.months ?= 0) * 30 * 24 * 60 * 60 * 1000
	ticks += (p.days ?= 0) * 24 * 60 * 60 * 1000
	ticks += (p.hours ?= 0) * 60 * 60 * 1000
	ticks += (p.minutes ?= 0) * 60 * 1000
	ticks += (p.seconds ?= 0) * 1000
	ticks += (p.milliseconds ?= 0)
	
next_from = (base, period, now = moment()) ->
	future = moment(base).add(period)
	while now > future
		future = now.add(period)
		
	return future

	
exports.Clock = Clock