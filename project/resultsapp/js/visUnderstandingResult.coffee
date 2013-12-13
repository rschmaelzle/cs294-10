$ = jQuery

class ScoreVis
    constructor: (@hist, @statements, @$el, @callback) ->
        data = []
        @$el.html('')

        countTotal = _.reduce @hist.count, ((memo, num) -> memo + num), 0
        for bin, i in @hist.bin
            data.push
                bin: bin
                count: @hist.count[i]
                normCount: @hist.count[i] / countTotal

        w = 390
        h = 300
        padding = 30

        barWidth = (w - 2 * padding) / @hist.count.length

        xScale = d3.scale.linear()
            .domain([0, 1])
            .range([padding, w - padding * 2])

        yScale = d3.scale.linear()
            .domain([0, d3.max(data, (d) -> d.normCount)])
            .range([h - padding, padding])

        xAxis = d3.svg.axis()
            .scale(xScale)
            .orient("bottom")
            .ticks(5)

        formatPercent = d3.format(".0%")
        yAxis = d3.svg.axis()
            .scale(yScale)
            .orient("left")
            .ticks(5)
            .tickFormat(formatPercent)

        svg = d3.select(@$el[0])
            .append("svg")
            .attr("width", w)
            .attr("height", h)

        svg.selectAll(".scoreBar")
            .data(data)
            .enter()
            .append("svg:rect")
            .classed("scoreBar", true)
            .attr("x", (d) -> xScale(d.bin) - .5 * barWidth + 3)
            .attr("y", (d) -> yScale(d.normCount))
            .attr("width", barWidth - 6)
            .attr("height", (d) -> yScale(0) - yScale(d.normCount))
            .attr("fill", "#7a4e91")
            .on('mouseover', (d) ->
                d3.select(this).style("fill", "#4c007e")
            ).on('mouseout', (d) ->
                d3.select(this).style("fill", "#7a4e91")
            ).on('click', (d, i) =>
                @showStatements d
            )

        svg.append("g")
            .attr("class", "axis")
            .attr("transform", "translate(0," + (h - padding) + ")")
            .call(xAxis)

        svg.append("g")
            .attr("class", "axis")
            .attr("transform", "translate(" + padding + ",0)")
            .call(yAxis)

        @$el.append('<div class="scoreStatements"></div>')
        @$statementEl = @$el.find('.scoreStatements')

        @callback()

    showStatements: (bin) ->
        binSize = 1 / (@hist.count.length)
        min = bin.bin - binSize / 2
        max = bin.bin + binSize / 2
        floatFormat = d3.format('.02f')
        stmts = []
        for s in @statements
            if max is 1
                if s.score >= min and s.score <= 1
                    stmts.push s
            else if s.score >= min and s.score < max
                stmts.push s

        @$statementEl.html("""
            <h4>Score in range #{floatFormat min}-#{floatFormat max}</h4>
            <ul class="list-unstyled"></ul>""")

        $ul = @$statementEl.find('ul')

        sortedStatements = stmts.sort (a, b) =>
            b.score - a.score

        (renderStatement(s, $ul) for s in sortedStatements)


