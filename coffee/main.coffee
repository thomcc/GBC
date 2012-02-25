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

Rect =
  move: (x, y) -> [@x, @y] = [x+@x, y+@y]
  moveTo: (nx, ny) -> [@x, @y] = [nx, ny]
  contains: ({ x: x, y: y }) -> @x <= x <= @x+@width and @y <= y <= @y+@height
  intersects: ({ x: x, y: y, width: w, height: h }) ->
    ((x <= @x <= x+w) or (@x <= x <= @x+@width)) and
    ((y <= @y <= y+h) or (@y <= y <= @y+@height))

Art =
  color: (r, g, b) -> "rgb(#{r},#{g},#{b})"
  hslColor: (h, s, l) -> "hsl(#{h*360},#{s*100}%,#{l*100}%)"

class Game
  constructor: (@game) ->
    @running = false
    @fpsElem = document.getElementById "fps" 
    @canvas = document.getElementsByTagName("canvas")[0]
    @ctx = @canvas.getContext "2d"
    @input = new InputHandler
  start: ->
    @lastTick    = new Date().getTime()
    @lastFPSDisp = new Date().getTime()
    @running = true
    @game.init this if @game.init?
    requestAnimFrame => do @loop
  loop: ->
    currentTick = new Date().getTime()
    fps = 1000/(currentTick - @lastTick)
    if new Date().getTime() - @lastFPSDisp > 1000
      @fpsElem.innerHTML = parseInt fps
      @lastFPSDisp = new Date().getTime()
    if @running
      do @game.tick
      do @game.render
      requestAnimFrame => do @loop
    @lastTick = currentTick

class Paddle
  mixin @, Rect
  constructor: (@input) ->
    [@width, @height] = [80, 10]
    [@x, @y] = [(WIDTH-@width)/2, HEIGHT-30]
    @speed = 8
  tick: ->
    if @input.right then @move @speed, 0
    else if @input.left then @move -1*@speed, 0
    if @x+@width > WIDTH then @x = WIDTH-@width
    else if @x < 0 then @x = 0
  render: (ctx) ->
    # draw rounded rectangle
    radius = @height/2
    do ctx.beginPath
    ctx.moveTo @x, @y+radius
    ctx.lineTo @x, @y+@height-radius
    ctx.quadraticCurveTo @x, @y+@height, @x+radius, @y+@height
    ctx.lineTo @x+@width-radius, @y+@height
    ctx.quadraticCurveTo @x+@width, @y+@height, @x+@width, @y+@height-radius
    ctx.lineTo @x+@width, @y+radius
    ctx.quadraticCurveTo @x+@width, @y, @x+@width-radius, @y
    ctx.lineTo @x+radius, @y
    ctx.quadraticCurveTo @x, @y, @x, @y+radius
    do ctx.closePath
    ctx.fillStyle = "#888888"
    ctx.strokeStyle = "#ffffff"
    do ctx.fill
    do ctx.stroke

class Brick
  mixin @, Rect
  constructor: (@x, @y, @width, @height, hsl) ->
    @color = Art.hslColor hsl...
    hsl[2] = hsl[2]*0.8
    @outline = Art.hslColor hsl...
  render: (@ctx) ->
    @ctx.fillStyle = @color
    @ctx.strokeStyle = @outline
    @ctx.lineWidth = 2
    @ctx.fillRect @x, @y, @width, @height
    @ctx.strokeRect @x+1, @y+1, @width-2, @height-2

class Ball
  mixin @, Rect
  constructor: (@x, @y, @radius) ->
    [@width, @height] = [@radius*2, @radius*2]
    [@xvel, @yvel] = [4,4]
    @color = [255,0,0]
    @hitBottom = false
  tick: ->
    [nx, ny] = [@x + @xvel, @y + @yvel]
    if nx < 0 or nx > WIDTH-@width then @xvel *= -1
    else if ny < 0 then @yvel *= -1
    else if ny > HEIGHT-@height
      @yvel *= -1
      @hitBottom = true
    @moveTo nx, ny
  render: (ctx) ->
    ctx.fillStyle = Art.color @color...
    do ctx.beginPath
    ctx.arc @x+@radius, @y+@radius, @radius, 0, Math.PI*2, true
    do ctx.fill
  bounce: (brick) ->
    return @xvel *= -1 if brick.x > @x+@radius or brick.x+brick.width < @x+@radius
    return @yvel *= -1 if brick.y > @y+@radius or brick.y+brick.height < @y+@radius

class Breakout
  constructor: ->
  init: (@mgr) ->
    {ctx: @ctx, input: @input} = @mgr
    @paddle = new Paddle @input
    @start 1
  start: (@level) ->
    @ball = new Ball 200, 200, 6
    @bricks = []
    [bw, bh] = [72, 20]
    cols = do @genColors
    @won = @lost = false
    for j in [0...(2+@level)]
      for i in [0...10]
        @bricks.push new Brick i*bw, j*bh, bw, bh, cols[(i+j)%10]
  genColors: ->
    s = 0.6 + Math.random() * 0.4
    l = 0.4 + Math.random() * 0.3
    [Math.random(), s, l] for i in [0...10]
  tick: ->
    unless @won or @lost
      do @ball.tick
      do @paddle.tick
      @ball.yvel = -1*Math.abs(@ball.yvel) if @paddle.intersects @ball
      @bricks = @bricks.filter (brick) =>
        return true unless brick.intersects @ball
        @ball.bounce brick
        false
      @lost = true if @ball.hitBottom
      @won = true if @bricks.length is 0
    else if @input.select
      @start if @lost then 1 else @level+1
  render: ->
    @ctx.clearRect 0, 0, WIDTH, HEIGHT
    brick.render @ctx for brick in @bricks
    @ball.render @ctx
    @paddle.render @ctx
    if @won or @lost
      [str, col] = if @won then ["You Win!", "green"] else ["You Lose!", "red"]
      @ctx.fillStyle = col
      @ctx.font = "50pt sans-serif"
      ty = (HEIGHT-50)/2
      @ctx.fillText str, (WIDTH-@ctx.measureText(str).width)/2, ty
      @ctx.fillText "press space.", (WIDTH-@ctx.measureText("press space.").width)/2, ty+100


class InputHandler
  constructor: ->
    @right = @left = @space = false
    window.addEventListener "keydown", (evt) => @onKey evt.keyCode, true
    window.addEventListener "keyup",   (evt) => @onKey evt.keyCode, false
  onKey: (code, pressed) ->
    switch code
      when 39, 68 then @right  = pressed
      when 37, 65 then @left   = pressed
      when 32, 13 then @select = pressed



window.addEventListener "load", -> 
  m = new Game new Breakout
  do m.start


