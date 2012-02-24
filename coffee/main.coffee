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

mixin = (cls, obj) ->
  for k, v of obj
    cls.prototype[k] = v

Rect = # mixin for things with x, y, width, and height properties
  move: (x, y) -> [@x, @y] = [x+@x, y+@y]
  moveTo: (nx, ny) -> [@x, @y] = [nx, ny]
  contains: (p) -> @x <= p.x <= @x+@width and @y <= p.y <= @y+@height
  intersects: (r) ->
    ((r.x <= @x <= r.x+r.width)  or (@x <= r.x <= @x+@width)) and
    ((r.y <= @y <= r.y+r.height) or (@y <= r.y <= @y+@height))

Art =
  color: (r, g, b) -> "rgb(#{r},#{g},#{b})"
  hslToRGB: (h, s, l) ->
    if s is 0 then [Math.floor(255*l), Math.floor(255*l), Math.floor(255*l)]
    else
      convertHue = (p, q, t) ->
        t += 1 if t < 0
        t -= 1 if t > 1
        if t < 1/6 then p+(q-p)*6*t
        else if t < 1/2 then q
        else if t < 2/3 then p + (q-p)*(2/3-t)*6
        else p
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
    if max is min then h = s = 0
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

class Game
  constructor: (@game) ->
    @running = false
    @fpsElem = document.getElementById "fps" 
    @canvas  = document.getElementsByTagName("canvas")[0]
    @ctx     = @canvas.getContext "2d"
    @input   = new InputHandler()
  start: ->
    @lastTick    = new Date().getTime()
    @lastFPSDisp = new Date().getTime()
    @running = true
    @game.init @ if @game.init?
    requestAnimFrame => @loop()
  loop: ->
    currentTick = (new Date()).getTime()
    fps = 1000/(currentTick - @lastTick)
    if (new Date()).getTime() - @lastFPSDisp > 1000
      @fpsElem.innerHTML = parseInt fps
      @lastFPSDisp = new Date().getTime()
    if @running
      @game.tick()
      @game.render()
      requestAnimFrame => @loop()
    @lastTick = currentTick

class Ball
  mixin @, Rect
  constructor: (@x, @y, @radius) ->
    [@width, @height] = [@radius*2, @radius*2]
    [@xvel, @yvel] = [3,3]
    @color = [255,0,0]
  tick: ->
    [nx, ny] = [@x + @xvel, @y + @yvel]
    if nx < 0 or nx > WIDTH-@radius*2 then @xvel *= -1
    else if ny < 0 or ny > HEIGHT-@radius*2 then @yvel *= -1
    @moveTo nx, ny
  render: (ctx) ->
    ctx.fillStyle = Art.color @color...
    ctx.beginPath()
    ctx.arc @x+@radius, @y+@radius, @radius, 0, Math.PI*2, true
    ctx.fill()

class Paddle
  mixin @, Rect
  constructor: (@input) ->
    [@width, @height] = [60, 10]
    [@x, @y] = [(WIDTH-@width)/2, HEIGHT-20]
  tick: -> 
    dx = 0
    if @input.right then @move 5, 0
    else if @input.left then @move -5, 0
    if @x+@width > WIDTH then @x = WIDTH-@width
    else if @x < 0 then @x = 0
  render: (ctx) ->
    # draw rounded rectangle
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

class Brick
  mixin @, Rect
  constructor: (@x, @y, @width, @height, hsl) ->
    @color = Art.hslToRGB hsl...
    hsl[2] = Math.min 0, hsl[2]-0.1
    @outline = Art.hslToRGB hsl...
  render: (@ctx) ->
    @ctx.fillStyle = Art.color @color...
    @ctx.strokeStyle = Art.color @outline...
    @ctx.strokeWidth = 2
    @ctx.fillRect @x, @y, @width, @height
    @ctx.strokeRect @x, @y, @width, @height

class Breakout
  constructor: ->
  init: (@mgr) ->
    @ctx    = @mgr.ctx
    @ball   = new Ball 20, 20, 6
    @paddle = new Paddle @mgr.input
    @bricks = []
    cols = @genCols
    for j in [0..3]
      for i in [0..10]
        @bricks.push new Brick(i*72, j*10, 72, 10, [Math.random()])
  tick: ->
    @ball.tick()
    @paddle.tick()
    if @paddle.intersects @ball then @ball.yvel *= -1
  render: ->
    @ctx.fillStyle = "#ffffff"
    @ctx.clearRect 0, 0, WIDTH, HEIGHT
    @ball.render @ctx
    @paddle.render @ctx

class InputHandler
  constructor: ->
    @right = @left = false
    window.addEventListener "keydown", (evt) => @onKey evt.keyCode, true
    window.addEventListener "keyup",   (evt) => @onKey evt.keyCode, false
  onKey: (code, pressed) ->
    switch code
      when 39, 68 then @right = pressed
      when 37, 65 then @left  = pressed



window.addEventListener "load", -> m = new Game(new Breakout()).start()


