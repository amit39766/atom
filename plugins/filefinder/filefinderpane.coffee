$ = require 'jquery'
_ = require 'underscore'

File = require 'fs'
Pane = require 'pane'

jQuery  = $
facebox = eval File.read require.resolve 'filefinder/facebox'
require 'filefinder/stringscore'

module.exports =
class FilefinderPane extends Pane
  html: require "filefinder/filefinder.html"

  constructor: (@window, @filefinder) ->
    $('#filefinder input').live 'keydown', @onKeydown

    css   = File.read require.resolve 'filefinder/facebox.css'
    head  = $('head')[0]
    style = document.createElement 'style'
    rules = document.createTextNode css
    style.type = 'text/css'
    style.appendChild rules
    head.appendChild style

  onKeydown: (e) =>
    keys = up: 38, down: 40, enter: 13

    if e.keyCode is keys.enter
      @openSelected()
    else if e.keyCode is keys.up
      @moveUp()
    else if e.keyCode is keys.down
      @moveDown()
    else
      @filterFiles()

  toggle: ->
    if @showing
      $.facebox.close()
    else
      @showFinder()
    @showing = not @showing

  paths: -> 
    _paths = []
    for dir in File.list @window.path
      continue if /\.git|Cocoa/.test dir
      _paths.push File.listDirectoryTree dir
    _.reject _.flatten(_paths), (dir) -> File.isDirectory dir

  showFinder: ->
    $.facebox @html
    @files = []
    for file in @paths()
      @files.push file.replace "#{@window.path}/", ''
    @filterFiles()

  findMatchingFiles: (query) ->
    return [] if not query

    results = []
    for file in @files
      score = file.score query
      if score > 0
        # Basename matches count for more.
        if not query.match '/'
          if name.match '/'
            score += name.replace(/^.*\//, '').score query
          else
            score *= 2
        results.push [score, file]

    sorted = results.sort (a, b) -> b[0] - a[0]
    _.map sorted, (el) -> el[1]

  filterFiles: ->
    if query = $('#filefinder input').val()
      files = @findMatchingFiles query
    else
      files = @files
    $('#filefinder ul').empty()
    for file in files[0..10]
      $('#filefinder ul').append "<li>#{file}</li>"
    $('#filefinder input').focus()
    $('#filefinder li:first').addClass 'selected'

  openSelected: ->
    dir  = @window.path
    file = $('#filefinder .selected').text()
    @window.open "#{dir}/#{file}"
    @toggle()

  moveUp: ->
    selected = $('#filefinder .selected')
    if selected.prev().length
      selected.prev().addClass 'selected'
      selected.removeClass 'selected'

  moveDown: ->
    selected = $('#filefinder .selected')
    if selected.next().length
      selected.next().addClass 'selected'
      selected.removeClass 'selected'

