# mrfrench
## a jabberbot designed to handle multi-part conversations.

Most chat bots I've seen respond correctly only to single inputs: they don't have the capacity to have multipart conversations. 
mrfrench uses sticky workers (on top of coffee-resque) and promises (on top of node-fibers) to enable the bot to ask questions of conversation partners.

### pre-reqs
1. [npm](http://npmjs.org)
1. [foreman](https://github.com/ddollar/foreman) (`gem install foreman`)

### setup
1. `npm install`
1. `cp app/_config.coffee app/config.coffee && vi app/config.coffee`

### run!
1. `foreman start`!

### status

* basic conversation mode works
* working on sticky worker implementation so that workers can scale past a single process