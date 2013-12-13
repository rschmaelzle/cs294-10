(function() {
  var $, ScoreVis, SpreadVis, VisUnderstandingResult, renderStatement;

  $ = jQuery;

  ScoreVis = (function() {
    function ScoreVis(hist, statements, $el, callback) {
      var barWidth, bin, countTotal, data, formatPercent, h, i, padding, svg, w, xAxis, xScale, yAxis, yScale, _i, _len, _ref,
        _this = this;
      this.hist = hist;
      this.statements = statements;
      this.$el = $el;
      this.callback = callback;
      data = [];
      this.$el.html('');
      countTotal = _.reduce(this.hist.count, (function(memo, num) {
        return memo + num;
      }), 0);
      _ref = this.hist.bin;
      for (i = _i = 0, _len = _ref.length; _i < _len; i = ++_i) {
        bin = _ref[i];
        data.push({
          bin: bin,
          count: this.hist.count[i],
          normCount: this.hist.count[i] / countTotal
        });
      }
      w = 390;
      h = 300;
      padding = 30;
      barWidth = (w - 2 * padding) / this.hist.count.length;
      xScale = d3.scale.linear().domain([0, 1]).range([padding, w - padding * 2]);
      yScale = d3.scale.linear().domain([
        0, d3.max(data, function(d) {
          return d.normCount;
        })
      ]).range([h - padding, padding]);
      xAxis = d3.svg.axis().scale(xScale).orient("bottom").ticks(5);
      formatPercent = d3.format(".0%");
      yAxis = d3.svg.axis().scale(yScale).orient("left").ticks(5).tickFormat(formatPercent);
      svg = d3.select(this.$el[0]).append("svg").attr("width", w).attr("height", h);
      svg.selectAll(".scoreBar").data(data).enter().append("svg:rect").classed("scoreBar", true).attr("x", function(d) {
        return xScale(d.bin) - .5 * barWidth + 3;
      }).attr("y", function(d) {
        return yScale(d.normCount);
      }).attr("width", barWidth - 6).attr("height", function(d) {
        return yScale(0) - yScale(d.normCount);
      }).attr("fill", "#7a4e91").on('mouseover', function(d) {
        return d3.select(this).style("fill", "#4c007e");
      }).on('mouseout', function(d) {
        return d3.select(this).style("fill", "#7a4e91");
      }).on('click', function(d, i) {
        return _this.showStatements(d);
      });
      svg.append("g").attr("class", "axis").attr("transform", "translate(0," + (h - padding) + ")").call(xAxis);
      svg.append("g").attr("class", "axis").attr("transform", "translate(" + padding + ",0)").call(yAxis);
      this.$el.append('<div class="scoreStatements"></div>');
      this.$statementEl = this.$el.find('.scoreStatements');
      this.callback();
    }

    ScoreVis.prototype.showStatements = function(bin) {
      var $ul, binSize, floatFormat, max, min, s, sortedStatements, stmts, _i, _j, _len, _len1, _ref, _results,
        _this = this;
      binSize = 1 / this.hist.count.length;
      min = bin.bin - binSize / 2;
      max = bin.bin + binSize / 2;
      floatFormat = d3.format('.02f');
      stmts = [];
      _ref = this.statements;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        s = _ref[_i];
        if (max === 1) {
          if (s.score >= min && s.score <= 1) {
            stmts.push(s);
          }
        } else if (s.score >= min && s.score < max) {
          stmts.push(s);
        }
      }
      this.$statementEl.html("<h4>Score in range " + (floatFormat(min)) + "-" + (floatFormat(max)) + "</h4>\n<ul class=\"list-unstyled\"></ul>");
      $ul = this.$statementEl.find('ul');
      sortedStatements = stmts.sort(function(a, b) {
        return b.score - a.score;
      });
      _results = [];
      for (_j = 0, _len1 = sortedStatements.length; _j < _len1; _j++) {
        s = sortedStatements[_j];
        _results.push(renderStatement(s, $ul));
      }
      return _results;
    };

    return ScoreVis;

  })();

  SpreadVis = (function() {
    function SpreadVis(statements, nuggets, $el, callback) {
      var barWidth, colors, data, h, nug, padding, svg, tooltip, w, xAxis, xScale, yAxis, yScale, _i, _len, _ref,
        _this = this;
      this.statements = statements;
      this.nuggets = nuggets;
      this.$el = $el;
      this.callback = callback;
      this.$el.html('');
      data = [];
      _ref = this.nuggets;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        nug = _ref[_i];
        if (nug.statements.length !== 0) {
          data.push({
            count: nug.statements.length,
            nugget: nug.nugget,
            statements: nug.statements,
            score: nug.score
          });
        }
      }
      data = data.sort(function(a, b) {
        return b.count - a.count;
      });
      w = 390;
      h = 300;
      padding = 30;
      barWidth = (w - 2 * padding) / data.length;
      xScale = d3.scale.linear().domain([0, data.length]).range([padding, w - padding * 2]);
      yScale = d3.scale.linear().domain([
        0, d3.max(data, function(d) {
          return d.count;
        })
      ]).range([h - padding, padding]);
      xAxis = d3.svg.axis().scale(xScale).orient("bottom").ticks(0);
      yAxis = d3.svg.axis().scale(yScale).orient("left").ticks(5);
      svg = d3.select(this.$el[0]).append("svg").attr("width", w).attr("height", h);
      this.$el.append('<div class="venn"><h4>Response overlap</h4><div class="spreadVenn"></div></div>');
      this.$vennEl = this.$el.find('.spreadVenn');
      this.$el.append('<div class="spreadStatements"></div>');
      this.$statementEl = this.$el.find('.spreadStatements');
      tooltip = d3.tip().attr('class', 'd3-tip').html(function(d) {
        return d.nugget;
      }).direction('s').offset([5, 0]);
      colors = d3.scale.ordinal().domain([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10]).range(colorbrewer.RdYlGn[11]);
      svg.call(tooltip);
      svg.selectAll(".spreadBar").data(data).enter().append("svg:rect").attr("x", function(d, i) {
        return xScale(i) + 2;
      }).attr("y", function(d) {
        return yScale(d.count);
      }).attr("width", barWidth - 10).attr("height", function(d) {
        return yScale(0) - yScale(d.count);
      }).style("fill", function(d) {
        return colors(Math.ceil(d.score * 10));
      }).classed("spreadBar", true).on('mouseover', function(d) {
        return tooltip.show(d);
      }).on('mouseout', function(d) {
        return tooltip.hide(d);
      }).on('click', function(d, i) {
        return _this.showStatements(d);
      });
      svg.append("g").attr("class", "axis").attr("transform", "translate(0," + (h - padding) + ")").call(xAxis);
      svg.append("g").attr("class", "axis").attr("transform", "translate(" + padding + ",0)").call(yAxis);
      this.renderVenn();
      this.callback();
    }

    SpreadVis.prototype.showStatements = function(nugget) {
      var $ul, i, sortedStatements, statements, _i, _len, _results,
        _this = this;
      statements = nugget.statements;
      this.$statementEl.html("<h4>" + nugget.nugget + "</h4>\n<ul class=\"list-unstyled\"></ul>");
      $ul = this.$statementEl.find('ul');
      sortedStatements = statements.sort(function(i, j) {
        return _this.statements[j].score - _this.statements[i].score;
      });
      _results = [];
      for (_i = 0, _len = sortedStatements.length; _i < _len; _i++) {
        i = sortedStatements[_i];
        _results.push(renderStatement(this.statements[i], $ul));
      }
      return _results;
    };

    SpreadVis.prototype.renderVenn = function() {
      var $slider, c, cString, combs, e, filterVenn, i, maxSize, n, ns, nug, nugs, offset, offsets, offsetted, olap, olaps, overlaps, s, sets, slider, svg, tooltip, v, vsets, _i, _j, _k, _l, _len, _len1, _len2, _len3, _ref, _ref1, _ref2,
        _this = this;
      sets = [];
      nugs = [];
      offsets = [];
      maxSize = 0;
      _ref = this.nuggets;
      for (i = _i = 0, _len = _ref.length; _i < _len; i = ++_i) {
        nug = _ref[i];
        if (nug.statements.length > 0) {
          nugs.push(nug);
          offsets.push(i);
          sets.push({
            label: '',
            size: nug.statements.length
          });
          if (nug.statements.length > maxSize) {
            maxSize = nug.statements.length;
          }
        }
      }
      overlaps = {};
      _ref1 = this.combinations((function() {
        var _k, _len1, _results;
        _results = [];
        for (i = _k = 0, _len1 = offsets.length; _k < _len1; i = ++_k) {
          offset = offsets[i];
          _results.push(i);
        }
        return _results;
      })());
      for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
        c = _ref1[_j];
        if (c.length > 1) {
          cString = c.join(',');
          overlaps[c] = 0;
        }
      }
      _ref2 = this.statements;
      for (_k = 0, _len2 = _ref2.length; _k < _len2; _k++) {
        s = _ref2[_k];
        ns = s.nuggets;
        offsetted = (function() {
          var _l, _len3, _results;
          _results = [];
          for (_l = 0, _len3 = ns.length; _l < _len3; _l++) {
            n = ns[_l];
            _results.push(offsets.indexOf(n));
          }
          return _results;
        })();
        combs = this.combinations(offsetted);
        for (_l = 0, _len3 = combs.length; _l < _len3; _l++) {
          c = combs[_l];
          if (c.length !== 1) {
            cString = c.join(',');
            overlaps[cString] += 1;
          }
        }
      }
      olaps = [];
      for (olap in overlaps) {
        v = overlaps[olap];
        if (v !== 0) {
          olaps.push({
            sets: (function() {
              var _len4, _m, _ref3, _results;
              _ref3 = olap.split(',');
              _results = [];
              for (_m = 0, _len4 = _ref3.length; _m < _len4; _m++) {
                i = _ref3[_m];
                _results.push(parseInt(i));
              }
              return _results;
            })(),
            size: v
          });
        }
      }
      console.log("sets", sets);
      console.log("olaps", olaps);
      try {
        vsets = venn.venn(sets, olaps);
      } catch (_error) {
        e = _error;
        console.log("hmm", e);
        vsets = venn.venn(sets, olaps, {
          layoutFunction: venn.classicMDSLayout
        });
      }
      venn.drawD3Diagram(d3.select(this.$vennEl[0]), vsets, 380, 300);
      svg = d3.select(this.$vennEl[0]).select('svg');
      tooltip = d3.tip().attr('class', 'd3-tip').html(function(d, i) {
        return _this.nuggets[offsets[i]].nugget + ("(" + _this.nuggets[offsets[i]].statements.length + ")");
      }).direction('s').offset([5, 0]);
      svg.call(tooltip);
      svg.selectAll('circle').each(function(d, i) {
        var circle,
          _this = this;
        circle = this;
        return d3.select(this).on('mouseover', function() {
          tooltip.show(d, i);
          return d3.select(circle).attr('stroke', 'black');
        }).on('mouseout', function() {
          tooltip.hide(d, i);
          return d3.select(circle).attr('stroke', 'none');
        });
      });
      filterVenn = function(val) {
        return svg.selectAll('circle').each(function(d, i) {
          if (d.size < val) {
            return d3.select(this).style('display', 'none');
          } else {
            return d3.select(this).style('display', 'block');
          }
        });
      };
      $slider = $(document.createElement('div')).attr('class', 'sliderBox').css('width', '100%').appendTo(this.$vennEl);
      return slider = $slider.slider({
        min: 1,
        max: maxSize,
        step: 1,
        value: 1
      }).on('slide', function(e) {
        return filterVenn(slider.getValue());
      }).data('slider');
    };

    SpreadVis.prototype.combinations = function(ids) {
      var f, result;
      result = [];
      f = function(prefix, ids) {
        var i, newPrefix, _results;
        i = 0;
        _results = [];
        while (i < ids.length) {
          newPrefix = prefix.slice(0);
          newPrefix.push(ids[i]);
          result.push(newPrefix);
          f(newPrefix, ids.slice(i + 1));
          _results.push(i++);
        }
        return _results;
      };
      f([], ids);
      return result;
    };

    return SpreadVis;

  })();

  renderStatement = function(statement, $el) {
    var $li, colors, floatFormat, s, score, scoreBin, scoreColor, textColor;
    floatFormat = d3.format('.02f');
    colors = d3.scale.ordinal().domain([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10]).range(colorbrewer.RdYlGn[11]);
    s = statement.statement;
    $li = $("<li>" + s + "</li>").appendTo($el);
    score = statement.score;
    scoreBin = Math.ceil(statement.score * 10);
    scoreColor = colors(scoreBin);
    if (scoreBin > 6 || scoreBin < 3) {
      textColor = 'white';
    } else {
      textColor = 'black';
    }
    return $(document.createElement('div')).css({
      background: scoreColor,
      width: "40px",
      height: "40px",
      color: textColor,
      "font-size": "10pt",
      "font-weight": "bold",
      "text-align": "center",
      "vertical-align": "middle",
      "-moz-border-radius": "20px",
      "border-radius": "20px",
      "float": "left",
      "line-height": "40px",
      "margin-right": "5px"
    }).html(floatFormat(score)).prependTo($li);
  };

  VisUnderstandingResult = (function() {
    function VisUnderstandingResult(vis, $el, callback) {
      var _this = this;
      this.vis = vis;
      this.$el = $el;
      this.callback = callback;
      this.$el.find('.visImg').html("<img src=\"data/" + this.vis + "/0.png\" />");
      $.getJSON("data/" + this.vis + "/result.csv", function(res) {
        var averageScore, cb, floatFormat, scov, sprv;
        _this.nuggets = res.nuggets;
        _this.statements = res.statements;
        _this.scoreHist = res.score_histogram;
        cb = _.after(2, _this.callback);
        scov = new ScoreVis(_this.scoreHist, _this.statements, _this.$el.find('.scoreHist'), cb);
        sprv = new SpreadVis(_this.statements, _this.nuggets, _this.$el.find('.spread'), cb);
        averageScore = d3.mean(_this.statements, function(d) {
          return d.score;
        });
        floatFormat = d3.format('.02f');
        return $('.avgScore').html(floatFormat(averageScore));
      });
    }

    return VisUnderstandingResult;

  })();

  window.VisUnderstandingResult = VisUnderstandingResult;

}).call(this);
