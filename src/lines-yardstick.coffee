TokenIterator = require './token-iterator'
AcceptFilter = {acceptNode: -> NodeFilter.FILTER_ACCEPT}
{Point} = require 'text-buffer'

module.exports =
class LinesYardstick
  constructor: (@model, @lineNodesProvider) ->
    @tokenIterator = new TokenIterator
    @rangeForMeasurement = document.createRange()

  pixelPositionForScreenPosition: (screenPosition, clip=true) ->
    screenPosition = Point.fromObject(screenPosition)
    screenPosition = @model.clipScreenPosition(screenPosition) if clip

    targetRow = screenPosition.row
    targetColumn = screenPosition.column
    baseCharacterWidth = @baseCharacterWidth

    top = targetRow * @model.getLineHeightInPixels()
    left = @leftPixelPositionForScreenPosition(targetRow, targetColumn)

    {top, left}

  leftPixelPositionForScreenPosition: (row, column) ->
    lineNode = @lineNodesProvider.lineNodeForScreenRow(row)

    tokenizedLine = @model.tokenizedLineForScreenRow(row)
    iterator = document.createNodeIterator(lineNode, NodeFilter.SHOW_TEXT, AcceptFilter)
    charIndex = 0

    @tokenIterator.reset(tokenizedLine)
    while @tokenIterator.next()
      text = @tokenIterator.getText()

      textIndex = 0
      while textIndex < text.length
        if @tokenIterator.isPairedCharacter()
          char = text
          charLength = 2
          textIndex += 2
        else
          char = text[textIndex]
          charLength = 1
          textIndex++

        continue if char is '\0'

        unless textNode?
          textNode = iterator.nextNode()
          textNodeLength = textNode.textContent.length
          textNodeIndex = 0
          nextTextNodeIndex = textNodeLength

        while nextTextNodeIndex <= charIndex
          textNode = iterator.nextNode()
          textNodeLength = textNode.textContent.length
          textNodeIndex = nextTextNodeIndex
          nextTextNodeIndex = textNodeIndex + textNodeLength

        if charIndex is column
          indexWithinToken = charIndex - textNodeIndex
          return @leftPixelPositionForCharInTextNode(textNode, indexWithinToken)

        charIndex += charLength

    if textNode?
      @leftPixelPositionForCharInTextNode(textNode, textNode.textContent.length)
    else
      0

  leftPixelPositionForCharInTextNode: (textNode, charIndex) ->
    @rangeForMeasurement.setEnd(textNode, textNode.textContent.length)

    if charIndex is 0
      @rangeForMeasurement.setStart(textNode, 0)
      @rangeForMeasurement.getBoundingClientRect().left
    else if charIndex is textNode.textContent.length
      @rangeForMeasurement.setStart(textNode, 0)
      @rangeForMeasurement.getBoundingClientRect().right
    else
      @rangeForMeasurement.setStart(textNode, charIndex)
      @rangeForMeasurement.getBoundingClientRect().left