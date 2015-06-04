$ -> 
    d3.json("/projects/cluster_json", (error, treeData) ->
        # Calculate total nodes, max label length
        totalNodes = 0
        maxLabelLength = 0
        # variables for drag/drop
        selectedNode = null
        draggingNode = null
        # panning variables
        panSpeed = 200
        panBoundary = 20 # Within 20px from edges will pan when dragging.
        # Misc. variables
        i = 0
        duration = 750
        root = null

        # added by kato
        domNode = null
        nodes = null
        dragStarted = null
        targetDom = "#field"
    
        # size of the diagram
        viewerWidth = $(targetDom).width()
        viewerHeight = viewerWidth
    
        tree = d3.layout.tree()
            .size([viewerHeight, viewerWidth])
    
        # define a d3 diagonal projection for use by the node paths later on.
        diagonal = d3.svg.diagonal()
            .projection((d) ->
                return [d.y, d.x]
            )
    
        # A recursive helper function for performing some setup by walking through all nodes
    
        visit = (parent, visitFn, childrenFn) ->
            if !parent 
                return
    
            visitFn(parent)
    
            children = childrenFn(parent)
            if children
                for child, i in children
                    visit(child, visitFn, childrenFn)
    
        # Call visit function to establish maxLabelLength
        visit(treeData, 
            (d) ->
                totalNodes++
                maxLabelLength = Math.max(d.name.length, maxLabelLength)
            (d) ->
                return if d.children and d.children.length > 0 then d.children else null
        )
    
    
        # sort the tree according to the node names
    
        sortTree = -> 
            tree.sort((a, b) ->
                return if b.name.toLowerCase() < a.name.toLowerCase() then 1 else -1
            )
        # Sort the tree initially incase the JSON isn't in a sorted order.
        sortTree()
    
        # TODO: Pan function, can be better implemented.
    
        pan = (domNode, direction) ->
            speed = panSpeed
            if panTimer
                clearTimeout(panTimer)
                translateCoords = d3.transform(svgGroup.attr("transform"))
                if direction == 'left' or direction == 'right'
                    translateX = if direction == 'left' then translateCoords.translate[0] + speed else translateCoords.translate[0] - speed
                    translateY = translateCoords.translate[1]
                else if direction == 'up' or direction == 'down'
                    translateX = translateCoords.translate[0]
                    translateY = if direction == 'up' then translateCoords.translate[1] + speed else translateCoords.translate[1] - speed
                
                scaleX = translateCoords.scale[0]
                scaleY = translateCoords.scale[1]
                scale = zoomListener.scale()
                svgGroup.transition().attr("transform", "translate(" + translateX + "," + translateY + ")scale(" + scale + ")")
                d3.select(domNode).select('g.node').attr("transform", "translate(" + translateX + "," + translateY + ")")
                zoomListener.scale(zoomListener.scale())
                zoomListener.translate([translateX, translateY])
                panTimer = setTimeout( ->
                    pan(domNode, speed, direction)
                50)
    
        # Define the zoom function for the zoomable tree
    
        zoom = -> 
            svgGroup.attr("transform", "translate(" + d3.event.translate + ")scale(" + d3.event.scale + ")")
    
    
        # define the zoomListener which calls the zoom function on the "zoom" event constrained within the scaleExtents
        zoomListener = d3.behavior.zoom().scaleExtent([0.1, 3]).on("zoom", zoom)
    
        initiateDrag = (d, domNode) ->
            draggingNode = d
            d3.select(domNode).select('.ghostCircle').attr('pointer-events', 'none')
            d3.selectAll('.ghostCircle').attr('class', 'ghostCircle show')
            d3.select(domNode).attr('class', 'node activeDrag')
    
            svgGroup.selectAll("g.node").sort((a, b) -> # select the parent and sort the path's
                if a.id != draggingNode.id
                    return 1 # a is not the hovered element, send "a" to the back
                else
                    return -1 # a is the hovered element, bring "a" to the front
            )
            # if nodes has children, remove the links and nodes
            if nodes.length > 1 
                # remove link paths
                links = tree.links(nodes)
                nodePaths = svgGroup.selectAll("path.link")
                    .data(links, (d) ->
                        return d.target.id
                    ).remove()
                # remove child nodes
                nodesExit = svgGroup.selectAll("g.node")
                    .data(nodes, (d) ->
                        return d.id
                    ).filter((d, i) ->
                        if d.id == draggingNode.id
                            return false
                        return true
                    ).remove()
    
            # remove parent link
            parentLink = tree.links(tree.nodes(draggingNode.parent))
            svgGroup.selectAll('path.link').filter((d, i) ->
                if d.target.id == draggingNode.id
                    return true
                return false
            ).remove()
    
            dragStarted = null
    
        # define the baseSvg, attaching a class for styling and the zoomListener
        baseSvg = d3.select(targetDom).append("svg")
            .attr("width", viewerWidth)
            .attr("height", viewerHeight)
            .attr("class", "overlay")
            #.call(zoomListener)
    
        # Define the drag listeners for drag/drop behaviour of nodes.
        dragListener = d3.behavior.drag()
            .on("dragstart", (d) ->
                if d == root
                    return
                dragStarted = true
                nodes = tree.nodes(d)
                d3.event.sourceEvent.stopPropagation()
                # it's important that we suppress the mouseover event on the node being dragged. Otherwise it will absorb the mouseover event and the underlying node will not detect it d3.select(this).attr('pointer-events', 'none')
            )
            .on("drag", (d) ->
                if d == root 
                    return
                if dragStarted
                    domNode = this
                    initiateDrag(d, domNode)
    
                # get coords of mouseEvent relative to svg container to allow for panning
                relCoords = d3.mouse($('svg').get(0))
                if relCoords[0] < panBoundary
                    panTimer = true
                    pan(this, 'left')
                else if relCoords[0] > ($('svg').width() - panBoundary)
                    panTimer = true
                    pan(this, 'right')
                else if relCoords[1] < panBoundary
                    panTimer = true
                    pan(this, 'up')
                else if relCoords[1] > ($('svg').height() - panBoundary)
                    panTimer = true
                    pan(this, 'down')
                else
                    try
                        clearTimeout(panTimer)
                    catch e
                        pass

                d.x0 += d3.event.dy
                d.y0 += d3.event.dx
                node = d3.select(this)
                node.attr("transform", "translate(" + d.y0 + "," + d.x0 + ")")
                updateTempConnector()
            ).on("dragend", (d) ->
                if d == root
                    return
                domNode = this
                if selectedNode
                    # now remove the element from the parent, and insert it into the new elements children
                    index = draggingNode.parent.children.indexOf(draggingNode)
                    if index > -1
                        draggingNode.parent.children.splice(index, 1)
                    if typeof selectedNode.children isnt 'undefined' or typeof selectedNode._children isnt 'undefined'
                        if typeof selectedNode.children isnt 'undefined'
                            selectedNode.children.push(draggingNode)
                        else
                            selectedNode._children.push(draggingNode)
                    else
                        selectedNode.children = []
                        selectedNode.children.push(draggingNode)
                    # Make sure that the node being added to is expanded so user can see added node is correctly moved
                    expand(selectedNode)
                    sortTree()
                    endDrag()
                else
                    endDrag()
            )
    
        endDrag = -> 
            selectedNode = null
            d3.selectAll('.ghostCircle').attr('class', 'ghostCircle')
            d3.select(domNode).attr('class', 'node')
            # now restore the mouseover event or we won't be able to drag a 2nd time
            d3.select(domNode).select('.ghostCircle').attr('pointer-events', '')
            updateTempConnector()
            if draggingNode isnt null
                update(root)
                # disabled by kato
                #centerNode(draggingNode)
                draggingNode = null
    
        # Helper functions for collapsing and expanding nodes.
        collapse = (d) ->
            if d.children
                d._children = d.children
                d._children.forEach(collapse)
                d.children = null
    
        expand = (d) ->
            if d._children
                d.children = d._children
                d.children.forEach(expand)
                d._children = null
   
        overCircle = (d) ->
            selectedNode = d
            updateTempConnector()
        outCircle = (d) ->
            selectedNode = null
            updateTempConnector()
    
        # Function to update the temporary connector indicating dragging affiliation
        updateTempConnector = () ->
            data = []
            if draggingNode isnt null and selectedNode isnt null
                # have to flip the source coordinates since we did this for the existing connectors on the original tree
                data = [{
                    source: {
                        x: selectedNode.y0,
                        y: selectedNode.x0
                    },
                    target: {
                        x: draggingNode.y0,
                        y: draggingNode.x0
                    }
                }]
            link = svgGroup.selectAll(".templink").data(data)
            link.enter().append("path")
                .attr("class", "templink")
                .attr("d", d3.svg.diagonal())
                .attr('pointer-events', 'none')
            link.attr("d", d3.svg.diagonal())
            link.exit().remove()
    
        # Function to center node when clicked/dropped so node doesn't get lost when collapsing/moving with large amount of children.
        centerNode = (source) ->
            scale = zoomListener.scale()
            x = -source.y0
            y = -source.x0
            x = x * scale + viewerWidth / 2
            y = y * scale + viewerHeight / 2
            d3.select('g').transition()
                .duration(duration)
                .attr("transform", "translate(" + x + "," + y + ")scale(" + scale + ")")
            zoomListener.scale(scale)
            zoomListener.translate([x, y])
    
        # Toggle children function
        toggleChildren = (d) ->
            if d.children
                d._children = d.children
                d.children = null
            else if d._children
                d.children = d._children
                d._children = null
            return d
    
        # Toggle children on click.
        click = (d) ->
            if d3.event.defaultPrevented 
                return # click suppressed
            d = toggleChildren(d)
            update(d)
            #centerNode(d)
    
        update = (source) ->
            # Compute the new height, function counts total children of root node and sets tree height accordingly.
            # This prevents the layout looking squashed when new nodes are made visible or looking sparse when nodes are removed
            # This makes the layout more consistent.
            levelWidth = [1]
            childCount = (level, n) ->
                if n.children and n.children.length > 0
                    if levelWidth.length <= level + 1
                        levelWidth.push(0)
                    levelWidth[level + 1] += n.children.length
                    n.children.forEach((d) ->
                        childCount(level + 1, d)
                    )
            childCount(0, root)
            newHeight = d3.max(levelWidth) * 25 # 25 pixels per line  
            tree = tree.size([newHeight, viewerWidth])
    
            # Compute the new tree layout.
            nodes = tree.nodes(root).reverse()
            links = tree.links(nodes)
    
            # Set widths between levels based on maxLabelLength.
            nodes.forEach((d) ->
                d.y = (d.depth * (maxLabelLength * 10)) #maxLabelLength * 10px
                # alternatively to keep a fixed scale one can set a fixed depth per level
                # Normalize for fixed-depth by commenting out below line
                # d.y = (d.depth * 500) #500px per level.
            )
    
            # Update the nodes…
            node = svgGroup.selectAll("g.node")
                .data(nodes, (d) ->
                    return d.id or (d.id = ++i)
                )
    
            # Enter any new nodes at the parent's previous position.
            nodeEnter = node.enter().append("g")
                .call(dragListener)
                .attr("class", "node")
                .attr("transform", (d) ->
                    return "translate(" + source.y0 + "," + source.x0 + ")"
                )
                .on('click', click)
    
            nodeEnter.append("circle")
                .attr('class', 'nodeCircle')
                .attr("r", 0)
                .style("fill", (d) ->
                    return if d._children then "lightsteelblue" else "#fff"
                )
    
            nodeEnter.append("text")
                .attr("x", (d) ->
                    return if d.children or d._children then -10 else 10
                )
                .attr("dy", ".35em")
                .attr('class', 'nodeText')
                .attr("text-anchor", (d) ->
                    return if d.children or d._children then "end" else "start"
                )
                .text((d) ->
                    return d.name
                )
                .style("fill-opacity", 0)
    
            # phantom node to give us mouseover in a radius around it
            nodeEnter.append("circle")
                .attr('class', 'ghostCircle')
                .attr("r", 30)
                .attr("opacity", 0.2) # change this to zero to hide the target area
                .style("fill", "red")
                .attr('pointer-events', 'mouseover')
                .on("mouseover", (node) ->
                    overCircle(node)
                )
                .on("mouseout", (node) ->
                    outCircle(node)
                )
    
            # Update the text to reflect whether node has children or not.
            node.select('text')
                .attr("x", (d) ->
                    return if d.children or d._children then -10 else 10
                )
                .attr("text-anchor", (d) ->
                    return if d.children or d._children then "end" else "start"
                )
                .text((d) ->
                    return d.name
                )
    
            # Change the circle fill depending on whether it has children and is collapsed
            node.select("circle.nodeCircle")
                .attr("r", 4.5)
                .style("fill", (d) ->
                    return if d._children then "lightsteelblue" else "#fff"
                )
    
            # Transition nodes to their new position.
            nodeUpdate = node.transition()
                .duration(duration)
                .attr("transform", (d) ->
                    return "translate(" + d.y + "," + d.x + ")"
                )
    
            # Fade the text in
            nodeUpdate.select("text")
                .style("fill-opacity", 1)
    
            # Transition exiting nodes to the parent's new position.
            nodeExit = node.exit().transition()
                .duration(duration)
                .attr("transform", (d) ->
                    return "translate(" + source.y + "," + source.x + ")"
                )
                .remove()
    
            nodeExit.select("circle")
                .attr("r", 0)
    
            nodeExit.select("text")
                .style("fill-opacity", 0)
    
            # Update the links…
            link = svgGroup.selectAll("path.link")
                .data(links, (d) ->
                    return d.target.id
                )
    
            # Enter any new links at the parent's previous position.
            link.enter().insert("path", "g")
                .attr("class", "link")
                .attr("d", (d) ->
                    o = {
                        x: source.x0,
                        y: source.y0
                    }
                    return diagonal({
                        source: o,
                        target: o
                    })
                )
    
            # Transition links to their new position.
            link.transition()
                .duration(duration)
                .attr("d", diagonal)
    
            # Transition exiting nodes to the parent's new position.
            link.exit().transition()
                .duration(duration)
                .attr("d", (d) ->
                    o = {
                        x: source.x,
                        y: source.y
                    }
                    return diagonal({
                        source: o,
                        target: o
                    })
                )
                .remove()
    
            # Stash the old positions for transition.
            nodes.forEach((d) ->
                d.x0 = d.x
                d.y0 = d.y
            )
    
        # Append a group which holds all nodes and which the zoom Listener can act upon.
        svgGroup = baseSvg.append("g")
    
        # Define the root
        root = treeData
        root.x0 = 0
        root.y0 = 0
    
        # Layout the tree initially and center on the root node.
        update(root)
        #centerNode(root)
    )