class SpreadVis
    constructor: (@statements, @nuggets, @$el, @callback) ->
        @$el.html('')
        data = []
        for nug in @nuggets
            if nug.statements.length isnt 0
                data.push
                    count: nug.statements.length
                    nugget: nug.nugget
                    statements: nug.statements
                    score: nug.score
        data = data.sort (a, b) -> b.count - a.count


        w = 390
        h = 300
        padding = 30

        barWidth = (w - 2 * padding) / data.length

        xScale = d3.scale.linear()
            .domain([0, data.length])
            .range([padding, w - padding * 2])

        yScale = d3.scale.linear()
            .domain([0, d3.max(data, (d) -> d.count)])
            .range([h - padding, padding])

        xAxis = d3.svg.axis()
            .scale(xScale)
            .orient("bottom")
            .ticks(0)

        yAxis = d3.svg.axis()
            .scale(yScale)
            .orient("left")
            .ticks(5)

        svg = d3.select(@$el[0])
            .append("svg")
            .attr("width", w)
            .attr("height", h)

        @$el.append('<div class="venn"><h4>Response overlap</h4><div class="spreadVenn"></div></div>')
        @$vennEl = @$el.find('.spreadVenn')

        @$el.append('<div class="spreadStatements"></div>')
        @$statementEl = @$el.find('.spreadStatements')



        tooltip = d3.tip().attr('class', 'd3-tip')
            .html((d) -> d.nugget)
            .direction('s')
            .offset([5,0])

        colors = d3.scale.ordinal()
            .domain([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10])
            .range(colorbrewer.RdYlGn[11])

        svg.call(tooltip)

        svg.selectAll(".spreadBar")
            .data(data)
            .enter()
            .append("svg:rect")
            .attr("x", (d, i) -> xScale(i) + 2)
            .attr("y", (d) -> yScale(d.count))
            .attr("width", barWidth - 10)
            .attr("height", (d) -> yScale(0) - yScale(d.count))
            .style("fill", (d) ->
                colors Math.ceil d.score * 10
            )
            .classed("spreadBar", true)
            .on('mouseover', (d) ->
                # d3.select(this).style("fill", "#4c007e")
                tooltip.show(d)
            ).on('mouseout', (d) ->
                # d3.select(this).style("fill", "#7a4e91")
                tooltip.hide(d)
            ).on('click', (d, i) =>
                @showStatements d
            )

        svg.append("g")
            .attr("class", "axis")
            .attr("transform", "translate(0," + (h - padding) + ")")
            .call(xAxis)

        svg.append("g")
            .attr("class", "axis")
            .attr("transform", "translate(" + padding + ",0)")
            .call(yAxis)

        @renderVenn()
        # catch
            # @$el.find('.venn').remove()

        @callback()

    showStatements: (nugget) ->
        statements = nugget.statements

        @$statementEl.html("""
            <h4>#{nugget.nugget}</h4>
            <ul class="list-unstyled"></ul>""")

        $ul = @$statementEl.find('ul')

        sortedStatements = statements.sort (i, j) =>
            @statements[j].score - @statements[i].score

        (renderStatement(@statements[i], $ul) for i in sortedStatements)

    renderVenn: ->
        sets = []
        nugs = []
        offsets = []
        maxSize = 0
        for nug, i in @nuggets
            if nug.statements.length > 0
                nugs.push nug
                offsets.push i
                sets.push
                    label: ''
                    size: nug.statements.length
                if nug.statements.length > maxSize
                    maxSize = nug.statements.length

        overlaps = {}

        for c in @combinations(i for offset, i in offsets)
            if c.length > 1
                cString = c.join ','
                overlaps[c] = 0

        for s in @statements
            ns = s.nuggets
            offsetted = (offsets.indexOf(n) for n in ns)
            combs = @combinations offsetted
            for c in combs
                if c.length isnt 1
                    cString = c.join ','
                    overlaps[cString] += 1

        olaps = []
        for olap, v of overlaps
            if v isnt 0
                olaps.push
                    sets: (parseInt(i) for i in olap.split ',')
                    size: v

        console.log "sets", sets
        console.log "olaps", olaps

        try
            vsets = venn.venn sets, olaps
        catch e
            console.log "hmm", e
            vsets = venn.venn sets, olaps, layoutFunction: venn.classicMDSLayout

        venn.drawD3Diagram d3.select(@$vennEl[0]), vsets, 380, 300


        svg = d3.select(@$vennEl[0]).select('svg')

        tooltip = d3.tip().attr('class', 'd3-tip')
            .html((d, i) => @nuggets[offsets[i]].nugget + "(#{@nuggets[offsets[i]].statements.length})")
            .direction('s')
            .offset([5,0])

        svg.call(tooltip)

        svg.selectAll('circle')
            .each( (d, i) ->
                circle = this
                d3.select(this)
                    .on('mouseover', =>
                        tooltip.show(d, i)
                        d3.select(circle)
                            .attr('stroke', 'black')
                    )
                    .on('mouseout', =>
                        tooltip.hide(d, i)
                        d3.select(circle)
                            .attr('stroke', 'none')
                    )
            )


        filterVenn = (val) ->
            svg.selectAll('circle')
                .each( (d, i) ->
                    if d.size < val
                        d3.select(this).style('display', 'none')
                    else
                        d3.select(this).style('display', 'block')
                )

        $slider = $(document.createElement 'div')
            .attr('class', 'sliderBox')
            .css('width', '100%')
            .appendTo(@$vennEl)
        slider = $slider.slider({
                min: 1
                max: maxSize
                step: 1
                value: 1
        }).on('slide', (e) ->
            filterVenn slider.getValue()
        ).data('slider')

    combinations: (ids) ->
        result = []
        f = (prefix, ids) ->
            i = 0

            while i < ids.length
                newPrefix = prefix.slice 0
                newPrefix.push ids[i]
                result.push newPrefix
                f newPrefix, ids.slice(i + 1)
                i++

        f [], ids
        result

renderStatement = (statement, $el) ->
    floatFormat = d3.format('.02f')
    colors = d3.scale.ordinal()
        .domain([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10])
        .range(colorbrewer.RdYlGn[11])
    s = statement.statement
    $li = $("<li>#{s}</li>").appendTo($el)
    score = statement.score
    scoreBin = Math.ceil statement.score * 10
    scoreColor = colors(scoreBin)
    if scoreBin > 6 or scoreBin < 3
        textColor = 'white'
    else
        textColor = 'black'
    $(document.createElement 'div')
        .css(
            background: scoreColor
            width: "40px"
            height: "40px"
            color: textColor
            "font-size": "10pt"
            "font-weight": "bold"
            "text-align": "center"
            "vertical-align": "middle"
            "-moz-border-radius": "20px"
            "border-radius": "20px"
            "float": "left"
            "line-height": "40px"
            "margin-right": "5px"
        )
        .html(floatFormat score)
        .prependTo($li)

class VisUnderstandingResult
    constructor: (@vis, @$el, @callback) ->
        # add the visualization image
        @$el.find('.visImg').html("""
            <img src="data/#{@vis}/0.png" />
            """)

        $.getJSON "data/#{@vis}/result.csv", (res) =>
            @nuggets = res.nuggets
            @statements = res.statements
            @scoreHist = res.score_histogram

            cb = _.after 2, @callback

            scov = new ScoreVis @scoreHist, @statements, @$el.find('.scoreHist'), cb
            sprv = new SpreadVis @statements, @nuggets, @$el.find('.spread'), cb

            averageScore = d3.mean(@statements, (d) -> d.score)
            floatFormat = d3.format('.02f')
            $('.avgScore').html(floatFormat averageScore)

window.VisUnderstandingResult = VisUnderstandingResult