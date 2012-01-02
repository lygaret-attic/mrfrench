# mrfrench
## a jabberbot designed to handle multi-part conversations.

Most chat bots I've seen respond corretly only to single inputs: they don't have the capacity to have multipart conversations. 
mrfrench uses sticky workers (on top of coffee-resque) and promises (on top of node-fibers) to enable the bot to ask questions of conversation partners.

### setup

#### get libs
1. `git submodule init`
1. `cd third_party/coffee-resque-sticky`
1. `npm link`
1. `cd ..\\.. && npm link coffee-resque-sticky`

#### setup and run
1. `cp app/_config.coffee app/config.coffee && vi app/config.coffee`
1. install [foreman](https://github.com/ddollar/foreman) (`gem install foreman`)
1. `foreman start`!

### status

* basic conversation mode works
* working on sticky worker implementation so that workers can scale past a single process