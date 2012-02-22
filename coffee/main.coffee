
###

HZK

(c) 2012 Thom Chiovoloni
###

window.requestAnimFrame = 
  window.requestAnimationFrame or
  window.webkitRequestAnimationFrame or
  window.mozRequestAnimationFrame or
  window.oRequestAnimationFrame or
  window.msRequestAnimationFrame or
  (callback, element) ->
    window.setTimeout callback, 16.666

DEBUG = true
WIDTH = 720
HEIGHT = 480

class Game
  constructor: (@game) ->
    [@ticks, @fps, @tickDur] = [0, 0, 0]
    @running = false

  dispFPS: ->
    @fpsElem or= document.getElementById "fps"
    @fpsElem.innerHTML = parseInt @fps    

  log: ->
    console.log(arguments) if DEBUG

  start: ->
    @log "starting main loop"
    @canvas = document.getElementsByTagName("canvas")[0]
    @ctx = @canvas.getContext "2d"
    
    @loopStart = new Date().getTime()
    @lastTick = new Date().getTime()
    @lastFPSDisp = new Date().getTime()
    
    @running = true
    @game.init @ if @game.init?
    requestAnimFrame =>
      @loop()
    @log "done starting main loop"

  stop: ->
    @running = false

  loop: ->
    @currentTick = (new Date()).getTime()
    tickDur = @currentTick - @lastTick
    
    fps = 1000/tickDur
    if (new Date()).getTime() - @lastFPSDisp > 1000
      @dispFPS fps
      @lastFPSDisp = new Date().getTime()
    
    if @running
      @game.tick()
      @game.render()
      ++@ticks
      requestAnimFrame =>
        @loop()
    
    @lastTick = @currentTick




class Ball
  constructor: (@x, @y) ->
    @radius = 5
    [@xvel, @yvel] = [3,3]
    @color = [255,0,0]
  tick: ->
    nx = @x + @xvel
    ny = @y + @yvel
    if nx <= 0
      @bounceX()
      nx = 0
    else if nx >= WIDTH-@size
      @bounceX()
      nx = WIDTH-@size
    else if ny <= 0
      @bounceY()
      ny = 0
    else if ny >= HEIGHT-@size
      @bounceY()
      ny = HEIGHT-@size
    [@x, @y] = [nx, ny]

  draw: (ctx) ->
    ctx.fillStyle = makeColor @color...
    ctx.beginPath()
    ctx.arc @x+@radius, @y+@radius, @radius, 0, Math.PI*2, true
    ctx.fill()



class HZK
  constructor: ->
    @ticks = 0

  init: (manager) ->
    @mgr = manager
    @ctx = manager.ctx

  
  tick: ->
    ++@ticks

  render: ->
    x = Math.floor(Math.random()*WIDTH)
    y = Math.floor(Math.random()*HEIGHT)
    w = Math.floor(Math.random()*(WIDTH-x))
    h = Math.floor(Math.random()*(HEIGHT-y))
    @mgr.ctx.fillStyle = randomColor()
    @mgr.ctx.fillRect x, y, w, h


# canvas manipulation utility functions

Art =

  randomColor: ->
    c = -> Math.floor(Math.random()*255)
    "rgb(#{c()},#{c()},#{c()})"

  color: (r, g, b) -> 
    "rgb(#{r},#{g},#{b})"
  
  circle: (ctx, x, y, r, stroke=false, fill=true) ->
    ctx.beginPath()
    ctx.arc x, y, r, 0, Math.PI*2, true
    ctx.closePath()
    ctx.fill() if fill
    ctx.stroke() if stroke
  
  roundedRect: (ctx, x, y, w, h, rad, stroke=false, fill=true) ->
    ctx.beginPath()
    ctx.moveTo x, y+radius
    ctx.lineTo x, y+height-radius
    ctx.quadraticCurveTo x, y+height, x+radius, y+height
    ctx.lineTo x+width-radius, y+height
    ctx.quadraticCurveTo x+width, y+height, x+width, y+height-radius
    ctx.lineTo x+width, y+radius
    ctx.quadraticCurveTo x+width, y, x+width-radius, y
    ctx.lineTo x+radius, y
    ctx.quadraticCurveTo x, y, x, y + radius
    ctx.closePath()
    ctx.fill() if fill
    ctx.stroke() if stroke
  
  clear: (ctx) ->
    ctx.clearRect 0, 0, WIDTH, HEIGHT

  rect: (ctx, x, y, w, h, stroke=false, fill=true) ->
    ctx.fillRect x, y, w, h if fill
    ctx.strokeRect x, y, w, h if stroke



window.addEventListener "load", ->
  m = new Game new HZK()
  m.start()

