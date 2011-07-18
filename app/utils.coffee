utils = module.exports = Spine.Class.create()

utils.extend
  getDate: ->
    today = new Date()
    h=today.getHours();
    m= if today.getMinutes() < 10 then '0'+today.getMinutes() else today.getMinutes()
    s= if today.getSeconds() < 10 then '0'+today.getSeconds() else today.getSeconds()
    h+':'+m