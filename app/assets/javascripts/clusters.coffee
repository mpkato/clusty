$ ->
    d3.selection.prototype.moveToFront = () ->
        return @each(() ->
            @parentNode.appendChild(@)
        )

    trans = (x, y) ->
        return "translate(#{x}, #{y})"

    wrap = (there, text, width) ->
        # const
        lineHeight = 1.0
        xoffset = 2
        yoffset = 0.1
        maxlinenum = 4

        words = text.split('').reverse()
        word = null
        line = []
        lineNumber = 0
        y = d3.select(there).attr("y")
        tspan = d3.select(there).append("tspan").attr("x", xoffset + "px")
            .attr("y", (++lineNumber * lineHeight + yoffset) + "em")
        while word = words.pop()
            line.push(word)
            tspan.text(line.join(""))
            if tspan.node().getComputedTextLength() > width - xoffset
                line.pop()
                tspan.text(line.join(""))
                if lineNumber >= maxlinenum
                    break
                line = [word]
                tspan = d3.select(there)
                    .append("tspan").attr("x", xoffset + "px")
                    .attr("y", (++lineNumber * lineHeight + yoffset) + "em")
                    .text(word)

    bestSize = (width, height, elemWidth, elemHeight, num) ->
        maxlen = Math.min(width, height)
        wcands = d3.range(1,
            Math.floor((width - Cluster.NODE_PADDING) / (elemWidth + Cluster.NODE_PADDING))
            ).map((d) -> d * (elemWidth + Cluster.NODE_PADDING))
        hcands = d3.range(1,
            Math.floor((height - Cluster.NODE_PADDING) / (elemHeight + Cluster.NODE_PADDING))
            ).map((d) -> d * (elemHeight + Cluster.NODE_PADDING))
        cands = wcands.concat(hcands).sort()
        currentbest = null
        cands.forEach((candsize) ->
            if candsize <= maxlen
                wnum = Math.floor((candsize - Cluster.NODE_PADDING) / (elemWidth + Cluster.NODE_PADDING))
                hnum = Math.floor((candsize - Cluster.NODE_PADDING) / (elemHeight + Cluster.NODE_PADDING))
                maxnum = wnum * hnum
                if maxnum >= num and currentbest is null
                    currentbest = candsize
        )
        if currentbest isnt null
            return currentbest
        else
            return cands[-1]

    class Cluster
        # constant
        @DURATION = 100
        @CHILD_WIDTH = 15
        @PARENT_WIDTH = 300
        @NODE_PADDING = 20
        @LIST_WIDTH = 200
        @LIST_MARGIN = 20

        constructor: (target, root, width, height) ->
            that = @
            @selectedNode = null
            @draggingNode = null
            @target = target
            @root = root
            @index = 1
            @color = d3.scale.category20()

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
                .on("contextmenu", d3.contextMenu(that.globalmenu()))

            @root.x = 0
            @root.y = 0
            @root.width = width - (Cluster.LIST_WIDTH + Cluster.LIST_MARGIN)
            @root.height = height
            @maxwidth = width - Cluster.CHILD_WIDTH * 8
            @maxheight = height - Cluster.CHILD_WIDTH * 3
            @initlayout()

        parents: () ->
            return @root.filter((d) -> d.id isnt null)

        orphan: () ->
            return @root.filter((d) -> d.id is null)[0]

        globalmenu: () ->
            that = @
            return [
                    {
                        title: 'Create Cluster',
                        action: (elm, d, i) ->
                            that.createParent(d, elm)
                    }
                ]

        localmenu: () ->
            that = @
            return [
                    {
                        title: 'Label Cluster',
                        action: (elm, d, i) ->
                            that.labelbox(d, elm)
                    },
                    {
                        title: (d) -> return if d.elements.length == 0 then 'Delete Cluster' else '',
                        action: (elm, d, i) ->
                            if d.elements.length == 0
                                that.destroyParent(d)
                    }
                ]

        createParent: (d, there) ->
            that = @
            xy = d3.mouse(there)
            data = {cluster:
                {project_id: $(that.target).data("id"), name: null}
                }
            d3.xhr($(that.target).data("url"))
                .header("Content-Type", "application/json")
                .header("X-CSRF-Token",
                    $('meta[name="csrf-token"]').attr('content'))
                .post(
                    JSON.stringify(data),
                    (err, data) ->
                        newParent = JSON.parse(data.response)
                        newParent.x = xy[0]
                        newParent.y = xy[1]
                        newParent.width = Cluster.PARENT_WIDTH
                        newParent.height = Cluster.PARENT_WIDTH
                        that.root.push(newParent)
                        that.justupdate()
                )

        destroyParent: (d) ->
            that = @
            d3.xhr($(that.target).data("url") + "/#{d.id}")
                .header("Content-Type", "application/json")
                .header("X-CSRF-Token",
                    $('meta[name="csrf-token"]').attr('content'))
                .send("DELETE",
                    (err, data) ->
                        that.justupdate()
                )

        toggleSize: (d) ->
            that = @
            parent = that.svgGroup.selectAll("g.parent") 
                .filter((c) -> d.id == c.id)
            if d.min is undefined
                that.svgGroup.selectAll("g.child")
                    .filter((c) -> d.id == c.parent.id)
                    .style("display", "none")
                parent.select("rect.resizehandle")
                    .style("display", "none")
                d.width0 = d.width
                d.height0 = d.height
                d.width = Cluster.CHILD_WIDTH * 8
                d.height = Cluster.CHILD_WIDTH * 8
                d.min = true
            else
                that.svgGroup.selectAll("g.child")
                    .filter((c) -> d.id == c.parent.id)
                    .style("display", "")
                parent.select("rect.resizehandle")
                    .style("display", "")
                d.width = d.width0
                d.height = d.height0
                delete d.width0
                delete d.height0
                delete d.min
            parent.select("rect.parentrect")
                .attr("width", (c) -> c.width)
                .attr("height", (c) -> c.height)
                .style("fill", if d.min is undefined then "#fff" else that.color(d.id))
            parent.select("rect.resizehandle")
                .attr("transform", (c) -> trans(c.x + c.width, c.y + c.height))
            parent.select("text.clustername")
                .attr("transform", (c) -> trans(c.x + c.width / 2, c.y + c.height / 2))

        labelbox: (d, there) ->
            that = @
            obj = that.svgGroup.append("g")
            obj.append("foreignObject")
                .attr("width", d.width)
                .attr("height", 50)
                .attr("transform", trans(d.x, d.y))
                .moveToFront()
                .append("xhtml:div")
                .html("""
                    <input type='text' id='labeltext' 
                    placeholder='Input label of this cluster ...'
                    style='width: 100%' onblur="$(this).closest('g').remove()"></input>""")
                .on("focusout", (c) ->
                    console.log(c)
                    try
                        obj.remove()
                    catch
                        #
                )
                .on("change", (c) ->
                    that.updateName(d, $("#labeltext").val(), there)
                    try
                        obj.remove()
                    catch
                        #
                )
            if d.name isnt null
                $("#labeltext").val(d.name)

            $("#labeltext").focus()

        updateName: (d, name, there) ->
            data = {cluster: {method: "update", name: name}}
            d3.xhr($(@target).data("url") + "/#{d.id}")
                .header("Content-Type", "application/json")
                .header("X-CSRF-Token",
                    $('meta[name="csrf-token"]').attr('content'))
                .send("PUT",
                    JSON.stringify(data),
                    (err, data) ->
                        if (err)
                            console.warn(err)
                            return
                        d.name = JSON.parse(data.response).name
                        d3.select(there.parentNode).select("text.clustername")
                            .text(d.name)
                )

        updateParent: (draggingNode, selectedNode) ->
            that = @
            element_id = draggingNode.id
            from_id = draggingNode.parent.id or -1
            to_id = selectedNode.id or -1
            that.updateElement(element_id, from_id, "destroy", (err, data) ->
                that.updateElement(element_id, to_id, "create", (err, data) ->
                    that.childupdate([draggingNode.parent.id, selectedNode.id])
                )
            )

        updateElement: (element_id, parent_id, method, callback) ->
            data = {cluster: {method: method, element_id: element_id}}
            d3.xhr($(@target).data("url") + "/#{parent_id}")
                .header("Content-Type", "application/json")
                .header("X-CSRF-Token",
                    $('meta[name="csrf-token"]').attr('content'))
                .send("PUT",
                    JSON.stringify(data),
                    (err, data) ->
                        if (err)
                            console.warn(err)
                            return
                        callback(err, data)
                )


        # Define the drag listeners for drag/drop behaviour of nodes.
        parentDragListener: ->
            that = @
            return d3.behavior.drag()
            .on("dragstart", (d) ->
                d.x0 = d.x
                d.y0 = d.y
                d3.event.sourceEvent.stopPropagation()
                if !d.elements
                    that.draggingNode = d
                    that.sort()
                else
                    that.svgGroup.selectAll("g.child")
                        .filter((c) -> d.id == c.parent.id)
                        .each((c) ->
                            c.x0 = c.x
                            c.y0 = c.y
                        )
            )
            .on("drag", (d) ->
                dx = d3.event.dx
                dy = d3.event.dy
                if d.x0 + dx < 0
                    dx = -d.x0
                if d.y0 + dy < 0
                    dy = -d.y0
                if d.x0 + dx > that.maxwidth
                    dx = that.maxwidth - d.x0
                if d.y0 + dy > that.maxheight
                    dy = that.maxheight - d.y0
                d.x0 += dx
                d.y0 += dy

                d3.select(@)
                    .attr("transform", (c) -> trans(c.x0, c.y0))
                that.svgGroup.selectAll("g.node rect.resizehandle")
                    .filter((c) -> c is d)
                    .attr("transform", (c) -> trans(c.x0 + c.width, c.y0 + c.height))
                that.svgGroup.selectAll("g.node text.clustername")
                    .filter((c) -> c is d)
                    .attr("transform", (c) -> trans(c.x0 + c.width / 2, c.y0 + c.height / 2))

                if d.elements
                    that.svgGroup.selectAll("g.child")
                        .filter((c) -> d.id == c.parent.id)
                        .each((c) ->
                            c.x0 += dx
                            c.y0 += dy
                        )
                        .attr("transform", (c) -> trans(c.x0, c.y0))

            ).on("dragend", (d) ->
                if that.selectedNode and that.selectedNode isnt that.draggingNode.parent
                    that.updateParent(that.draggingNode, that.selectedNode)
                    that.selectedNode = null
                else
                    if d.elements
                        d.x = d.x0
                        d.y = d.y0
                        that.svgGroup.selectAll("g.child")
                            .filter((c) -> d.id == c.parent.id)
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
            @svgGroup.selectAll("g.node").sort((a, b) ->
                if a is that.draggingNode
                    return -1
                else if b is that.draggingNode
                    return 1
                else if a.elements
                    return -1
                else if b.elements
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
                if d.min # minimized
                    return
                d.width += d3.event.dx
                d.height += d3.event.dy
                if d.width < Cluster.CHILD_WIDTH * 8
                    d.width = Cluster.CHILD_WIDTH * 8
                if d.height < Cluster.CHILD_WIDTH * 8
                    d.height = Cluster.CHILD_WIDTH * 8
                d3.select(@).attr("transform", (c) ->
                    trans(c.x + c.width, c.y + c.height))
                that.svgGroup.selectAll("g.parent rect.parentrect")
                    .filter((c) -> c.id == d.id)
                    .attr("width", (c) -> c.width)
                    .attr("height", (c) -> c.height)
                that.svgGroup.selectAll("text.clustername")
                    .filter((c) -> c.id == d.id)
                    .attr("transform", (c) -> trans(c.x + c.width / 2, c.y + c.height / 2))
            )
            .on("dragend", (d) ->
                if d.min # minimized
                    return
                that.simplechildupdate([d.id])
            )

        treegrid: () ->
            that = @
            cols = Math.max(1, Math.min(
                Math.floor((@root.width - Cluster.NODE_PADDING)\
                    / (Cluster.CHILD_WIDTH * 8 + Cluster.NODE_PADDING)),
                @parents().length
            ))
            grid = d3.layout.grid()
                .bands()
                .size([@root.width, @root.height])
                .padding([Cluster.NODE_PADDING, Cluster.NODE_PADDING])
                .nodeSize([Cluster.CHILD_WIDTH * 8, Cluster.CHILD_WIDTH * 8])
                .cols(cols)
            nodes = grid(@parents())
            nodes.forEach((d) ->
                size = bestSize(that.root.width, that.root.height,
                    Cluster.CHILD_WIDTH * 8, Cluster.CHILD_WIDTH * 3, d.elements.length)
                d.width = size
                d.height = size
            )
            # orphan
            orphan = @orphan()
            orphan.width = Cluster.LIST_WIDTH
            orphan.height = @root.height
            orphan.x = @root.width + Cluster.LIST_MARGIN
            orphan.y = 0
            nodes.push(orphan)
            # children
            @root.forEach((d) ->
                if d.elements
                    elements = that.childgrid(d)
                    nodes = nodes.concat(elements)
            )
            return nodes

        childgrid: (parent) ->
            cols = Math.max(1, Math.min(
                Math.floor((parent.width - Cluster.NODE_PADDING)\
                    / (Cluster.CHILD_WIDTH * 8 + Cluster.NODE_PADDING)),
                parent.elements.length
            ))
            childgrid = d3.layout.grid()
                .bands()
                .cols(cols)
                .size([parent.width, parent.height])
                .padding([Cluster.NODE_PADDING, Cluster.NODE_PADDING])
                .nodeSize([Cluster.CHILD_WIDTH * 8, Cluster.CHILD_WIDTH * 3])
            elements = childgrid(parent.elements)
            elements.forEach((c) ->
                c.x += parent.x
                c.y += parent.y
                c.width = Cluster.CHILD_WIDTH * 8
                c.height = Cluster.CHILD_WIDTH * 3
                c.parent = parent
            )
            return elements

        initlayout: () ->
            that = @
            nodes = @treegrid()
            @update(nodes)
            @svgGroup.selectAll('g.parent')
                .each((d) ->
                    that.toggleSize(d)
                )

        childupdate: (parent_ids) ->
            that = @
            d3.json($(@target).data("url"), (error, newdata) ->
                if (error)
                    console.warn(error)
                    return
                else
                    that.syncstruct(newdata)
                    nodes = []
                    that.root.forEach((d) ->
                        nodes.push(d)
                        elements = if parent_ids.indexOf(d.id) > -1 then that.childgrid(d) else d.elements
                        nodes = nodes.concat(elements)
                    )
                    that.update(nodes)
            )

        simplechildupdate: (parent_ids) ->
            that = @
            nodes = []
            that.root.forEach((d) ->
                nodes.push(d)
                elements = if parent_ids.indexOf(d.id) > -1 then that.childgrid(d) else d.elements
                nodes = nodes.concat(elements)
            )
            that.update(nodes)

        justupdate: () ->
            that = @
            d3.json($(@target).data("url"), (error, newdata) ->
                if (error)
                    console.warn(error)
                    return
                else
                    that.syncstruct(newdata)
                    nodes = []
                    that.root.forEach((d) ->
                        nodes.push(d)
                        nodes = nodes.concat(d.elements)
                    )
                    that.update(nodes)
            )

        syncstruct: (treedata) ->
            that = @
            dict = {}
            @root.map((d) -> dict[d.id] = d)
            # parents
            @sync(@root, treedata)
            # children
            treedata.forEach((d) ->
                that.sync(dict[d.id].elements, d.elements)
            )

        # change x according to y
        sync: (x, y) ->
            # add missing parents
            dict = {}
            x.map((d) -> dict[d.id] = d)
            y.forEach((d) ->
                if dict[d.id] isnt undefined
                    delete dict[d.id]
                else
                    x.push(d)
            )
            # delete redundant parents
            x.forEach((d) ->
                if dict[d.id] isnt undefined
                    index = x.indexOf(d)
                    if index > -1
                        x.splice(index, 1)
            )

        update: (data) ->
            that = @
            # Update the nodes…
            node = @svgGroup.selectAll("g.node")
                .data(data, (d) ->
                    if d.id is null
                        return null
                    else
                        if d.elements
                            return "C#{d.id}"
                        else
                            return "E#{d.id}"
                )

            # enter any new nodes at the parent's previous position.
            nodeenter = node.enter().append("g")
                .attr("class", "node")

            parentrects = nodeenter
                .filter((d) -> d.elements)
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
            parentrects.filter((d) -> d.id isnt null)
                .attr('pointer-events', 'mouseover')
                .on("contextmenu", d3.contextMenu(that.localmenu(), (d) ->
                    if d.min isnt undefined
                        that.toggleSize(d)
                        d3.event.preventDefault()
                        return false
                ))
                .call(@parentDragListener())
            # orphans
            parentrects.filter((d) -> d.id is null)
                .attr('class', 'node parent orphan')

            childgroups = nodeenter
                .filter((d) -> !d.elements)
                .attr("class", "node child")
                .attr("transform", (d) -> trans(d.x, d.y))
                .attr('pointer-events', 'mouseover')
                .attr('title', (d) -> d.body)
                .call(@parentDragListener())
            nodeenter
                .filter((d) -> !d.elements)
                .append("rect")
                .style("fill", "lightsteelblue")
                .style("opacity", "0.5")
                .attr("width", (d) -> d.width)
                .attr("height", (d) -> d.height)
            nodeenter
                .filter((d) -> !d.elements)
                .append("text")
                .each((d) ->
                    wrap(@, d.body, d.width, d.height)
                )

            # handle for resizing
            handles = nodeenter.filter((d) -> d.elements)
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
                .on("contextmenu", (d) ->
                    that.toggleSize(d)
                    d3.event.preventDefault()
                )

            # Cluster names
            nodeenter.filter((d) -> d.elements)
                .append("text")
                .attr("class", "clustername")
                .text((d) -> d.name)
                .style("opacity", "0.5")
                .style("text-anchor", "middle")
                .style("font-size", "20pt")
                .attr("transform", (d) -> trans(d.x + d.width / 2, d.y + d.height / 2))

            # Transition nodes to their new position.
            @svgGroup.selectAll("g.parent rect.parentrect")
                .attr("transform", (d) -> trans(d.x, d.y))
            @svgGroup.selectAll("g.child")
                .attr("transform", (d) -> trans(d.x, d.y))
            @svgGroup.selectAll("g.child")
                .filter((d) -> d.parent.min isnt undefined)
                .style("display", "none")
            @svgGroup.selectAll("g.child")
                .filter((d) -> d.parent.min is undefined)
                .style("display", "")
            @svgGroup.selectAll("g.node rect.resizehandle")
                .attr("transform", (d) -> trans(d.x + d.width, d.y + d.height))

            # Transition exiting nodes to the parent's new position.
            node.exit().remove()

            @sort()

    targetDom = "#field"
    viewerWidth = $(targetDom).width()
    viewerHeight = viewerWidth
    d3.json($(targetDom).data("url"), (error, treeData) ->
        new Cluster(targetDom, treeData, viewerWidth, viewerHeight)
    )
