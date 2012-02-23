window.requestAnimFrame = 
  window.requestAnimationFrame or
  window.webkitRequestAnimationFrame or
  window.mozRequestAnimationFrame or
  window.oRequestAnimationFrame or
  window.msRequestAnimationFrame or
  (callback, element) ->
    window.setTimeout callback, 16.666

WIDTH = 720
HEIGHT = 480

class Game
  constructor: (@game) ->
    @running = false
    @fpsElem = document.getElementById "fps" 

  start: ->
    @canvas = document.getElementsByTagName("canvas")[0]
    @width  = @canvas.width
    @height = @canvas.height
    @ctx    = @canvas.getContext "2d"
    @loopStart   = new Date().getTime()
    @lastTick    = new Date().getTime()
    @lastFPSDisp = new Date().getTime()
    @running = true
    @game.init @ if @game.init?
    requestAnimFrame =>
      @loop()

  loop: ->
    @currentTick = (new Date()).getTime()
    fps = 1000/(@currentTick - @lastTick)
    if (new Date()).getTime() - @lastFPSDisp > 1000
      @fpsElem.innerHTML = parseInt fps
      @lastFPSDisp = new Date().getTime()
    if @running
      @game.tick()
      @game.render()
      requestAnimFrame =>
        @loop()
    @lastTick = @currentTick

class Ball
  constructor: (@x, @y) ->
    @radius = 6
    [@xvel, @yvel] = [3,3]
    @color = [255,0,0]
    @ticks=0

  shiftColor: ->
    h = (@ticks % 360)/360
    @color = Art.hslToRGB h, 1, 0.5

  tick: ->
    @ticks++
    @shiftColor()
    [nx, ny] = [@x + @xvel, @y + @yvel]
    if nx < 0 or nx > WIDTH-@radius*2 then @xvel *= -1
    else if ny < 0 or ny > HEIGHT-@radius*2 then @yvel *= -1
    [@x, @y] = [nx, ny]

  render: (ctx) ->
    ctx.fillStyle = Art.color @color...
    ctx.beginPath()
    ctx.arc @x+@radius, @y+@radius, @radius, 0, Math.PI*2, true
    ctx.fill()

class Paddle
  constructor: ->
    [@width, @height] = [60, 10]
    [@x, @y] = [(WIDTH-@width)/2, HEIGHT-20]

  render: (ctx) ->
    radius = @height/2
    ctx.beginPath()
    ctx.moveTo(@x, @y+radius)
    ctx.lineTo(@x, @y+@height-radius)
    ctx.quadraticCurveTo(@x, @y+@height, @x+radius, @y+@height)
    ctx.lineTo(@x+@width-radius, @y+@height)
    ctx.quadraticCurveTo(@x+@width, @y+@height, @x+@width, @y+@height-radius)
    ctx.lineTo(@x+@width, @y+radius)
    ctx.quadraticCurveTo(@x+@width, @y, @x+@width-radius, @y)
    ctx.lineTo(@x+radius, @y)
    ctx.quadraticCurveTo(@x, @y, @x, @y+radius)
    ctx.closePath()
    ctx.fillStyle = "#cccccc"
    ctx.strokeStyle = "#ffffff"
    ctx.fill()
    ctx.stroke()

class HZK
  constructor: ->
    @ticks = 0
  init: (@mgr) ->
    @ctx  = @mgr.ctx
    @ball = new Ball 20, 20
    @paddle = new Paddle()

  tick: ->
    ++@ticks
    @ball.tick()
  
  render: ->
    @ctx.fillStyle = "#ffffff"
    @ctx.clearRect 0, 0, @mgr.width, @mgr.height
    @ball.render @ctx
    @paddle.render @ctx

Art =
  randomColor: ->
    c = -> Math.floor(Math.random()*255)
    "rgb(#{c()},#{c()},#{c()})"
  color: (r, g, b) -> "rgb(#{r},#{g},#{b})"

  hslToRGB: (h, s, l) ->
    if s is 0 then [Math.floor(255*l), Math.floor(255*l), Math.floor(255*l)]
    else
      convertHue = (p, q, t) ->
        t += 1 if t < 0
        t -= 1 if t > 1
        if t < 1/6 
          p+(q-p)*6*t
        else if t < 1/2
          q
        else if t < 2/3
          p + (q-p)*(2/3-t)*6
        else
          p
      q = if l < 0.5 then l*(1+s) else (l+s-l*s)
      p = 2*l-q
      r = convertHue p, q, h+1/3
      g = convertHue p, q, h
      b = convertHue p, q, h-1/3
      [Math.floor(r*255), Math.floor(g*255), Math.floor(b*255)]
  rgbToHSL: (r, g, b) ->
    [rf, gf, bf] = [r/255, g/255, b/255]
    [max, min]   = [Math.max(rf, gf, bf), Math.min(rf, gf, bf)]
    [h, s, l]    = [0, 0, (max+min)/2]
    if max is min
      h = s = 0
    else
      d = max-min
      if l > 0.5 then s = d/(2-max-min)
      else s = d/(max + min)
      switch max
        when rf then h = (g-b)/d + (if g < b then 6 else 0)
        when gf then h = (b-r)/d + 2
        when bf then h = (r-g)/d + 4
      h /= 6
    [h, s, l]
  darker: (c) ->
    c2 = Art.rgbToHSL c...
    c2[2] = Math.min(1, Math.max(0, c2[2] - 0.1))
    Art.hslToRGB c2...

window.addEventListener "load", ->
  m = new Game new HZK()
  m.start()

