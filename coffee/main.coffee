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
    @canvas = document.getElementsByTagName("canvas")[0]
    @ctx = @canvas.getContext "2d"
    @input = new InputHandler()
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
    ctx.fillStyle = "#888888"
    ctx.strokeStyle = "#ffffff"
    ctx.fill()
    ctx.stroke()

class Brick
  mixin @, Rect
  constructor: (@x, @y, @width, @height, hsl) ->
    @color = Art.hslToRGB hsl...
    hsl[2] = Math.max 0, hsl[2]*0.8
    @outline = Art.hslToRGB hsl...
  render: (@ctx) ->
    @ctx.fillStyle = Art.color @color...
    @ctx.strokeStyle = Art.color @outline...
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
    ctx.beginPath()
    ctx.arc @x+@radius, @y+@radius, @radius, 0, Math.PI*2, true
    ctx.fill()
  bounce: (brick) ->
    return @xvel *= -1 if brick.x > @x+@radius or brick.x+brick.width < @x+@radius
    return @yvel *= -1 if brick.y > @y+@radius or brick.y+brick.height < @y+@radius

class Breakout
  constructor: ->
  init: (@mgr) ->
    @won = @lost = false
    {ctx: @ctx, input: @input} = @mgr
    @paddle = new Paddle @input
    @start 1
  start:  ->
    @ball = new Ball 200, 200, 6
    @bricks = []
    [bw, bh] = [72, 20]
    cols = do @genColors
    for j in [0...4]
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
  render: ->
    @ctx.clearRect 0, 0, WIDTH, HEIGHT
    brick.render @ctx for brick in @bricks
    @ball.render @ctx
    @paddle.render @ctx
    if @won or @lost
      [str, col] = if @won then ["You Win!", "green"] else ["You Lose!", "red"]
      @ctx.fillStyle = col
      @ctx.font = "50pt sans-serif"
      @ctx.fillText str, (WIDTH-@ctx.measureText(str).width)/2, (HEIGHT-50)/2

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


