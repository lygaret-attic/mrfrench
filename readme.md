# mrfrench
## a jabberbot designed to handle multi-part conversations.

Most chat bots I've seen respond corretly only to single inputs: they don't have the capacity to have multipart conversations. 
mrfrench uses sticky workers (on top of coffee-resque) and promises (on top of node-fibers) to enable the bot to ask questions of conversation partners.

### setup

1. install [foreman](https://github.com/ddollar/foreman) (`gem install foreman`)
1. move `app/_config.coffee` to `app/config.coffee` and edit with your relevant details.
1. `foreman start`!

### status

* basic conversation mode works
* working on sticky worker implementation so that workers can scale past a single process