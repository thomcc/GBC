(function() {
  var Art, Ball, Breakout, Brick, Game, HEIGHT, InputHandler, Paddle, Rect, SoundManager, WIDTH, mixin,
    __slice = Array.prototype.slice;

  window.requestAnimFrame = window.requestAnimationFrame || window.webkitRequestAnimationFrame || window.mozRequestAnimationFrame || window.oRequestAnimationFrame || window.msRequestAnimationFrame || function(callback, element) {
    return window.setTimeout(callback, 16.666);
  };

  WIDTH = 720;

  HEIGHT = 480;

  mixin = function(cls, obj) {
    var k, v, _results;
    _results = [];
    for (k in obj) {
      v = obj[k];
      _results.push(cls.prototype[k] = v);
    }
    return _results;
  };

  Rect = {
    move: function(x, y) {
      var _ref;
      return _ref = [x + this.x, y + this.y], this.x = _ref[0], this.y = _ref[1], _ref;
    },
    moveTo: function(nx, ny) {
      var _ref;
      return _ref = [nx, ny], this.x = _ref[0], this.y = _ref[1], _ref;
    },
    contains: function(_arg) {
      var x, y;
      x = _arg.x, y = _arg.y;
      return (this.x <= x && x <= this.x + this.width) && (this.y <= y && y <= this.y + this.height);
    },
    intersects: function(_arg) {
      var h, w, x, y, _ref, _ref2;
      x = _arg.x, y = _arg.y, w = _arg.width, h = _arg.height;
      return (((x <= (_ref = this.x) && _ref <= x + w)) || ((this.x <= x && x <= this.x + this.width))) && (((y <= (_ref2 = this.y) && _ref2 <= y + h)) || ((this.y <= y && y <= this.y + this.height)));
    }
  };

  Art = {
    color: function(r, g, b) {
      return "rgb(" + r + "," + g + "," + b + ")";
    },
    hslColor: function(h, s, l) {
      return "hsl(" + (h * 360) + "," + (s * 100) + "%," + (l * 100) + "%)";
    }
  };

  SoundManager = (function() {

    function SoundManager() {
      var s, soundNames, _i, _len;
      soundNames = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      this.sounds = {};
      for (_i = 0, _len = soundNames.length; _i < _len; _i++) {
        s = soundNames[_i];
        this.sounds[s] = new Audio("snd/" + s + ".wav");
      }
      window.theSoundManager = this;
    }

    SoundManager.prototype.play = function(snd) {
      var _ref;
      return (_ref = this.sounds[snd]) != null ? _ref.play() : void 0;
    };

    return SoundManager;

  })();

  Game = (function() {

    function Game(game) {
      this.game = game;
      this.running = false;
      this.fpsElem = document.getElementById("fps");
      this.tickElem = document.getElementById("ticks");
      this.canvas = document.getElementsByTagName("canvas")[0];
      this.ctx = this.canvas.getContext("2d");
      this.input = new InputHandler;
      this.needed = this.ticks = 0;
      new SoundManager('destroybrick', 'lose', 'paddlebounce', 'wallbounce', 'win');
    }

    Game.prototype.start = function() {
      var _this = this;
      this.lastTick = new Date().getTime();
      this.lastFPSDisp = new Date().getTime();
      this.running = true;
      if (this.game.init != null) this.game.init(this);
      return requestAnimFrame(function() {
        return _this.loop();
      });
    };

    Game.prototype.loop = function() {
      var currentTick, fps,
        _this = this;
      currentTick = new Date().getTime();
      fps = 1000 / (currentTick - this.lastTick);
      this.needed = (currentTick - this.lastTick) * 60 / 1000;
      if (new Date().getTime() - this.lastFPSDisp > 1000) {
        this.tickElem.innerHTML = this.ticks;
        this.ticks = 0;
        this.fpsElem.innerHTML = parseInt(fps);
        this.lastFPSDisp = new Date().getTime();
      }
      if (this.running) {
        while (this.needed > 0) {
          this.game.tick();
          ++this.ticks;
          --this.needed;
        }
        this.game.render();
        requestAnimFrame(function() {
          return _this.loop();
        });
      }
      return this.lastTick = new Date().getTime();
    };

    return Game;

  })();

  Paddle = (function() {

    mixin(Paddle, Rect);

    function Paddle(input) {
      var _ref, _ref2;
      this.input = input;
      _ref = [80, 10], this.width = _ref[0], this.height = _ref[1];
      _ref2 = [(WIDTH - this.width) / 2, HEIGHT - 30], this.x = _ref2[0], this.y = _ref2[1];
      this.speed = 8;
    }

    Paddle.prototype.tick = function() {
      if (this.input.right) {
        this.move(this.speed, 0);
      } else if (this.input.left) {
        this.move(-1 * this.speed, 0);
      }
      if (this.x + this.width > WIDTH) {
        return this.x = WIDTH - this.width;
      } else if (this.x < 0) {
        return this.x = 0;
      }
    };

    Paddle.prototype.render = function(ctx) {
      var radius;
      radius = this.height / 2;
      ctx.beginPath();
      ctx.moveTo(this.x, this.y + radius);
      ctx.lineTo(this.x, this.y + this.height - radius);
      ctx.quadraticCurveTo(this.x, this.y + this.height, this.x + radius, this.y + this.height);
      ctx.lineTo(this.x + this.width - radius, this.y + this.height);
      ctx.quadraticCurveTo(this.x + this.width, this.y + this.height, this.x + this.width, this.y + this.height - radius);
      ctx.lineTo(this.x + this.width, this.y + radius);
      ctx.quadraticCurveTo(this.x + this.width, this.y, this.x + this.width - radius, this.y);
      ctx.lineTo(this.x + radius, this.y);
      ctx.quadraticCurveTo(this.x, this.y, this.x, this.y + radius);
      ctx.closePath();
      ctx.fillStyle = "#888888";
      ctx.strokeStyle = "#ffffff";
      ctx.fill();
      return ctx.stroke();
    };

    return Paddle;

  })();

  Brick = (function() {

    mixin(Brick, Rect);

    function Brick(x, y, width, height, hsl) {
      this.x = x;
      this.y = y;
      this.width = width;
      this.height = height;
      this.color = Art.hslColor.apply(Art, hsl);
      hsl[2] = hsl[2] * 0.8;
      this.outline = Art.hslColor.apply(Art, hsl);
    }

    Brick.prototype.render = function(ctx) {
      this.ctx = ctx;
      this.ctx.fillStyle = this.color;
      this.ctx.strokeStyle = this.outline;
      this.ctx.lineWidth = 2;
      this.ctx.fillRect(this.x, this.y, this.width, this.height);
      return this.ctx.strokeRect(this.x + 1, this.y + 1, this.width - 2, this.height - 2);
    };

    return Brick;

  })();

  Ball = (function() {

    mixin(Ball, Rect);

    function Ball(x, y, radius) {
      var _ref, _ref2;
      this.x = x;
      this.y = y;
      this.radius = radius;
      _ref = [this.radius * 2, this.radius * 2], this.width = _ref[0], this.height = _ref[1];
      _ref2 = [4, 4], this.xvel = _ref2[0], this.yvel = _ref2[1];
      this.color = [255, 0, 0];
      this.hitBottom = false;
    }

    Ball.prototype.tick = function() {
      var nx, ny, _ref;
      _ref = [this.x + this.xvel, this.y + this.yvel], nx = _ref[0], ny = _ref[1];
      if (nx < 0 || nx > WIDTH - this.width) {
        this.xvel *= -1;
        window.theSoundManager.play("wallbounce");
      } else if (ny < 0) {
        this.yvel *= -1;
        window.theSoundManager.play("wallbounce");
      } else if (ny > HEIGHT - this.height) {
        this.yvel *= -1;
        this.hitBottom = true;
      }
      return this.moveTo(nx, ny);
    };

    Ball.prototype.render = function(ctx) {
      ctx.fillStyle = Art.color.apply(Art, this.color);
      ctx.beginPath();
      ctx.arc(this.x + this.radius, this.y + this.radius, this.radius, 0, Math.PI * 2, true);
      return ctx.fill();
    };

    Ball.prototype.bounce = function(brick) {
      window.theSoundManager.play("destroybrick");
      if (brick.x > this.x + this.radius || brick.x + brick.width < this.x + this.radius) {
        return this.xvel *= -1;
      }
      if (brick.y > this.y + this.radius || brick.y + brick.height < this.y + this.radius) {
        return this.yvel *= -1;
      }
    };

    return Ball;

  })();

  Breakout = (function() {

    function Breakout() {}

    Breakout.prototype.init = function(mgr) {
      var _ref;
      this.mgr = mgr;
      _ref = this.mgr, this.ctx = _ref.ctx, this.input = _ref.input;
      this.paddle = new Paddle(this.input);
      return this.start(1);
    };

    Breakout.prototype.start = function(level) {
      var bh, bw, cols, i, j, _ref, _ref2, _results;
      this.level = level;
      this.ball = new Ball(200, 200, 6);
      this.bricks = [];
      _ref = [72, 20], bw = _ref[0], bh = _ref[1];
      cols = this.genColors();
      this.won = this.lost = false;
      _results = [];
      for (j = 0, _ref2 = 2 + this.level; 0 <= _ref2 ? j < _ref2 : j > _ref2; 0 <= _ref2 ? j++ : j--) {
        _results.push((function() {
          var _results2;
          _results2 = [];
          for (i = 0; i < 10; i++) {
            _results2.push(this.bricks.push(new Brick(i * bw, j * bh, bw, bh, cols[(i + j) % 10])));
          }
          return _results2;
        }).call(this));
      }
      return _results;
    };

    Breakout.prototype.genColors = function() {
      var i, l, s, _results;
      s = 0.6 + Math.random() * 0.4;
      l = 0.4 + Math.random() * 0.3;
      _results = [];
      for (i = 0; i < 10; i++) {
        _results.push([Math.random(), s, l]);
      }
      return _results;
    };

    Breakout.prototype.tick = function() {
      var _this = this;
      if (!(this.won || this.lost)) {
        this.ball.tick();
        this.paddle.tick();
        if (this.paddle.intersects(this.ball)) {
          this.ball.yvel = -1 * Math.abs(this.ball.yvel);
          window.theSoundManager.play("paddlebounce");
        }
        this.bricks = this.bricks.filter(function(brick) {
          if (!brick.intersects(_this.ball)) return true;
          _this.ball.bounce(brick);
          return false;
        });
        if (this.ball.hitBottom) this.lose();
        if (this.bricks.length === 0) return this.win();
      } else if (this.input.select) {
        return this.start(this.lost ? 1 : this.level + 1);
      }
    };

    Breakout.prototype.lose = function() {
      this.lost = true;
      return window.theSoundManager.play("lose");
    };

    Breakout.prototype.win = function() {
      this.won = true;
      return window.theSoundManager.play("win");
    };

    Breakout.prototype.render = function() {
      var brick, col, str, ty, _i, _len, _ref, _ref2;
      this.ctx.clearRect(0, 0, WIDTH, HEIGHT);
      _ref = this.bricks;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        brick = _ref[_i];
        brick.render(this.ctx);
      }
      this.ball.render(this.ctx);
      this.paddle.render(this.ctx);
      if (this.won || this.lost) {
        _ref2 = this.won ? ["You Win!", "green"] : ["You Lose!", "red"], str = _ref2[0], col = _ref2[1];
        this.ctx.fillStyle = col;
        this.ctx.font = "50pt sans-serif";
        ty = (HEIGHT - 50) / 2;
        this.ctx.fillText(str, (WIDTH - this.ctx.measureText(str).width) / 2, ty);
        return this.ctx.fillText("press space.", (WIDTH - this.ctx.measureText("press space.").width) / 2, ty + 100);
      }
    };

    return Breakout;

  })();

  InputHandler = (function() {

    function InputHandler() {
      var _this = this;
      this.right = this.left = this.space = false;
      window.addEventListener("keydown", function(evt) {
        return _this.onKey(evt.keyCode, true);
      });
      window.addEventListener("keyup", function(evt) {
        return _this.onKey(evt.keyCode, false);
      });
    }

    InputHandler.prototype.onKey = function(code, pressed) {
      switch (code) {
        case 39:
        case 68:
          return this.right = pressed;
        case 37:
        case 65:
          return this.left = pressed;
        case 32:
        case 13:
          return this.select = pressed;
      }
    };

    return InputHandler;

  })();

  window.addEventListener("load", function() {
    var m;
    m = new Game(new Breakout);
    return m.start();
  });

}).call(this);
