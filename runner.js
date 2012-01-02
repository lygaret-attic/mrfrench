require('coffee-script')

app = process.argv[2]; // [node] [runner.js] [app]
require("app/" + app)