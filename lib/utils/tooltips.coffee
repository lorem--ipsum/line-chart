      getTooltipHandlers: (options) ->
        if options.tooltipMode is 'scrubber'
          return {
            onChartHover: angular.bind(this, this.showScrubber)
          }
        else
          return {
            onMouseOver: angular.bind(this, this.onMouseOver)
            onMouseOut: angular.bind(this, this.onMouseOut)
          }

      showScrubber: (svg, glass, axes, data) ->
        that = this
        glass.on('mousemove', ->
          svg.selectAll('.glass-container').attr('opacity', 1)
          that.updateScrubber(svg, d3.mouse(this), axes, data)
        )
        glass.on('mouseout', ->
          glass.on('mousemove', null)
          svg.selectAll('.glass-container').attr('opacity', 0)
        )

      updateScrubber: (svg, [x, y], axes, data) ->
        # Dichotomy FTW
        getClosest = (values, value) ->
          left = 0
          right = values.length - 1

          i = Math.round((right - left)/2)
          while true
            if value < values[i].x
              right = i
              i = i - Math.ceil((right-left)/2)
            else
              left = i
              i = i + Math.floor((right-left)/2)


            if i in [left, right]
              if Math.abs(value - values[left].x) < Math.abs(value - values[right].x)
                i = left
              else
                i = right
              break

          return values[i]

        that = this
        data.forEach (series, index) ->
          v = getClosest(series.values, axes.xScale.invert(x))

          item = svg.select(".scrubberItem.series_#{index}")
          item.transition().duration(50)
            .attr('transform': "translate(#{axes.xScale(v.x)}, #{axes[v.axis + 'Scale'](v.value)})")

          item.select('text').text(v.value)

          item.select('path')
            .attr('d', (s) ->
              if s.axis is 'y2'
                return that.getY2TooltipPath(that.getTextWidth('' + v.value))
              else
                return that.getYTooltipPath(that.getTextWidth('' + v.value))
            )


      addTooltips: (svg, dimensions, axesOptions) ->
        width = dimensions.width
        height = dimensions.height

        width = width - dimensions.left - dimensions.right
        height = height - dimensions.top - dimensions.bottom

        w = 24
        h = 18
        p = 5

        xTooltip = svg.append('g')
          .attr(
            'id': 'xTooltip'
            'class': 'xTooltip'
            'opacity': 0
          )

        xTooltip.append('path')
          .attr('transform', "translate(0,#{(height + 1)})")

        xTooltip.append('text')
          .style('text-anchor', 'middle')
          .attr(
            'width': w
            'height': h
            'font-family': 'monospace'
            'font-size': 10
            'transform': 'translate(0,' + (height + 19) + ')'
            'fill': 'white'
            'text-rendering': 'geometric-precision'
          )

        yTooltip = svg.append('g')
          .attr(
            id: 'yTooltip'
            class: 'yTooltip'
            opacity: 0
          )

        yTooltip.append('path')
        yTooltip.append('text')
          .attr(
            'width': h
            'height': w
            'font-family': 'monospace'
            'font-size': 10
            'fill': 'white'
            'text-rendering': 'geometric-precision'
          )

        if axesOptions.y2?
          y2Tooltip = svg.append('g')
            .attr(
              'id': 'y2Tooltip'
              'class': 'y2Tooltip'
              'opacity': 0
              'transform': 'translate(' + width + ',0)'
            )

          y2Tooltip.append('path')

          y2Tooltip.append('text')
            .attr(
              'width': h
              'height': w
              'font-family': 'monospace'
              'font-size': 10
              'fill': 'white'
              'text-rendering': 'geometric-precision'
            )

      onMouseOver: (svg, event) ->
        this.updateXTooltip(svg, event)

        if event.series.axis is 'y2'
          this.updateY2Tooltip(svg, event)
        else
          this.updateYTooltip(svg, event)

      onMouseOut: (svg) ->
        this.hideTooltips(svg)

      updateXTooltip: (svg, event) ->
        xTooltip = svg.select("#xTooltip")
          .transition()
          .attr(
            'opacity': 1.0
            'transform': 'translate(' + event.x + ',0)'
          )

        textX = undefined
        if event.series.xFormatter?
          textX = '' + event.series.xFormatter(event.datum.x)
        else
          textX = '' + event.datum.x

        xTooltip.select('text').text(textX)
        xTooltip.select('path')
          .attr('fill', event.series.color)
          .attr('d', this.getXTooltipPath(textX))

      getXTooltipPath: (text) ->
        w = this.getTextWidth(text)
        h = 18
        p = 5 # Size of the 'arrow' that points towards the axis

        return 'm-' + w/2 + ' ' + p + ' ' +
          'l0 ' + h + ' ' +
          'l' + w + ' 0 ' +
          'l0 ' + '-' + h +
          'l-' + (w/2 - p) + ' 0 ' +
          'l-' + p + ' -' + h/4 + ' ' +
          'l-' + p + ' ' + h/4 + ' ' +
          'l-' + (w/2 - p) + ' 0z'

      updateYTooltip: (svg, event) ->
        yTooltip = svg.select("#yTooltip")
          .transition()
          .attr(
            'opacity': 1.0
            'transform': 'translate(0, ' + event.y + ')'
          )

        textY = '' + event.datum.value
        w = this.getTextWidth(textY)
        yTooltipText = yTooltip.select('text').text(textY)

        yTooltipText.attr(
          'transform': 'translate(' + (- w - 2) + ',3)'
          'width': w
        )

        yTooltip.select('path')
          .attr('fill', event.series.color)
          .attr('d', this.getYTooltipPath(w))

      getYTooltipPath: (w) ->
        h = 18
        p = 5 # Size of the 'arrow' that points towards the axis

        return 'm0 0' +
          'l-' + p + ' -' + p + ' ' +
          'l0 -' + (h/2 - p) + ' ' +
          'l-' + w + ' 0 ' +
          'l0 ' + h + ' ' +
          'l' + w + ' 0 ' +
          'l0 -' + (h/2 - p) +
          'l-' + p + ' ' + p + 'z'

      updateY2Tooltip: (svg, event) ->
        y2Tooltip = svg.select("#y2Tooltip")
          .transition()
          .attr('opacity', 1.0)

        textY = '' + event.datum.value
        w = this.getTextWidth(textY)
        y2TooltipText = y2Tooltip.select('text').text(textY)
        y2TooltipText.attr(
          'transform': 'translate(7, ' + (parseFloat(event.y) + 3) + ')'
          'w': w
        )

        y2Tooltip.select('path')
          .attr(
            'fill': event.series.color
            'd': this.getY2TooltipPath(w)
            'transform': 'translate(0, ' + event.y + ')'
          )

      getY2TooltipPath: (w) ->
        h = 18
        p = 5 # Size of the 'arrow' that points towards the axis

        return 'm0 0' +
          'l' + p + ' ' + p + ' ' +
          'l0 ' + (h/2 - p) + ' ' +
          'l' + w + ' 0 ' +
          'l0 -' + h + ' ' +
          'l-' + w + ' 0 ' +
          'l0 ' + (h/2 - p) + ' ' +
          'l-' + p + ' ' + p + 'z'

      hideTooltips: (svg) ->
        svg.select("#xTooltip")
          .transition()
          .attr('opacity', 0)

        svg.select("#yTooltip")
          .transition()
          .attr('opacity', 0)

        svg.select("#y2Tooltip")
          .transition()
          .attr('opacity', 0)
