(function() {
  var Art, Ball, Breakout, Brick, Game, HEIGHT, InputHandler, Paddle, Rect, WIDTH, mixin;

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
    contains: function(p) {
      var _ref, _ref2;
      return (this.x <= (_ref = p.x) && _ref <= this.x + this.width) && (this.y <= (_ref2 = p.y) && _ref2 <= this.y + this.height);
    },
    intersects: function(r) {
      var _ref, _ref2, _ref3, _ref4;
      return (((r.x <= (_ref = this.x) && _ref <= r.x + r.width)) || ((this.x <= (_ref2 = r.x) && _ref2 <= this.x + this.width))) && (((r.y <= (_ref3 = this.y) && _ref3 <= r.y + r.height)) || ((this.y <= (_ref4 = r.y) && _ref4 <= this.y + this.height)));
    }
  };

  Art = {
    color: function(r, g, b) {
      return "rgb(" + r + "," + g + "," + b + ")";
    },
    hslToRGB: function(h, s, l) {
      var b, convertHue, g, p, q, r;
      if (s === 0) {
        return [Math.floor(255 * l), Math.floor(255 * l), Math.floor(255 * l)];
      } else {
        convertHue = function(p, q, t) {
          if (t < 0) t += 1;
          if (t > 1) t -= 1;
          if (t < 1 / 6) {
            return p + (q - p) * 6 * t;
          } else if (t < 1 / 2) {
            return q;
          } else if (t < 2 / 3) {
            return p + (q - p) * (2 / 3 - t) * 6;
          } else {
            return p;
          }
        };
        q = l < 0.5 ? l * (1 + s) : l + s - l * s;
        p = 2 * l - q;
        r = convertHue(p, q, h + 1 / 3);
        g = convertHue(p, q, h);
        b = convertHue(p, q, h - 1 / 3);
        return [Math.floor(r * 255), Math.floor(g * 255), Math.floor(b * 255)];
      }
    },
    rgbToHSL: function(r, g, b) {
      var bf, d, gf, h, l, max, min, rf, s, _ref, _ref2, _ref3;
      _ref = [r / 255, g / 255, b / 255], rf = _ref[0], gf = _ref[1], bf = _ref[2];
      _ref2 = [Math.max(rf, gf, bf), Math.min(rf, gf, bf)], max = _ref2[0], min = _ref2[1];
      _ref3 = [0, 0, (max + min) / 2], h = _ref3[0], s = _ref3[1], l = _ref3[2];
      if (max === min) {
        h = s = 0;
      } else {
        d = max - min;
        if (l > 0.5) {
          s = d / (2 - max - min);
        } else {
          s = d / (max + min);
        }
        switch (max) {
          case rf:
            h = (g - b) / d + (g < b ? 6 : 0);
            break;
          case gf:
            h = (b - r) / d + 2;
            break;
          case bf:
            h = (r - g) / d + 4;
        }
        h /= 6;
      }
      return [h, s, l];
    }
  };

  Game = (function() {

    function Game(game) {
      this.game = game;
      this.running = false;
      this.fpsElem = document.getElementById("fps");
      this.canvas = document.getElementsByTagName("canvas")[0];
      this.ctx = this.canvas.getContext("2d");
      this.input = new InputHandler();
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
      currentTick = (new Date()).getTime();
      fps = 1000 / (currentTick - this.lastTick);
      if ((new Date()).getTime() - this.lastFPSDisp > 1000) {
        this.fpsElem.innerHTML = parseInt(fps);
        this.lastFPSDisp = new Date().getTime();
      }
      if (this.running) {
        this.game.tick();
        this.game.render();
        requestAnimFrame(function() {
          return _this.loop();
        });
      }
      return this.lastTick = currentTick;
    };

    return Game;

  })();

  Paddle = (function() {

    mixin(Paddle, Rect);

    function Paddle(input) {
      var _ref, _ref2;
      this.input = input;
      _ref = [60, 10], this.width = _ref[0], this.height = _ref[1];
      _ref2 = [(WIDTH - this.width) / 2, HEIGHT - 20], this.x = _ref2[0], this.y = _ref2[1];
    }

    Paddle.prototype.tick = function() {
      if (this.input.right) {
        this.move(7, 0);
      } else if (this.input.left) {
        this.move(-7, 0);
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
      this.color = Art.hslToRGB.apply(Art, hsl);
      hsl[2] = Math.max(0, hsl[2] * 0.8);
      this.outline = Art.hslToRGB.apply(Art, hsl);
    }

    Brick.prototype.render = function(ctx) {
      this.ctx = ctx;
      this.ctx.fillStyle = Art.color.apply(Art, this.color);
      this.ctx.strokeStyle = Art.color.apply(Art, this.outline);
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
      _ref2 = [3, 3], this.xvel = _ref2[0], this.yvel = _ref2[1];
      this.color = [255, 0, 0];
    }

    Ball.prototype.tick = function() {
      var nx, ny, _ref;
      _ref = [this.x + this.xvel, this.y + this.yvel], nx = _ref[0], ny = _ref[1];
      if (nx < 0 || nx > WIDTH - this.width) {
        this.xvel *= -1;
      } else if (ny < 0 || ny > HEIGHT - this.height) {
        this.yvel *= -1;
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
      this.mgr = mgr;
      this.ctx = this.mgr.ctx;
      this.paddle = new Paddle(this.mgr.input);
      return this.start(1);
    };

    Breakout.prototype.start = function() {
      var cols, i, j, _results;
      this.ball = new Ball(200, 200, 6);
      this.bricks = [];
      cols = this.genColors();
      _results = [];
      for (j = 0; j < 4; j++) {
        _results.push((function() {
          var _results2;
          _results2 = [];
          for (i = 0; i < 10; i++) {
            _results2.push(this.bricks.push(new Brick(i * 72, j * 20, 72, 20, cols[(i + j) % 10])));
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
      this.ball.tick();
      this.paddle.tick();
      if (this.paddle.intersects(this.ball)) {
        this.ball.yvel = -1 * Math.abs(this.ball.yvel);
      }
      return this.bricks = this.bricks.filter(function(brick) {
        if (!brick.intersects(_this.ball)) return true;
        _this.ball.bounce(brick);
        return false;
      });
    };

    Breakout.prototype.render = function() {
      var brick, _i, _len, _ref;
      this.ctx.fillStyle = "#ffffff";
      this.ctx.clearRect(0, 0, WIDTH, HEIGHT);
      _ref = this.bricks;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        brick = _ref[_i];
        brick.render(this.ctx);
      }
      this.ball.render(this.ctx);
      return this.paddle.render(this.ctx);
    };

    return Breakout;

  })();

  InputHandler = (function() {

    function InputHandler() {
      var _this = this;
      this.right = this.left = false;
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
      }
    };

    return InputHandler;

  })();

  window.addEventListener("load", function() {
    var m;
    return m = new Game(new Breakout()).start();
  });

}).call(this);
