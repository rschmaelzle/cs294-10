# Steve Rubin - srubin@cs.berkeley.edu
# Completed 10/16/2013
#   for CS294-10 - Visualization, assignment 3

$ = jQuery

class ReorderableMatrix
    constructor: (@el) ->
        # set up buttons
        controls = d3.select(@el)
        .append("div")

        controls.append("strong")
        .html("Mode:")

        @reorderButton = controls.append("button")
        .html("Reorder rows")

        @groupBtn = controls.append("button")
        .html("Create group")
        
        @statusText = controls.append("div")
        .html("")

        controls.append("hr")

        # mode info
        @modes =
            reorder:
                status: "Drag to reorder rows"
                button: @reorderButton
            addGroup:
                status: "Drag over several rows to create group. Click a group name to edit."
                button: @groupBtn

        for m, obj of @modes
            do (m) =>
                obj.button.on("click", => @setMode(m))

        @setMode "reorder"

        @groupColors = d3.scale.category10()
        .domain([0..9])

        @groupCount = 0
        @groupLabels = []

    setMode: (mode) ->
        @mode = mode
        @statusText.html(@modes[mode].status)

        for m, obj of @modes
            obj.button.attr("disabled", null)

        @modes[mode].button.attr("disabled", "disabled")

    load: (filename, noHeader) ->
        # load in csv from filename with format
        # name, max-value, val, val, val, val...
        d3.text filename, (data) =>
            data = d3.csv.parseRows data
            if not noHeader?
                @header = data[0].slice 2
                data = data.slice 1
            else
                @header = null

            @data = []
            for d, i in data
                datum = {}
                datum.name = d[0]
                datum.max = d[1]
                datum.vals = (+x for x in d.slice 2)
                datum.group = null
                @data.push datum

            # double it!
            for d in @data
                for v in d.vals
                    d.vals.push v
                threshold = d3.mean d.vals
                d.aboveThreshold = (v > threshold for v in d.vals)
            if @header?
                for h in @header
                    @header.push h

            @draw()

    draw: ->
        # draw the initial visualization
        nColumns = @data[0].vals.length
        width = 800
        labelWidth = 200
        groupMarkerWidth = 200
        totalWidth = width + labelWidth + groupMarkerWidth
        maxHeight = 75
        minHeight = 15

        heights = []
        rowHeights = []
        thresholds = []
        scales = []
        for d, i in @data
            heights.push d3.max(d.vals) / d.max * maxHeight
            rowHeights.push d3.max([heights[i], minHeight])
            thresholds.push d3.mean d.vals
            scales.push(
                d3.scale.linear()
                .domain([0, d3.max(d.vals)])
                .range([0, heights[i]])
            )

        fnHeight = (d, i, j) -> scales[j] d
        fnWidth = -> parseInt(width / nColumns)
        fnY = (d, i, j) -> rowHeights[j] - fnHeight(d, i, j)
        fnX = (d, i) -> parseInt(width / nColumns) * i
        fnColor = (d, i, j) ->
            if remat.data[j].aboveThreshold[i]
                return "#565656"
            "#c4c4c4"

        headerRow = d3.select(@el)
        .append('svg')
        .attr("height", 20)
        .attr("width", totalWidth)
        .attr("class", "rematHeaderRow")

        headerRow.selectAll('text')
        .data(@header)
        .enter()
        .append("svg:text")
        .text((d, i) -> d)
        .attr("x", (d, i) -> fnX(d, i) + fnWidth(d, i) / 2)
        .attr("y", 14)
        .attr("width", fnWidth)
        .attr("text-anchor", "middle")

        dragPosition = null
        groupInds = null
        groupEls = null
        dragToIndex = null

        remat = @

        drag = d3.behavior.drag()
        .origin((d) ->
            x: d3.event.x
            y: d3.event.y
        )
        .on("drag", ->
            dragPosition = null
            dragToIndex = null
            groupEls = null
            allY = []
            y = d3.event.y + $(document).scrollTop()

            d3.select(this)
            .select(".rematRowBackground")
            .style("fill", "#fd999c")

            d3.selectAll("div.rematRow")
            .each((d, i) ->
                allY.push
                    y: $(this).position().top
                    el: this
            )
            .select(".rematBottomBorder")
            .attr("stroke", "none")
            allY.sort((a, b) ->
                a.y - b.y
            )

            for obj, i in allY
                if not dragPosition? and y < obj.y
                    if i is 0
                        dragPosition = allY[0]
                        dragToIndex = 0
                    else
                        dragPosition = allY[i - 1]
                        dragToIndex = i - 1
            if dragPosition is null
                dragPosition = allY[allY.length - 1]
                dragToIndex = allY.length - 1

            if remat.mode is "reorder"
                d3.select(dragPosition.el)
                .select(".rematBottomBorder")
                .attr("stroke", "black")

            else if remat.mode is "addGroup"
                start = $(this).position().top
                for elt, i in allY
                    if elt.y is start
                        startIndex = i
                        break
                groupInds = [
                    Math.min(dragToIndex, startIndex),
                    Math.max(dragToIndex, startIndex)
                ]

                groupEls = []
                for e, i in allY
                    if i >= groupInds[0] and i <= groupInds[1]
                        groupEls.push e.el

                d3.selectAll(".rematRowBackground")
                .style("fill", (d, i) ->
                    if i >= groupInds[0] and i <= groupInds[1]
                        return "#fd999c"
                    "none"
                )


        ).on("dragend", ->
            if remat.mode is "reorder"
                g = d3.select(this).datum().group
                g1 = null
                g2 = null

                if dragToIndex >= 0
                    g1 = d3.select($('div.rematRow')[dragToIndex])
                    .datum().group

                if dragToIndex + 1 < $('div.rematRow').size()
                    g2 = d3.select($('div.rematRow')[dragToIndex + 1])
                    .datum().group

                if g1 is g2
                    d3.select(this).datum().group = g1
                else if g isnt g1 and g isnt g2
                    d3.select(this).datum().group = null


                d3.selectAll("div.rematRow")
                .select(".rematBottomBorder")
                .attr("stroke", "none")

                d3.selectAll(".rematRowBackground")
                .style("fill", "none")

                $(dragPosition.el).after($(this).parent())

            else if remat.mode is "addGroup"
                d3.selectAll("div.rematRow")
                .select(".rematBottomBorder")
                .attr("stroke", "none")
                
                d3.selectAll(".rematRowBackground")
                .style("fill", "none")

                if groupEls?
                    for el in groupEls
                        d3.select(el).datum().group = remat.groupCount

                    remat.groupLabels[remat.groupCount] = "Group #{remat.groupCount}"
                    remat.groupCount++

            groupEls = null
            remat.update()
        )

        borderHeight = 3

        @box = d3.select(@el)
        .append("div")
        .attr("class", "rematBox")

        @box.selectAll('div.rematRow')
        .data(@data)
        .enter()
        .append('div')
        .attr("class", "rematRow")
        .style("height", (d, i) -> rowHeights[i] + borderHeight)
        .style("cursor", "pointer")
        .append('svg')
        .call(drag)
        .call( ->
            # this is very ugly, but I have to get the background
            # in somehow
            for el, i in this[0]
                d3.select(el)
                .append("svg:rect")
                .attr("class", "rematRowBackground")
                .attr("x", 0)
                .attr("y", 0)
                .attr("width", width + labelWidth + 1)
                .attr("height", rowHeights[i] + borderHeight + 5)
                .attr("fill", "none")
        )
        .attr("class", "rematRowSVG")
        .style("width", totalWidth)
        .style("height", (d, i) -> rowHeights[i] + borderHeight)
        .selectAll('.rematColumn')
        .data((d, i) -> d.vals)
        .enter()
        .append('svg:rect')
        .attr("class", "rematColumn")
        .attr("x", fnX)
        .attr("height", fnHeight)
        .attr("y", fnY)
        .attr("width", fnWidth)
        .attr("fill", fnColor)
        .attr("stroke-width", 1)
        .attr("stroke", "#eee")

        @box.selectAll('.rematRowSVG')
        .selectAll('.rematColumn')
        .data((d, i) -> d.aboveThreshold)

        @box.selectAll('.rematRowSVG')
        .append("svg:path")
        .attr("class", "rematBottomBorder")
        .attr("d", (d, i) ->
            r = "M 0 #{rowHeights[i] + borderHeight - 3}"
            r += " L #{width + labelWidth} #{rowHeights[i] + borderHeight - 3}"
        )
        .attr("stroke", "none")
        .attr("stroke-width", 2)
        .style("stroke-dasharray", "7,7")

        @box.selectAll('.rematRowSVG')
        .append("svg:rect")
        .attr("x", width + labelWidth)
        .attr("y", -1)
        .attr("width", 10)
        .attr("height", (d, i) -> rowHeights[i] + borderHeight + 2)
        .attr("class", "rematGroupMarker")
        .attr("fill", "none")

        @box.selectAll('.rematRowSVG')
        .append("svg:text")
        .attr("x", width)
        .attr("y", (d, i) -> rowHeights[i] - 4)
        .text((d, i) -> d.name)

        @box.selectAll('.rematRowSVG')
        .append("svg:text")
        .attr("font-weight", "bold")
        .attr("class", "rematGroupLabel")
        .attr("x", width + labelWidth + 13)
        .attr("y", 15)
        .text((d, i) =>
            if d.group?
                return @groupLabels[d.group]
            ""
        )

        @box.selectAll('.rematRowSVG')
        .append("svg:rect")
        .attr("x", width + labelWidth + 13)
        .attr("y",  0)
        .attr("width", groupMarkerWidth)
        .attr("height", 20)
        .style("fill", "rgba(0, 0, 0,0)")
        .on("click", ->
            datum = d3.select(this).datum()
            g = datum.group
            remat.groupLabels[g] =\
                window.prompt("Rename '#{remat.groupLabels[g]}'")
            remat.update()
        )


    update: ->
        # update the visualization (based on created groups)
        seenGroups = []
        @box.selectAll('.rematGroupMarker')
        .attr("fill", (d, i) =>
            if d.group?
                return @groupColors d.group
            "none"
        )

        @box.selectAll('.rematGroupLabel')
        .text((d, i) =>
            if d.group not in seenGroups
                seenGroups.push d.group
                return @groupLabels[d.group]
            ""
        )

        @box.selectAll('.rematRowSVG')
        .selectAll('.rematColumn')
        .style("fill", (d, i, j) =>
            if d
                datum = d3.select($('.rematRow')[j]).datum()
                if datum.group?
                    return @groupColors datum.group
                else
                    return "#565656"
            "#c4c4c4"
        )

window.ReorderableMatrix = ReorderableMatrix