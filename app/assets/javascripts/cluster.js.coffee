$ ->
    trans = (x, y) ->
        return "translate(#{x}, #{y})"

    class Cluster
        # constant
        @DURATION = 100
        @CHILD_WIDTH = 15
        @PARENT_WIDTH = 300
        @LIST_WIDTH = 200
        @LIST_MARGIN = 20

        constructor: (target, root, width, height) ->
            that = @
            @selectedNode = null
            @draggingNode = null
            @root = root
            @index = 1

            baseSvg = d3.select(target).append("svg")
                .attr("width", width)
                .attr("height", height)
                .attr("class", "overlay")

            @svgGroup = baseSvg.append("g")
                .attr("width", width)
                .attr("height", height)

            @svgGroup.append("rect")
                .attr("width", width)
                .attr("height", height)
                .attr("opacity", 0)
                .on("dblclick", @createParent())

            @root.x = 0
            @root.y = 0
            @root.width = width - (Cluster.LIST_WIDTH + Cluster.LIST_MARGIN)
            @root.height = height
            @initlayout()

        parents: () ->
            return @root.children.filter((d) -> !d.orphan)

        orphan: () ->
            return @root.children.filter((d) -> d.orphan)[0]

        createParent: () ->
            that = @
            return (d) ->
                console.log()
                xy = d3.mouse(@)
                console.log(xy)
                that.root.children.push(
                    {x: xy[0], y: xy[1], children: [],
                    width: Cluster.PARENT_WIDTH, height: Cluster.PARENT_WIDTH})
                that.justupdate()


        # Define the drag listeners for drag/drop behaviour of nodes.
        parentDragListener: ->
            that = @
            return d3.behavior.drag()
            .on("dragstart", (d) ->
                d.x0 = d.x
                d.y0 = d.y
                d3.event.sourceEvent.stopPropagation()
                if !d.children
                    that.draggingNode = d
                    that.sort()
                else
                    that.svgGroup.selectAll("g.node rect")
                        .filter((c) -> d.children.indexOf(c) > -1)
                        .each((c) ->
                            c.x0 = c.x
                            c.y0 = c.y
                        )
            )
            .on("drag", (d) ->
                d.x0 += d3.event.dx
                d.y0 += d3.event.dy
                d3.select(@)
                    .attr("transform", (c) -> trans(c.x0, c.y0))
                that.svgGroup.selectAll("g.node rect.resizehandle")
                    .filter((c) -> c is d)
                    .attr("transform", (c) -> trans(c.x0 + c.width, c.y0 + c.height))

                if d.children
                    that.svgGroup.selectAll("g.child")
                        .filter((c) -> d.children.indexOf(c) > -1)
                        .each((c) ->
                            c.x0 += d3.event.dx
                            c.y0 += d3.event.dy
                        )
                        .attr("transform", (c) -> trans(c.x0, c.y0))

            ).on("dragend", (d) ->
                if that.selectedNode
                    console.log(that.selectedNode)
                    index = that.draggingNode.parent.children.indexOf(that.draggingNode)
                    if index > -1
                        that.draggingNode.parent.children.splice(index, 1)
                    if typeof that.selectedNode.children isnt 'undefined'
                        that.selectedNode.children.push(that.draggingNode)
                    else
                        that.selectedNode.children = []
                        that.selectedNode.children.push(that.draggingNode)
                    that.childupdate([that.draggingNode.parent, that.selectedNode])
                    that.selectedNode = null
                else
                    if d.children
                        d.x = d.x0
                        d.y = d.y0
                        that.svgGroup.selectAll("g.node")
                            .filter((c) -> d.children.indexOf(c) > -1)
                            .each((c) -> 
                                c.x = c.x0
                                c.y = c.y0
                            )
                    else
                        d3.select(@).attr("transform", (c) -> trans(c.x, c.y))

                that.draggingNode = null
                that.sort()
            )

        sort: ->
            that = @
            @svgGroup.selectAll("g").sort((a, b) ->
                if a is that.draggingNode
                    return -1
                else if b is that.draggingNode
                    return 1
                else if a.children
                    return -1
                else if b.children
                    return 1
                else if a.id < b.id
                    return -1
                else
                    return 1
            )

        resizeDragListener: ->
            that = @
            return d3.behavior.drag()
            .on("dragstart", (d) ->
                d3.event.sourceEvent.stopPropagation()
            )
            .on("drag", (d) ->
                d.width += d3.event.dx
                d.height += d3.event.dy
                d3.select(@).attr("transform", (c) -> 
                    trans(c.x + c.width, c.y + c.height))
                that.svgGroup.selectAll("g.parent rect.parentrect")
                    .filter((c) -> c is d)
                    .attr("width", (c) -> c.width)
                    .attr("height", (c) -> c.height)
            )
            .on("dragend", (d) ->
                that.childupdate([d])
            )

        treegrid: () ->
            that = @
            grid = d3.layout.grid()
                .bands()
                .size([@root.width, @root.height])
            nodes = grid(@parents())
            nodes.forEach((d) ->
                d.width = d.width or Cluster.PARENT_WIDTH
                d.height = d.height or d.width
            )
            # orphan
            orphan = @orphan()
            orphan.width = Cluster.LIST_WIDTH
            orphan.height = @root.height
            orphan.x = @root.width + Cluster.LIST_MARGIN
            orphan.y = 0
            nodes.push(orphan)
            # children
            @root.children.forEach((d) ->
                if d.children
                    children = that.childgrid(d)
                    nodes = nodes.concat(children)
            )
            return nodes

        childgrid: (parent) ->
            cols = Math.max(1, Math.min(
                Math.floor((parent.width - 20) / (Cluster.CHILD_WIDTH * 8 + 20)),
                parent.children.length
            ))
            childgrid = d3.layout.grid()
                .bands()
                .cols(cols)
                .size([parent.width, parent.height])
                .padding([20, 20])
                .nodeSize([Cluster.CHILD_WIDTH * 8, Cluster.CHILD_WIDTH * 3])
            children = childgrid(parent.children)
            children.forEach((c) ->
                c.x += parent.x
                c.y += parent.y
                c.width = Cluster.CHILD_WIDTH * 8
                c.height = Cluster.CHILD_WIDTH * 3
                c.parent = parent
            )
            return children

        initlayout: () ->
            nodes = @treegrid()
            @update(nodes)

        childupdate: (parents) ->
            that = @
            nodes = @root.children
            @root.children.forEach((d) ->
                if parents.indexOf(d) > -1
                    children = that.childgrid(d)
                    nodes = nodes.concat(children)
                else
                    nodes = nodes.concat(d.children)
            )
            @update(nodes)

        justupdate: () ->
            that = @
            nodes = @root.children
            @root.children.forEach((d) ->
                nodes = nodes.concat(d.children)
            )
            @update(nodes)

        update: (data) ->
            that = @
            # Update the nodes…
            node = @svgGroup.selectAll("g.node")
                .data(data, (d) ->
                    return d.id or (d.id = that.index++)
                )

            # enter any new nodes at the parent's previous position.
            nodeenter = node.enter().append("g")
                .attr("class", "node")

            parentrects = nodeenter
                .filter((d) -> d.children)
                .attr('class', 'node parent')
                .append("rect")
                .attr('class', 'parentrect')
                .style("fill", "#fff")
                .style("opacity", "0.5")
                .attr("width", (d) -> d.width)
                .attr("height", (d) -> d.height)
                .attr("transform", (d) -> trans(d.x, d.y))
                .on("mouseover", (d) ->
                    if that.draggingNode
                        that.selectedNode = d
                )
                .on("mouseout", (d) ->
                    if that.draggingNode
                        that.selectedNode = null
                )
            # non orphans
            parentrects.filter((d) -> !d.orphan)
                .attr('pointer-events', 'mouseover')
                .call(@parentDragListener())
            # orphans
            parentrects.filter((d) -> d.orphan)
                .attr('class', 'node parent orphan')

            childgroups = nodeenter
                .filter((d) -> !d.children)
                .attr("class", "node child")
                .attr("transform", (d) -> trans(d.x, d.y))
                .attr('pointer-events', 'mouseover')
                .attr('title', (d) -> d.name)
                .call(@parentDragListener())
            nodeenter
                .filter((d) -> !d.children)
                .append("rect")
                .style("fill", "lightsteelblue")
                .style("opacity", "0.5")
                .attr("width", (d) -> d.width)
                .attr("height", (d) -> d.height)
            nodeenter
                .filter((d) -> !d.children)
                .append("text")
                .each((d) ->
                    d3.select(@).append("tspan")
                        .text((d) -> d.name)
                        .attr("x", 0)
                        .attr("dy", 10)
                    d3.select(@).append("tspan")
                        .text((d) -> d.name)
                        .attr("x", 0)
                        .attr("dy", 20)
                )


            # handle for resizing
            handles = nodeenter.filter((d) -> d.children)
                .append("rect")
                .attr('class', 'resizehandle')
                .style("fill", "black")
                .style("opacity", "0.5")
                .style("cursor", "nwse-resize")
                .attr('pointer-events', 'mouseover')
                .attr('width', 10)
                .attr('height', 10)
                .attr("transform", (d) -> trans(d.x + d.width, d.x + d.height))
                .call(@resizeDragListener())

            # Transition nodes to their new position.
            @svgGroup.selectAll("g.parent rect.parentrect")
                .attr("transform", (d) -> trans(d.x, d.y))
            @svgGroup.selectAll("g.child")
                .attr("transform", (d) -> trans(d.x, d.y))
            @svgGroup.selectAll("g.node rect.resizehandle")
                .attr("transform", (d) -> trans(d.x + d.width, d.y + d.height))

            # Transition exiting nodes to the parent's new position.
            node.exit().remove()

            @sort()

    d3.json("/projects/cluster_json", (error, treeData) ->

        targetDom = "#field"
        viewerWidth = $(targetDom).width()
        viewerHeight = viewerWidth

        new Cluster(targetDom, treeData, viewerWidth, viewerHeight)
    )
