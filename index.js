#!/usr/bin/env node
(function() {
	var stitch  = require('stitch'),
	express = require('express'),
	util    = require('util'),
	fs      = require('fs'),
	argv    = process.argv.slice(2),
	app 	= express.createServer(),
	io 		= require('socket.io').listen(app);

// stitch configuration
	stitch.compilers.tmpl = function(module, filename) {
		var content = fs.readFileSync(filename, 'utf8');
		content = ["var template = jQuery.template(", JSON.stringify(content), ");", 
		"module.exports = (function(data){ return jQuery.tmpl(template, data); });\n"].join("");
		return module._compile(content, filename);
	};

	var package = stitch.createPackage({
		paths: [__dirname + '/app'],
		dependencies: [
		__dirname + '/lib/json2.js',
		__dirname + '/lib/shim.js',
		__dirname + '/lib/jquery.js',
		__dirname + '/lib/jquery.tmpl.js',
		__dirname + '/lib/spine.js',
		__dirname + '/lib/spine.tmpl.js',
		__dirname + '/lib/spine.manager.js',
		__dirname + '/lib/spine.ajax.js',
		__dirname + '/lib/spine.local.js',
		__dirname + '/lib/spine.route.js'
		]
	});


//express server configuration
	app.configure(function() {
		app.set('views', __dirname + '/views');
		app.use(express.compiler({ src: __dirname + '/public', enable: ['less'] }));
		app.use(app.router);
		app.use(express.static(__dirname + '/public'));
		app.get('/application.js', package.createServer());
	});

//global variable

	var activeClients = 0,//number of clients connected
		chatList = [], // list of messages
		client = '', // reference to the socket
		clients = {}; // map clientId -> name

//when a user connect to the chat
	onConnect = function(data) {
	  console.log(clients)
	  
		//store his name
		var userExists = false
		for (var id in clients){
		  if (clients[id].name === data.name) {
		    userExists = true;
		    util.puts('user already exists')
		    
		    client.emit('userExists')
		    break;
		  };
		}
		
		if (!userExists) {
		  util.puts('new user')
		  
		  activeClients++;
      clients[client.id].name = data.name;
      // let the others know that a new user joint
      io.sockets.emit('userConnect', {
        clients: activeClients,
        user: data.name,
        state:'connect'
      });
      //send the previous chat messages to the new user
      client.emit('chatList', {
        chatList: chatList
      });

      //save the user connection message
      chatList.push({
        user: data.name,
        content: '',
        type: 'connect',
        date: data.time
      });
		};
	};
	
	//when a user disconnect from chat
	onDisconnect = function() {
		var name;
		activeClients--;
		name = clients[client.id].name;
		//delete the user
		clients[client.id]={name:''}
		//we let the others know that he's left
		io.sockets.emit('userConnect', {
			clients: activeClients,
			user: name,
			state:'disconnect'
		});
	};
	
	//when receiving a chat message we broadcast it to others
	onChatMessage = function(data) {
		//save message on server
		chatList.push(data);
		//broadcast message
		return io.sockets.emit('chatMessage', data);
	};

  //when a user connect to the socket
	io.sockets.on('connection', function(socket){
	  util.puts('socket connection')
		client = socket;
		clients[client.id] = {
			name: ''
		};
		client.on('userJoint', onConnect);
		client.on('disconnect', onDisconnect);
		return client.on('chatMessage', onChatMessage);
	});

//starting server
	var port = argv[0] || process.env.PORT || 9294;
	util.puts("Starting server on port: " + port);
	app.listen(port);
}).call(this);