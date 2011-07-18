Message = require('models/Message')
Messages = require('controllers/Messages')
utils = require('./utils')
module.exports = Spine.Controller.create
  events:
    "click .enter": "enterChatRoom"
    "keydown input[name=user_name]": 'enterChatRoom'
    "click .send": "send"
    "keydown input[name=message]" : 'send'
  proxied: [
    'send',
    'initChat',
    'addMessage',
    'onUserConnect',
    'enterChatRoom',
  ]
  elements:
    ".count"                : "count"
    "#client_count"         : "clientCount"
    'input[name=user_name]' : "nameField"
    'input[name=message]'   : 'messageField'
    '.name'                 : "nameArea"
    '.message'              : "messageArea"
    '#chatList'             : "chatList"
  
  init: ->
    #when we create a Message, we run addMessage
    Message.bind "create",  this.addMessage
    #focus on name field
    this.nameField.focus()
    
  #notify the server for a new message sent 
  send: (e) ->
    if (e.type=='click' || (e.type=='keydown' && e.keyCode==13))
      data = user: this.userName
      content: this.messageField.val()
      type:'talk'
      time:utils.getDate()
      
      this.messageField.val('').focus()
      this.socket.emit 'chatMessage', data
  
  ## when a message is received from the server  
  updateChat: (data) ->
    Message.create(user: data.user
    content: data.content
    type:data.type
    time:data.time)
  
  ##when we reiceve the chat list, we initialize the conversation
  initChat: (data)->
    this.nameArea.addClass 'hide'
    this.messageArea.removeClass 'hide'
    this.messageField.focus()
    ##display all previous messages
    for data in data.chatList
      Message.create(user: data.user
      content: data.content
      type:data.type
      time:data.time)
    ##create the 'user joint' message     
    Message.create(user: this.userName,
    content: ''
    type:'connect'
    time:utils.getDate())
  
  ##when a Message is created
  addMessage: (msg) ->
    view = Messages.init msg: msg
    this.chatList.append view.render().el
  
  userExists: ->
    alert('user already exists.')
    this.socket.emit('disconnect')
    this.nameField.focus()
    
  
  ##run when a user join/leave the chat  
  onUserConnect: (msg) ->
    ## update client counter
    if msg.clients?	
      this.clientCount.html msg.clients 
    ## a user join
    if msg.user? && msg.user != this.userName && msg.state == 'connect'
      Message.create(user: msg.user,
      content: ''
      type:'connect'
      time:utils.getDate())
    ## a user leave 
    if msg.user? && msg.state == 'disconnect'
      Message.create(user: msg.user,
      content: ''
      type:'disconnect'
      time:utils.getDate())    
            
  
  enterChatRoom: (e) ->
    if (e.type=='click' || (e.type=='keydown' && e.keyCode==13))
      ##get the user name
      this.userName = this.nameField.val()
      ## we open the connection
      this.socket = io.connect()
      ## bind socket messages to functions
      this.socket.on 'userConnect', this.onUserConnect
      this.socket.on 'chatMessage', this.updateChat
      this.socket.on 'chatList', this.initChat
      this.socket.on 'userExists', this.userExists
      ## notify the server for a new user
      this.socket.emit 'userJoint', {name:this.userName, time:utils.getDate()}