logging = require "caterpillar"
fs 		= require "fs"
config 	= require "app/config"

logging.Formatter::getLineInfo = ->
	# Prepare
	result =
		line: -1
		method: 'unknown'

	# Retrieve
	try
		throw new Error()
	catch e
		lines = e.stack.split('\n')
		for line in lines
			continue if line.indexOf('caterpillar.coffee') isnt -1 or line.indexOf('logger.coffee') isnt -1 or line.indexOf(' at ') is -1
			parts = line.split(':')
			if parts[0].indexOf('(') is -1
				result.method = 'unknown'
				result.file = parts[0].replace(/^.+?\s+at\s+/, '')
			else
				result.method = parts[0].replace(/^.+?\s+at\s+/, '').replace(/\s+\(.+$/, '')
				result.file = parts[0].replace(/^.+?\(/, '')
			result.line = parts[1]
			break
	return result

MyFormatter = class extends logging.Formatter
	format: (levelCode,levelName,args) ->
		debugger
		{date,file,line,method,color,levelName,message} = @details levelCode, levelName, args
		if !message 
			message
		else
			color = color and logging.colors[color] or (str) -> str
			message = "#{color(levelName)}: #{message}"

FileFormatter = class extends logging.Formatter
	format: (levelCode,levelName,args) ->
		{date,file,line,method,color,levelName,message} = @details levelCode, levelName, args
		file = file.split('/')[-2..].join("/") if file?	
		message = "[#{date}] [#{file}: #{line}] [#{method}] "+@padLeft(' ', 10, "#{levelName}:")+" #{message}"

FileTransport = class extends logging.Transport
	constructor: (args...) ->
		FileTransport.__super__.constructor.apply(this, args)
		if config.logging.file?
			@file = fs.createWriteStream config.logging.file, { flags: "a", encoding: "ascii" }
			@fileformat = new FileFormatter
			@file.on 'error', (err) =>
				@file = null
				exports.error "Couldn't write to log file! (#{err})"

	write: (levelCode,levelName,message) ->
		_message = message
		message = super levelCode, levelName, message
		if message?
			console.log message
			if @file?
				message = @fileformat.format levelCode, levelName, _message
				@file.write message + "\n"

logger = new logging.Logger
	transports: new FileTransport
		level: config.logging.level || 5
		formatter: new MyFormatter
		
for own name, code of logger.config.levels
	do (name, code) ->
		exports[name] = (args...) ->
			args.unshift code 
			logger.log.apply(logger, args)