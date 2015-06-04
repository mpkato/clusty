$ ->
    diameter = $("#field").width()
    format = d3.format(",d")
    padding = 1.5
    clusterPadding = 1
    maxRadius = 1

    selectedobj = null
    draggingobj = null

    pack = d3.layout.pack()
        .size([diameter - 4, diameter - 4])
        .value((d) ->
            return d.size
        )

    d3.selectAll("#field div").remove()

    svg = d3.select("#field").append("svg")
        .attr("width", diameter)
        .attr("height", diameter)
        .append("g")
        .attr("transform", "translate(2,2)")

    update = (j) ->
        nodes = pack.nodes(j)
        node = svg.selectAll(".node")
            .data(nodes)
            .enter().append("g")
            .attr("class", (d) ->
                return if d.children then "node" else "leaf node"
            )
            .attr("transform", (d) ->
                return "translate(" + d.x + "," + d.y + ")"
            )
            .sort((a, b) ->
                if !a.children
                    return 1
                else
                    return -1
            )
        return node

    d3.json("/projects/cluster_json", (error, root) ->
        node = update(root)
        node.filter((d) ->
            d.children
        )
            .on("mouseover", (d) ->
                selectedobj = @
            )
            .on("mouseout", (d) ->
                selectedobj = null
            )

        drag = d3.behavior.drag()
            .on("dragstart", (d,i) ->
                draggingobj = @
                d3.select(@)
                    .attr("style", "fill: rgb(255, 255, 255)")
                node
                    .sort((a, b) ->
                        if a is d
                            return -1
                        if b is d
                            return 1
                        if !a.children
                            return 1
                        else
                            return -1
                    )
            )
            .on("drag", (d,i) ->
                if !d.tmpx or !d.tmpy
                    d.tmpx = d.x
                    d.tmpy = d.y
                d.tmpx += d3.event.dx
                d.tmpy += d3.event.dy
                d3.select(this).attr("transform", (d,i) ->
                    return "translate(" + d.tmpx + "," + d.tmpy + ")"
                )
            )
            .on("dragend", (d, i) ->
                console.log(selectedobj)
                d3.select(this).attr("style", "fill: rgb(0, 0, 0)")
                svg.selectAll(".leaf")
                    .each((d) ->
                        delete d.tmpx
                        delete d.tmpy
                    )
                    .transition().duration(1000)
                    .attr("transform", (d) ->
                        return "translate(" + d.x + "," + d.y + ")"
                    )
                d3.select(selectedobj).attr("style", "stroke: red;")
                node
                    .sort((a, b) ->
                        if !a.children
                            return 1
                        else
                            return -1
                    )
            )
        svg.selectAll(".leaf").call(drag)


        collide = (alpha) ->
            quadtree = d3.geom.quadtree(nodes.filter((d) ->
                !d.children
            ))
            return (d) ->
                r = d.r + maxRadius + Math.max(padding, clusterPadding)
                nx1 = d.x - r
                nx2 = d.x + r
                ny1 = d.y - r
                ny2 = d.y + r
                quadtree.visit((quad, x1, y1, x2, y2) ->
                    if (quad.point and (quad.point isnt d))
                        x = d.x - quad.point.x
                        y = d.y - quad.point.y
                        d.x -= x * 0.1
                        d.y -= y * 0.1
                    return x1 > nx2 || x2 < nx1 || y1 > ny2 || y2 < ny1
                )

        tick = (e) ->
            k = e.alpha
            svg.selectAll(".leaf")
                .each((d) ->
                    x = d.x - d.parent.x
                    y = d.y - d.parent.y
                    d.x -= x * 0.1
                    d.y -= y * 0.1
                )
                .attr("transform", (d) ->
                    return "translate(" + d.x + "," + d.y + ")"
                )

        ###
        force = d3.layout.force()
            .nodes(nodes.filter((d) ->
                !d.children
            ))
            .size([diameter, diameter])
            .gravity(.1)
            .charge(0.1)
            .on("tick", tick)
            .start()

        svg.selectAll(".leaf")
            .call(force.drag)
        ###

        node.append("title")
            .text((d) ->
                return d.name + (if d.children then "" else  ": " + format(d.size))
            )
        node.append("circle")
            .attr("r", (d) -> 
                return d.r
            )
        node.filter((d) ->
            return !d.children
        )
            .append("text")
            .attr("dy", ".3em")
            .style("text-anchor", "middle")
            .text((d) -> 
                return d.parent.name.substring(0, d.r / 3)
            )

    )


