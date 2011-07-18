module.exports = Spine.Controller.create
  tag: "li"
  proxied: ["render"]
  
  init: ->
	  this.msg.bind "update",  this.render
	  this
	##render a message, depending on the type we use different template
  render: ->
    if this.msg? && this.msg.type?
      switch this.msg.type
        when 'connect' then template = $("#msgConnectTmpl")
        when 'disconnect' then template = $("#msgDisconnectTmpl")
        else template = $("#msgTalkTmpl")
      this.el.html template.tmpl this.msg
      ##this.refreshElements()
      this
