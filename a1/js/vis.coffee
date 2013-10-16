
$ = jQuery

$ ->
    d3.csv "executed.csv", (d) ->
        execution: d.Execution
        name: d["First Name"] + " " + d["Last Name"]
        age: d.Age
        date: new Date(d.Date)
        race: d.Race
        county: d.County
        statement: d["Last Statement"]
        info: d["Offender Information"]
    , (error, rows) ->
        window.ex = rows.reverse()

    d3.csv "allex.csv", (d) ->
        state: d.State
        date: new Date(d.Date)
    , (err, rows) ->
        window.allex = rows

    d3.json "govs.json", (d) ->
        window.govs = d
        for g in govs
            g.start = new Date(g.start)
            g.end = new Date(g.end)

window.go = =>
    compute()
    drawVis()

compute = ->
    govi = 0
    gov = window.govs[govi]
    gov.executed = []

    for e in window.ex
        if e.date < gov.end
            gov.executed.push(e)
        else
            govi += 1
            gov = window.govs[govi]
            gov.executed = [e]


    for g in window.govs
        g.days = (g.end - g.start) / (1000 * 60 * 60 * 24)

drawVis = ->
    svg = d3.select(".vis")
    .append("svg")
    .attr("width", 1500)
    .attr("height", 700)

    header = svg
    .append("text")
    .text("Executions in Texas under each governor since reinstatement of capital punishment in 1976")
    .attr("x", 0)
    .attr("y", 30)
    .attr("fill", "black")
    .attr("font-size", "30px")

    subhead = svg
    .append("text")
    .text("and a comparison to the rest of the nation.")
    .attr("x", 800)
    .attr("y", 62)
    .attr("fill", "#aaa")
    .attr("font-size", "30px")
    .attr('font-style', 'italic')

    runningX = []
    last = 10
    for g in window.govs
        runningX.push last
        last += g.days / 365 * GOV_WIDTH_PER_YEAR
    runningX.push last

    govNames = svg.selectAll('.govName')
    .data(window.govs)
    .enter()
    .append("text")
    .text((d, i) -> d.name)
    .attr("x", (d, i) -> runningX[i])
    .attr("y", GOV_NAMES_Y)
    .attr("fill", "black")
    .attr("font-size", "20px")

    govColor = svg.selectAll('.govColor')
    .data(window.govs)
    .enter()
    .append('svg:rect')
    .attr("fill", (d) -> if d.party is "Democrat" then "#9cb5ff" else "#ff7184")
    .attr("x", (d, i) -> runningX[i])
    .attr("width", (d, i) -> runningX[i + 1] - runningX[i] - 3)
    .attr("y", GOV_NAMES_Y + 5)
    .attr("height", 7)

    govs = window.govs
    ex = window.ex
    exct = ex.length

    x = d3.time.scale()
    .domain([govs[0].start, govs[govs.length - 1].end])
    .range([runningX[0], runningX[runningX.length - 1]])




    years = svg.selectAll('.yearLabel')
    .data([1980, 1990, 2000, 2010])
    .enter()
    .append('svg:text')
    .attr('x', (d, i) -> x(new Date("1/1/#{d}")))
    .attr('y', 650)
    .text((d, i) -> d)
    .attr('fill', '#666')
    .attr('font-size', '18px')

    # binSize = 13
    # radius = binSize / 2 - 1
    # nbins = parseInt((runningX[runningX.length - 1]) / binSize, 10) + 1

    nbins = (govs[govs.length - 1].end - govs[0].start) / (1000 * 60 * 60 * 25 * 365) * 3
    bins = (0 for i in [0...nbins])
    binSize = runningX[runningX.length - 1] / nbins
    radius = binSize / 2 - 1


    allex = window.allex

    allex = _.reject(allex, (d) -> d.state is 'TX')
    console.log allex

    for person in ex
        person.bin = parseInt(x(person.date) / binSize, 10)
        bins[person.bin] += 1
        person.binPos = bins[person.bin]

    for person in allex
        if person.state isnt "TX"
            person.bin = parseInt(x(person.date) / binSize, 10)
            bins[person.bin] += 1
            person.binPos = bins[person.bin]
            if person.bin < 0
                person.binPos = 1

    txpeople = svg.selectAll('.txperson')
    .data(ex)
    .enter()
    .append('svg:circle')
    .attr('cx', (d,i) -> d.bin * binSize - binSize / 2)
    .attr('cy', (d,i) -> GOV_NAMES_Y + 10 + d.binPos * binSize)
    .attr('r', radius)
    .attr('fill', '#222')

    otherpeople = svg.selectAll('.otherperson')
    .data(allex)
    .enter()
    .append('svg:circle')
    .attr('cx', (d, i) -> d.bin * binSize - binSize / 2)
    .attr('cy', (d, i) -> GOV_NAMES_Y + 10 + d.binPos * binSize)
    .attr('r', radius)
    .attr('fill', '#ddd')


    # LEGEND

    svg.append('svg:circle')
    .attr('cx', 50)
    .attr('cy', 400)
    .attr('r', radius)
    .attr('fill', '#222')

    svg.append('svg:circle')
    .attr('cx', 50)
    .attr('cy', 400 + binSize + 5)
    .attr('r', radius)
    .attr('fill', '#ccc')

    svg.append('svg:text')
    .attr('x', 50 + binSize)
    .attr('y', 400 + 5)
    .text('Execution in Texas')

    svg.append('svg:text')
    .attr('x', 50 + binSize)
    .attr('y', 400 + binSize + 10)
    .text('Execution elsewhere in the United States')

    svg.append('svg:text')
    .attr('x', 50 - binSize / 2)
    .attr('y', 400 + 2 * binSize + 25)
    .text('Note: there was a de facto moratorium on capital')
    
    svg.append('svg:text')
    .text('punishment for part of 2007-2008 while the')
    .attr('x', 50 - binSize / 2)
    .attr('y', 400 + 3 * binSize + 28)

    svg.append('svg:text')
    .text('Supreme Court considered an appeal on the')
    .attr('x', 50 - binSize / 2)
    .attr('y', 400 + 4 * binSize + 31)

    svg.append('svg:text')
    .text('constitutionality of lethal injection.')
    .attr('x', 50 - binSize / 2)
    .attr('y', 400 + 5 * binSize + 34)

    svg.append('svg:text')
    .text('Source: http://www.cnn.com/2008/CRIME/12/11/death.sentences/')
    .attr('x', 50 - binSize / 2)
    .attr('y', 400 + 6 * binSize + 37)
    .attr('font-size', '12px')
    .attr('font-style', 'italic')

    svg.append('svg:rect')
    .attr('stroke', '#222')
    .attr('stroke-width', .5)
    .attr('fill', 'rgba(0,0,0,0)')
    .attr('x', 50 - binSize)
    .attr('y', 400 - binSize)
    .attr('height', 143)
    .attr('width', 325)

    svg.append('svg:text')
    .text('Source: http://www.deathpenaltyinfo.org/')
    .attr('x', 1100)
    .attr('y', 680)
    .attr('font-size', '14px')
    .attr('font-style', 'italic')

    



