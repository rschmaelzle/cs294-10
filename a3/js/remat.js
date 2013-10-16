(function() {
  var $, ReorderableMatrix,
    __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  $ = jQuery;

  ReorderableMatrix = (function() {
    function ReorderableMatrix(el) {
      var controls, m, obj, _fn, _ref,
        _this = this;
      this.el = el;
      controls = d3.select(this.el).append("div");
      controls.append("strong").html("Mode:");
      this.reorderButton = controls.append("button").html("Reorder rows");
      this.groupBtn = controls.append("button").html("Create group");
      this.statusText = controls.append("div").html("");
      controls.append("hr");
      this.modes = {
        reorder: {
          status: "Drag to reorder rows",
          button: this.reorderButton
        },
        addGroup: {
          status: "Drag over several rows to create group. Click a group name to edit.",
          button: this.groupBtn
        }
      };
      _ref = this.modes;
      _fn = function(m) {
        return obj.button.on("click", function() {
          return _this.setMode(m);
        });
      };
      for (m in _ref) {
        obj = _ref[m];
        _fn(m);
      }
      this.setMode("reorder");
      this.groupColors = d3.scale.category10().domain([0, 1, 2, 3, 4, 5, 6, 7, 8, 9]);
      this.groupCount = 0;
      this.groupLabels = [];
    }

    ReorderableMatrix.prototype.setMode = function(mode) {
      var m, obj, _ref;
      this.mode = mode;
      this.statusText.html(this.modes[mode].status);
      _ref = this.modes;
      for (m in _ref) {
        obj = _ref[m];
        obj.button.attr("disabled", null);
      }
      return this.modes[mode].button.attr("disabled", "disabled");
    };

    ReorderableMatrix.prototype.load = function(filename, noHeader) {
      var _this = this;
      return d3.text(filename, function(data) {
        var d, datum, h, i, threshold, v, x, _i, _j, _k, _l, _len, _len1, _len2, _len3, _ref, _ref1, _ref2;
        data = d3.csv.parseRows(data);
        if (noHeader == null) {
          _this.header = data[0].slice(2);
          data = data.slice(1);
        } else {
          _this.header = null;
        }
        _this.data = [];
        for (i = _i = 0, _len = data.length; _i < _len; i = ++_i) {
          d = data[i];
          datum = {};
          datum.name = d[0];
          datum.max = d[1];
          datum.vals = (function() {
            var _j, _len1, _ref, _results;
            _ref = d.slice(2);
            _results = [];
            for (_j = 0, _len1 = _ref.length; _j < _len1; _j++) {
              x = _ref[_j];
              _results.push(+x);
            }
            return _results;
          })();
          datum.group = null;
          _this.data.push(datum);
        }
        _ref = _this.data;
        for (_j = 0, _len1 = _ref.length; _j < _len1; _j++) {
          d = _ref[_j];
          _ref1 = d.vals;
          for (_k = 0, _len2 = _ref1.length; _k < _len2; _k++) {
            v = _ref1[_k];
            d.vals.push(v);
          }
          threshold = d3.mean(d.vals);
          d.aboveThreshold = (function() {
            var _l, _len3, _ref2, _results;
            _ref2 = d.vals;
            _results = [];
            for (_l = 0, _len3 = _ref2.length; _l < _len3; _l++) {
              v = _ref2[_l];
              _results.push(v > threshold);
            }
            return _results;
          })();
        }
        if (_this.header != null) {
          _ref2 = _this.header;
          for (_l = 0, _len3 = _ref2.length; _l < _len3; _l++) {
            h = _ref2[_l];
            _this.header.push(h);
          }
        }
        return _this.draw();
      });
    };

    ReorderableMatrix.prototype.draw = function() {
      var borderHeight, d, drag, dragPosition, dragToIndex, fnColor, fnHeight, fnWidth, fnX, fnY, groupEls, groupInds, groupMarkerWidth, headerRow, heights, i, labelWidth, maxHeight, minHeight, nColumns, remat, rowHeights, scales, thresholds, totalWidth, width, _i, _len, _ref,
        _this = this;
      nColumns = this.data[0].vals.length;
      width = 800;
      labelWidth = 200;
      groupMarkerWidth = 200;
      totalWidth = width + labelWidth + groupMarkerWidth;
      maxHeight = 75;
      minHeight = 15;
      heights = [];
      rowHeights = [];
      thresholds = [];
      scales = [];
      _ref = this.data;
      for (i = _i = 0, _len = _ref.length; _i < _len; i = ++_i) {
        d = _ref[i];
        heights.push(d3.max(d.vals) / d.max * maxHeight);
        rowHeights.push(d3.max([heights[i], minHeight]));
        thresholds.push(d3.mean(d.vals));
        scales.push(d3.scale.linear().domain([0, d3.max(d.vals)]).range([0, heights[i]]));
      }
      fnHeight = function(d, i, j) {
        return scales[j](d);
      };
      fnWidth = function() {
        return parseInt(width / nColumns);
      };
      fnY = function(d, i, j) {
        return rowHeights[j] - fnHeight(d, i, j);
      };
      fnX = function(d, i) {
        return parseInt(width / nColumns) * i;
      };
      fnColor = function(d, i, j) {
        if (remat.data[j].aboveThreshold[i]) {
          return "#565656";
        }
        return "#c4c4c4";
      };
      headerRow = d3.select(this.el).append('svg').attr("height", 20).attr("width", totalWidth).attr("class", "rematHeaderRow");
      headerRow.selectAll('text').data(this.header).enter().append("svg:text").text(function(d, i) {
        return d;
      }).attr("x", function(d, i) {
        return fnX(d, i) + fnWidth(d, i) / 2;
      }).attr("y", 14).attr("width", fnWidth).attr("text-anchor", "middle");
      dragPosition = null;
      groupInds = null;
      groupEls = null;
      dragToIndex = null;
      remat = this;
      drag = d3.behavior.drag().origin(function(d) {
        return {
          x: d3.event.x,
          y: d3.event.y
        };
      }).on("drag", function() {
        var allY, e, elt, obj, start, startIndex, y, _j, _k, _l, _len1, _len2, _len3;
        dragPosition = null;
        dragToIndex = null;
        groupEls = null;
        allY = [];
        y = d3.event.y + $(document).scrollTop();
        d3.select(this).select(".rematRowBackground").style("fill", "#fd999c");
        d3.selectAll("div.rematRow").each(function(d, i) {
          return allY.push({
            y: $(this).position().top,
            el: this
          });
        }).select(".rematBottomBorder").attr("stroke", "none");
        allY.sort(function(a, b) {
          return a.y - b.y;
        });
        for (i = _j = 0, _len1 = allY.length; _j < _len1; i = ++_j) {
          obj = allY[i];
          if ((dragPosition == null) && y < obj.y) {
            if (i === 0) {
              dragPosition = allY[0];
              dragToIndex = 0;
            } else {
              dragPosition = allY[i - 1];
              dragToIndex = i - 1;
            }
          }
        }
        if (dragPosition === null) {
          dragPosition = allY[allY.length - 1];
          dragToIndex = allY.length - 1;
        }
        if (remat.mode === "reorder") {
          return d3.select(dragPosition.el).select(".rematBottomBorder").attr("stroke", "black");
        } else if (remat.mode === "addGroup") {
          start = $(this).position().top;
          for (i = _k = 0, _len2 = allY.length; _k < _len2; i = ++_k) {
            elt = allY[i];
            if (elt.y === start) {
              startIndex = i;
              break;
            }
          }
          groupInds = [Math.min(dragToIndex, startIndex), Math.max(dragToIndex, startIndex)];
          groupEls = [];
          for (i = _l = 0, _len3 = allY.length; _l < _len3; i = ++_l) {
            e = allY[i];
            if (i >= groupInds[0] && i <= groupInds[1]) {
              groupEls.push(e.el);
            }
          }
          return d3.selectAll(".rematRowBackground").style("fill", function(d, i) {
            if (i >= groupInds[0] && i <= groupInds[1]) {
              return "#fd999c";
            }
            return "none";
          });
        }
      }).on("dragend", function() {
        var el, g, g1, g2, _j, _len1;
        if (remat.mode === "reorder") {
          g = d3.select(this).datum().group;
          g1 = null;
          g2 = null;
          if (dragToIndex >= 0) {
            g1 = d3.select($('div.rematRow')[dragToIndex]).datum().group;
          }
          if (dragToIndex + 1 < $('div.rematRow').size()) {
            g2 = d3.select($('div.rematRow')[dragToIndex + 1]).datum().group;
          }
          if (g1 === g2) {
            d3.select(this).datum().group = g1;
          } else if (g !== g1 && g !== g2) {
            d3.select(this).datum().group = null;
          }
          d3.selectAll("div.rematRow").select(".rematBottomBorder").attr("stroke", "none");
          d3.selectAll(".rematRowBackground").style("fill", "none");
          $(dragPosition.el).after($(this).parent());
        } else if (remat.mode === "addGroup") {
          d3.selectAll("div.rematRow").select(".rematBottomBorder").attr("stroke", "none");
          d3.selectAll(".rematRowBackground").style("fill", "none");
          if (groupEls != null) {
            for (_j = 0, _len1 = groupEls.length; _j < _len1; _j++) {
              el = groupEls[_j];
              d3.select(el).datum().group = remat.groupCount;
            }
            remat.groupLabels[remat.groupCount] = "Group " + remat.groupCount;
            remat.groupCount++;
          }
        }
        groupEls = null;
        return remat.update();
      });
      borderHeight = 3;
      this.box = d3.select(this.el).append("div").attr("class", "rematBox");
      this.box.selectAll('div.rematRow').data(this.data).enter().append('div').attr("class", "rematRow").style("height", function(d, i) {
        return rowHeights[i] + borderHeight;
      }).style("cursor", "pointer").append('svg').call(drag).call(function() {
        var el, _j, _len1, _ref1, _results;
        _ref1 = this[0];
        _results = [];
        for (i = _j = 0, _len1 = _ref1.length; _j < _len1; i = ++_j) {
          el = _ref1[i];
          _results.push(d3.select(el).append("svg:rect").attr("class", "rematRowBackground").attr("x", 0).attr("y", 0).attr("width", width + labelWidth + 1).attr("height", rowHeights[i] + borderHeight + 5).attr("fill", "none"));
        }
        return _results;
      }).attr("class", "rematRowSVG").style("width", totalWidth).style("height", function(d, i) {
        return rowHeights[i] + borderHeight;
      }).selectAll('.rematColumn').data(function(d, i) {
        return d.vals;
      }).enter().append('svg:rect').attr("class", "rematColumn").attr("x", fnX).attr("height", fnHeight).attr("y", fnY).attr("width", fnWidth).attr("fill", fnColor).attr("stroke-width", 1).attr("stroke", "#eee");
      this.box.selectAll('.rematRowSVG').selectAll('.rematColumn').data(function(d, i) {
        return d.aboveThreshold;
      });
      this.box.selectAll('.rematRowSVG').append("svg:path").attr("class", "rematBottomBorder").attr("d", function(d, i) {
        var r;
        r = "M 0 " + (rowHeights[i] + borderHeight - 3);
        r += " L " + (width + labelWidth) + " " + (rowHeights[i] + borderHeight - 3);
        return r;
      }).attr("stroke", "none").attr("stroke-width", 2).style("stroke-dasharray", "7,7");
      this.box.selectAll('.rematRowSVG').append("svg:rect").attr("x", width + labelWidth).attr("y", -1).attr("width", 10).attr("height", function(d, i) {
        return rowHeights[i] + borderHeight + 2;
      }).attr("class", "rematGroupMarker").attr("fill", "none");
      this.box.selectAll('.rematRowSVG').append("svg:text").attr("x", width).attr("y", function(d, i) {
        return rowHeights[i] - 4;
      }).text(function(d, i) {
        return d.name;
      });
      this.box.selectAll('.rematRowSVG').append("svg:text").attr("font-weight", "bold").attr("class", "rematGroupLabel").attr("x", width + labelWidth + 13).attr("y", 15).text(function(d, i) {
        if (d.group != null) {
          return _this.groupLabels[d.group];
        }
        return "";
      });
      return this.box.selectAll('.rematRowSVG').append("svg:rect").attr("x", width + labelWidth + 13).attr("y", 0).attr("width", groupMarkerWidth).attr("height", 20).style("fill", "rgba(0, 0, 0,0)").on("click", function() {
        var datum, g;
        datum = d3.select(this).datum();
        g = datum.group;
        remat.groupLabels[g] = window.prompt("Rename '" + remat.groupLabels[g] + "'");
        return remat.update();
      });
    };

    ReorderableMatrix.prototype.update = function() {
      var seenGroups,
        _this = this;
      seenGroups = [];
      this.box.selectAll('.rematGroupMarker').attr("fill", function(d, i) {
        if (d.group != null) {
          return _this.groupColors(d.group);
        }
        return "none";
      });
      this.box.selectAll('.rematGroupLabel').text(function(d, i) {
        var _ref;
        if (_ref = d.group, __indexOf.call(seenGroups, _ref) < 0) {
          seenGroups.push(d.group);
          return _this.groupLabels[d.group];
        }
        return "";
      });
      return this.box.selectAll('.rematRowSVG').selectAll('.rematColumn').style("fill", function(d, i, j) {
        var datum;
        if (d) {
          datum = d3.select($('.rematRow')[j]).datum();
          if (datum.group != null) {
            return _this.groupColors(datum.group);
          } else {
            return "#565656";
          }
        }
        return "#c4c4c4";
      });
    };

    return ReorderableMatrix;

  })();

  window.ReorderableMatrix = ReorderableMatrix;

}).call(this);
