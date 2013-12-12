(function() {
  var $, QueryString, renderVis, viz;

  $ = jQuery;

  viz = ["hl-event", "hl-freedom", "hl-newsguns", "hl-typhoon", "hl-univision", "nohl-energy", "nohl-favor", "nohl-meaningful", "nohl-newsinterest", "nohl-superpower", "pew-facebooknews", "pew-globalwarming", "pew-jewswitching", "pew-racialgaps", "pew-womenworking"];

  QueryString = (function() {
    function QueryString(queryString) {
      var key, pair, value, _ref;
      this.queryString = queryString;
      this.queryString || (this.queryString = (_ref = window.document.location.search) != null ? _ref.substr(1) : void 0);
      this.variables = this.queryString.split('&');
      this.pairs = (function() {
        var _i, _len, _ref1, _ref2, _results;
        _ref1 = this.variables;
        _results = [];
        for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
          pair = _ref1[_i];
          _results.push((_ref2 = pair.split('='), key = _ref2[0], value = _ref2[1], _ref2));
        }
        return _results;
      }).call(this);
    }

    QueryString.prototype.get = function(name) {
      var key, value, _i, _len, _ref, _ref1;
      _ref = this.pairs;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        _ref1 = _ref[_i], key = _ref1[0], value = _ref1[1];
        if (key === name) {
          return value;
        }
      }
    };

    return QueryString;

  })();

  renderVis = function(vis) {
    var vur,
      _this = this;
    $('body').spin('modal');
    $('.pageTitle').html(vis);
    return vur = new VisUnderstandingResult(vis, $('.result'), function() {
      return $('body').spin('modal');
    });
  };

  $(function() {
    var $select, qs, v, vis, _i, _len;
    qs = new QueryString();
    vis = qs.get('vis');
    if (vis != null) {
      renderVis(vis);
    }
    $select = $('.visSelect');
    for (_i = 0, _len = viz.length; _i < _len; _i++) {
      v = viz[_i];
      if (v === vis) {
        $("<option value=\"" + v + "\" selected>" + v + "</option>").appendTo($select);
      } else {
        $("<option value=\"" + v + "\">" + v + "</option>").appendTo($select);
      }
    }
    return $select.chosen().change(function() {
      vis = $select.val();
      if (vis !== '') {
        history.pushState(null, vis, "result.html?vis=" + vis);
        return renderVis(vis);
      }
    });
  });

}).call(this);
