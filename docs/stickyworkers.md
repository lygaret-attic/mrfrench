# sticky workers

## current flow

1. a client sends a message.
1. the xmpp frontend gets the message and posts it to the `xmpp-in` queue.
1. a worker gets the message from the queue ands starts having a conversation.
    1. the worker posts `say` messages to a `xmpp-out` queue, which are forwarded to the client
	   by the xmpp frontend.
	1. the worker can wait for input by blocking on a promise.
1. **that same worker** gets another message from the same person, which resolves the promise, unblocking the talker and continuing the conversation.
    
## problem

the phrase "**that same worker**"

the general way that the system works doesn't provide for scalability of talker processes: since the talker has to maintain a list of active promises (one for each ongoing conversation), and those promises are tied to the process (ie can't be serialized out as state (vm level objects)), there currently isn't a way to run multiple talkers. if we did, in the current system, we'd end up with each talker process starting conversations, and non-deterministically picking one to get input on every input event.

## solution

sticky workers solves this problem by adding a second level of job queuing to the system:

1. client sends a message
1. the xmpp frontend gets the message
    1. the xmpp frontend posts the message to the queue named after the user the message came from.
	1. the xmpp frontend then does a checkset to a "active conversations" set in redis:
        `sadd active.convos [from]`	
		which returns 1 (if the address was not in the set) or 0 (if it was). 
	1. if the address was NOT in the set, the frontend ALSO posts the address to the `incoming.convo` queue.
1. the workers are polling on a list af queues, which initially is only the `incoming.convo` queue.
1. when the worker gets a message on the `incoming.convo` queue, it adds the address to it's list of queues to listen on, and starts listening on it.
1. the original message will be delivered, and the worker will process it
1. start again at the beginning: this time, the `active.convos` set will return 0, the `incoming.convo` queue doesn't get anything, so new workers won't see it, and the original worker is already listening for messages for the particular address.