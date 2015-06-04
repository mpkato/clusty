$ ->
    enable_drag()

enable_drag = ->
    $(".element").draggable(
        containment: "parent",
        stop: ->
            merge(@)
    )

dist = (x, y) ->
    return Math.sqrt(Math.pow(x.top - y.top, 2) + Math.pow(x.left - y.left, 2))

merge = (dragged) ->
    $(".element").each ->
        if dragged != @
            d = dist($(dragged).position(), $(@).position())
            if d < 100
                block = $(@).clone()
                block.find(".panel-body").html("")
                block.find(".panel-body").append(@)
                #block.find(".panel-body").append(dragged)
                console.log(block.find(".panel-body").html())
                $("#field").append(block)
                enable_drag()