GOV_WIDTH_TOTAL = 150
GOV_WIDTH_PER_YEAR = 40
GOV_WIDTH = GOV_WIDTH_PER_YEAR - 7
PADDING = GOV_WIDTH_TOTAL - GOV_WIDTH
BAR_WIDTH = (GOV_WIDTH - PADDING * 2) / 3
GOV_NAMES_Y = 100

drawGovernor2 = (govi, svg) ->
    gov = window.govs[govi]


drawGovernor = (govi, svg) ->
    gov = window.govs[govi]

    offset = GOV_WIDTH_TOTAL * govi

    svg.selectAll(".gov#{govi}")
    .append("svg:g")

    races = _.groupBy(gov.executed, (d) -> d.race)

    console.log races

    raceList = ["Hispanic", "White", "Black"]
    colors = ["#ccc", "#aaa" ,"#888"]


    raceArray = [0, 0, 0]

    for race, val of races
        racei = raceList.indexOf(race)
        if racei isnt -1
            raceArray[racei] = val.length

    console.log raceArray

    svg.selectAll(".ethName#{govi}")
    .data(raceList)
    .enter()
    .append("text")
    .text((d, i) -> d)
    .attr("x", (d, i) -> offset + PADDING * i + BAR_WIDTH * i)
    .attr("y", GOV_NAMES_Y + 25)
    .attr("font-size", "12px")
    .attr("fill", "black")


    svg.selectAll(".eth#{govi}")
    .data(raceArray)
    .enter()
    .append("svg:rect")
    .attr("fill", (d, i) -> colors[i])
    .attr("x", (d, i) -> offset + PADDING * i + BAR_WIDTH * i)
    .attr("y", GOV_NAMES_Y + 30)
    .attr("height", (d, i) -> 15000 * (d / gov.days))
    .attr("width", (d, i) -> BAR_WIDTH)

    svg.selectAll(".ethCount#{govi}")
    .data(raceArray)
    .enter()
    .append("text")
    .text((d, i) ->
        if d isnt 0
            return "1 every #{parseInt(gov.days / d, 10)} days"
        else
            return ""
    )
    .attr("transform", (d, i) ->
        x = offset + PADDING * i + BAR_WIDTH * i + 17
        y = GOV_NAMES_Y + 35 + 15000 * (d / gov.days)
        return "translate(#{x},#{y})rotate(90)"
    )
    # .attr("x", (d, i) -> offset + PADDING + i + BAR_WIDTH * i)
    # .attr("y", GOV_NAMES_Y + 40)

