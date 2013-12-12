$ = jQuery

viz = [
  "hl-event",
  "hl-freedom",
  "hl-newsguns",
  "hl-typhoon",
  "hl-univision",
  "nohl-energy",
  "nohl-favor",
  "nohl-meaningful",
  "nohl-newsinterest",
  "nohl-superpower",
  "pew-facebooknews",
  "pew-globalwarming",
  "pew-jewswitching",
  "pew-racialgaps",
  "pew-womenworking"
]

class QueryString
    
    constructor: (@queryString) ->
        @queryString or= window.document.location.search?.substr 1
        @variables = @queryString.split '&'
        @pairs = ([key, value] = pair.split '=' for pair in @variables)
    
    get: (name) ->
        for [key, value] in @pairs
            return value if key is name

renderVis = (vis) ->
  $('body').spin 'modal'
  $('.pageTitle').html(vis)
  vur = new VisUnderstandingResult vis, $('.result'), => 
    $('body').spin 'modal'

$ ->
  qs = new QueryString()
  vis = qs.get 'vis'
  renderVis vis if vis?

  $select = $('.visSelect')
  for v in viz
    if v is vis
      $("""<option value="#{v}" selected>#{v}</option>""").appendTo($select)
    else
      $("""<option value="#{v}">#{v}</option>""").appendTo($select)
  $select.chosen()
    .change ->
      vis = $select.val()
      if vis isnt ''
        history.pushState null, vis, "result.html?vis=#{vis}"
        renderVis vis





