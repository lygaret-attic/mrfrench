module.exports =	
	actives_key: 	() -> "resque:active.users"
	user_queue: 	() -> "user"
	read_queue: 	(user) -> "read.#{user}"
	write_queue: 	() -> "write"