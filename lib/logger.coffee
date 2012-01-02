{ Logger, Formatter, colors }  = require "caterpillar"

MyFormatter = class extends Formatter
	format: (levelCode,levelName,args) ->
		{date,file,line,method,color,levelName,message} = @details levelCode, levelName, args
		debugger
		if !message 
			message
		else
			color = color and colors[color] or (str) -> str
			message = "#{color(levelName)}: #{message}"

logger = new Logger
	transports:
		level: 7
		formatter: new MyFormatter
		
for own name, code of logger.config.levels
	do (name, code) ->
		exports[name] = (args...) ->
			args.unshift code 
			logger.log.apply(logger, args)