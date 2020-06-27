library notustohtml;

import 'dart:convert';

import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart';
import 'package:notus/notus.dart';
import 'package:quill_delta/quill_delta.dart';
import 'package:meta/meta.dart';

class NotusHtmlCodec extends Codec<Delta, String> {
  const NotusHtmlCodec();

  @override
  Converter<String, Delta> get decoder => _NotusHtmlDecoder();

  @override
  Converter<Delta, String> get encoder => _NotusHtmlEncoder();
}

/// Delta -> HTML
class _NotusHtmlEncoder extends Converter<Delta, String> {
  static const kBold = 'strong';
  static const kItalic = 'em';
  static final kSimpleBlocks = <NotusAttribute, String>{
    NotusAttribute.bq: 'blockquote',
    NotusAttribute.ul: 'ul',
    NotusAttribute.ol: 'ol',
  };

  @override
  String convert(Delta input) {
    final deltaIterator = DeltaIterator(input);
    final htmlBuffer = StringBuffer();
    final lineBuffer = StringBuffer();
    NotusAttribute<String> currentBlockStyle;
    NotusStyle currentInlineStyle = NotusStyle();
    final List<String> currentBlockLines = [];

    void _handleBlock(NotusAttribute<String> blockStyle) {
      if (currentBlockLines.isEmpty) {
        return; // Empty block
      }

      if (blockStyle == null) {
        htmlBuffer.write(currentBlockLines.join());
      } else if (blockStyle == NotusAttribute.code) {
        _writeAttribute(htmlBuffer, blockStyle);
        htmlBuffer.write(currentBlockLines.join('\n'));
        _writeAttribute(htmlBuffer, blockStyle, close: true);
      } else if (blockStyle == NotusAttribute.bq) {
        _writeAttribute(htmlBuffer, blockStyle);
        htmlBuffer.write(currentBlockLines.join('\n'));
        _writeAttribute(htmlBuffer, blockStyle, close: true);
      } else if (blockStyle == NotusAttribute.ol ||
          blockStyle == NotusAttribute.ul) {
        _writeAttribute(htmlBuffer, blockStyle);
        htmlBuffer.write("<li>");
        // TODO consider removing P tags from currentBlockLines
        htmlBuffer.write(currentBlockLines.join('</li><li>'));
        htmlBuffer.write("</li>");
        _writeAttribute(htmlBuffer, blockStyle, close: true);
      } else {
        for (String line in currentBlockLines) {
          _writeBlockTag(htmlBuffer, blockStyle);
          htmlBuffer.write(line);
        }
      }
    }

    void _handleSpan(String text, Map<String, dynamic> attributes) {
      final style = NotusStyle.fromJson(attributes);
      currentInlineStyle = _writeInline(
        lineBuffer,
        text,
        style,
        currentInlineStyle,
      );
    }

    void _handleLine(Map<String, dynamic> attributes) {
      final style = NotusStyle.fromJson(attributes);
      final lineBlock = style.get(NotusAttribute.block);
      final bool isLineBlock = currentBlockStyle == lineBlock;

      if (isLineBlock) {
        currentBlockLines.add(_writeLine(lineBuffer.toString(), style));
      } else {
        _handleBlock(currentBlockStyle);
        currentBlockLines.clear();
        currentBlockLines.add(_writeLine(lineBuffer.toString(), style));

        currentBlockStyle = lineBlock;
      }
      lineBuffer.clear();
    }

    while (deltaIterator.hasNext) {
      final operation = deltaIterator.next();
      final operationData = operation.data;
      final operationIsOneLine = !operationData.contains('\n');

      if (operationIsOneLine) {
        _handleSpan(operationData, operation.attributes);
      } else {
        final spanBuffer = StringBuffer();
        for (int i = 0; i < operationData.length; i++) {
          if (operationData[i] == '\n') {
            if (spanBuffer.isNotEmpty) {
              // Write the span if it's not empty.
              _handleSpan(spanBuffer.toString(), operation.attributes);
            }
            // Close any open inline styles.
            _handleSpan('', null);
            _handleLine(operation.attributes);
            spanBuffer.clear();
          } else {
            spanBuffer.write(operationData[i]);
            // span.writeCharCode(operationData.codeUnitAt(i));
          }
        }
        // Remaining span
        if (spanBuffer.isNotEmpty) {
          _handleSpan(spanBuffer.toString(), operation.attributes);
        }
      }
    }

    _handleBlock(currentBlockStyle); // Close the last block
    return htmlBuffer.toString().trim();
  }

  String _writeLine(String text, NotusStyle style) {
    bool addPTag = !style.contains(NotusAttribute.block);

    final buffer = StringBuffer();
    if (addPTag) _writeParagraphTag(buffer);

    if (text.isNotEmpty) {
      // Write the text itself
      buffer.write(text);
    } else {
      // Blank likes should look like `<p><br></p>
      _writeBreakTag(buffer);
    }

    if (addPTag) _writeParagraphTag(buffer, close: true);
    return buffer.toString();
  }

  String _trimRight(StringBuffer buffer) {
    final text = buffer.toString();
    if (!text.endsWith(' ')) return '';
    final result = text.trimRight();
    buffer.clear();
    buffer.write(result);
    return ' ' * (text.length - result.length);
  }

  NotusStyle _writeInline(
    StringBuffer lineBuffer,
    String text,
    NotusStyle style,
    NotusStyle currentStyle,
  ) {
    NotusAttribute hyperlinkAttribute;
    // First close any current styles if needed, they should be closed in
    // reverse order so inner tags are closed before outer ones.
    for (NotusAttribute attribute in currentStyle.values.toList().reversed) {
      if (attribute.scope == NotusAttributeScope.line) continue;
      if (attribute.key == "a") {
        hyperlinkAttribute = attribute;
        continue;
      }
      if (style.containsSame(attribute)) continue;
      final padding = _trimRight(lineBuffer);
      _writeAttribute(lineBuffer, attribute, close: true);
      if (padding.isNotEmpty) lineBuffer.write(padding);
    }
    if (hyperlinkAttribute != null) {
      _writeAttribute(lineBuffer, hyperlinkAttribute, close: true);
    }
    // Now open any new styles.
    for (NotusAttribute value in style.values) {
      if (value.scope == NotusAttributeScope.line) continue;
      if (currentStyle.containsSame(value)) continue;
      final originalText = text;
      text = text.trimLeft();
      final padding = ' ' * (originalText.length - text.length);
      if (padding.isNotEmpty) lineBuffer.write(padding);
      _writeAttribute(lineBuffer, value);
    }
    // Write the text itself
    lineBuffer.write(text);
    return style;
  }

  void _writeAttribute(StringBuffer buffer, NotusAttribute attribute,
      {bool close = false}) {
    if (attribute == NotusAttribute.bold) {
      _writeBoldTag(buffer, close: close);
    } else if (attribute == NotusAttribute.italic) {
      _writeItalicTag(buffer, close: close);
    } else if (attribute.key == NotusAttribute.link.key) {
      _writeLinkTag(buffer, attribute as NotusAttribute<String>, close: close);
    } else if (attribute.key == NotusAttribute.heading.key) {
      _writeHeadingTag(buffer, attribute as NotusAttribute<int>, close: close);
    } else if (attribute.key == NotusAttribute.block.key) {
      _writeBlockTag(buffer, attribute as NotusAttribute<String>, close: close);
    } else if (attribute.key == NotusAttribute.embed.key) {
      _writeEmbedTag(buffer, attribute as EmbedAttribute, close: close);
    } else {
      throw ArgumentError('Cannot handle $attribute');
    }
  }

  void _writeParagraphTag(StringBuffer buffer, {bool close = false}) {
    buffer.write(!close ? "<p>" : "</p>");
  }

  void _writeBreakTag(StringBuffer buffer, {bool close = false}) {
    buffer.write(!close ? "<br>" : "</br>");
  }

  void _writeBoldTag(StringBuffer buffer, {bool close = false}) {
    buffer.write(!close ? "<$kBold>" : "</$kBold>");
  }

  void _writeItalicTag(StringBuffer buffer, {bool close = false}) {
    buffer.write(!close ? "<$kItalic>" : "</$kItalic>");
  }

  void _writeLinkTag(StringBuffer buffer, NotusAttribute<String> link,
      {bool close = false}) {
    if (close) {
      buffer.write('</a>');
    } else {
      buffer.write('<a href="${link.value}">');
    }
  }

  void _writeHeadingTag(StringBuffer buffer, NotusAttribute<int> heading,
      {bool close = false}) {
    int level = heading.value;
    buffer.write(!close ? "<h$level>" : "</h$level>");
  }

  void _writeBlockTag(StringBuffer buffer, NotusAttribute<String> block,
      {bool close = false}) {
    if (block == NotusAttribute.code) {
      if (!close) {
        buffer.write('\n<code>');
      } else {
        buffer.write('</code>\n');
      }
    } else {
      if (!close) {
        buffer.write('<${kSimpleBlocks[block]}>');
      } else {
        buffer.write('</${kSimpleBlocks[block]}>');
      }
    }
  }

  void _writeEmbedTag(StringBuffer buffer, EmbedAttribute embed,
      {bool close = false}) {
    if (close) return;
    if (embed.type == EmbedType.horizontalRule) {
      buffer.write("<hr>");
    } else if (embed.type == EmbedType.image) {
      buffer.write('<img src="${embed.value["source"]}">');
    }
  }
}

/// HTML -> Delta
class _NotusHtmlDecoder extends Converter<String, Delta> {
  @override
  Delta convert(String input) {
    Delta delta = Delta();

    final dom.Document html = parse(input);

    final dom.NodeList htmlNodes = html.body.nodes;

    // Removes empty p tags like <p></p>
    htmlNodes.removeWhere(
      (dom.Node htmlNode) {
        return htmlNode is dom.Element &&
            htmlNode.localName == 'p' &&
            htmlNode.nodes.isEmpty;
      },
    );

    

    /// Converts each HTML node to a [Delta]
    htmlNodes.asMap().forEach((int index, dom.Node htmlNode) {
      dom.Node nextNode;

      /// If the current node isn't the final node then initialise [next] as the
      /// next node
      if (index + 1 < htmlNodes.length) {
        nextNode = htmlNodes[index + 1];
      }

      // TODO Could this use delta.insert?
      delta = _parseNode(htmlNode, delta, nextNode);
    });

    /* // Deltas must end with a newline aka \n
    if (delta.isNotEmpty && delta.last.data.endsWith('\n')) {
      return delta;
    } else {
      return _appendNewLine(delta);
    } */
    return delta;
  }

  Delta _appendNewLine(Delta delta) {
    // This is a workaround as sometimes the Delta is created without a
    // trailing \n
    final List<Operation> operations = delta.toList();

    if (operations.isNotEmpty) {
      final Operation lastOperation = operations.removeLast();
      operations.add(
        Operation.insert('${lastOperation.data}\n', lastOperation.attributes),
      );
      delta = Delta();

      operations.forEach(delta.push);
    } else {
      return delta..insert('\n');
    }
    return delta;
  }

  Delta _parseNode(
    dom.Node htmlNode,
    Delta delta,
    dom.Node nextHtmlNode, {
    bool inList,
    Map<String, dynamic> parentAttributes,
    Map<String, dynamic> parentBlockAttributes,
  }) {
    final Map<String, dynamic> attributes = Map.from(parentAttributes ?? {});
    final Map<String, dynamic> blockAttributes =
        Map.from(parentBlockAttributes ?? {});
    if (htmlNode is dom.Element) {
      print('$htmlNode is Element');
      // The html node is an element
      dom.Element element = htmlNode;
      final String elementName = htmlNode.localName;
      if (elementName == "ul") {
        // Unordered list
        element.children.forEach((child) {
          delta = _parseElement(
            child,
            delta,
            listType: "ul",
            next: nextHtmlNode,
            inList: inList,
            parentAttributes: attributes,
            parentBlockAttributes: blockAttributes,
          );
        });
        return delta;
      } else if (elementName == "ol") {
        // Ordered list
        element.children.forEach((child) {
          delta = _parseElement(
            child,
            delta,
            listType: "ol",
            next: nextHtmlNode,
            inList: inList,
            parentAttributes: attributes,
            parentBlockAttributes: blockAttributes,
          );
        });
        return delta;
      } else if (elementName == 'p') {
        // TODO check if it only contains a br tag
        // Paragraph
        final nodes = element.nodes;

        // TODO find a simpler way to express htis
        if (nodes.length == 1 &&
            nodes.first is dom.Element &&
            (nodes.first as dom.Element).localName == 'br') {
          // The p tag looks like <p><br></p> so we should treat it as a blank
          // line
          return delta..insert('\n');
        } else {
          for (int i = 0; i < nodes.length; i++) {
            delta = _parseNode(
              nodes[i],
              delta,
              nextHtmlNode,
              parentAttributes: attributes,
              parentBlockAttributes: blockAttributes,
            );
          }
          if (delta.isEmpty || !delta.last.data.endsWith('\n')) {
            delta = _appendNewLine(delta);
          }
          return delta;
        }
      } else if (elementName == 'br') {
        return delta..insert('\n');
      } else if (_supportedHTMLElements[elementName] == null) {
        // Not a supported element
        return delta;
      } else {
        // A supported element that isn't an ordered or unordered list
        delta = _parseElement(
          element,
          delta,
          next: nextHtmlNode,
          inList: inList,
          parentAttributes: attributes,
          parentBlockAttributes: blockAttributes,
        );
        return delta;
      }
    } else if (htmlNode is dom.Text) {
      print('$htmlNode is Text');
      // The html node is text
      dom.Text text = htmlNode;

      if (nextHtmlNode is dom.Element &&
          (nextHtmlNode.localName == 'br' || nextHtmlNode.localName == 'p')) {
        delta.insert(
          '${text.text}\n',
          attributes.isNotEmpty ? attributes : null,
        );
      } else {
        delta.insert(
          text.text,
          attributes.isNotEmpty ? attributes : null,
        );
      }
      return delta;
    } else {
      // The html node isn't an element or text e.g. if it's a comment
      return delta;
    }
  }

  Delta _parseElement(
    dom.Element element,
    Delta delta, {
    Map<String, dynamic> parentAttributes,
    Map<String, dynamic> parentBlockAttributes,
    String listType,
    @required dom.Node next,
    // bool addTrailingLineBreak = false,
    @required bool inList,
  }) {
    final Map<String, dynamic> attributes = Map.from(parentAttributes ?? {});
    final type = _supportedHTMLElements[element.localName];
    if (type == _HtmlType.BLOCK) {
      final Map<String, dynamic> blockAttributes =
          Map.from(parentBlockAttributes ?? {});

      if (element.localName == "blockquote") {
        blockAttributes["block"] = "quote";
      }
      if (element.localName == "code") {
        blockAttributes["block"] = "code";
      }
      if (element.localName == "li") {
        blockAttributes["block"] = listType;
      }
      if (element.localName == "h1") {
        blockAttributes["heading"] = 1;
      }
      if (element.localName == "h2") {
        blockAttributes["heading"] = 2;
      }
      if (element.localName == "h3") {
        blockAttributes["heading"] = 3;
      }
      element.nodes.asMap().forEach((index, node) {
        dom.Node next;
        // Initialise `next` if possible
        if (index + 1 < element.nodes.length) next = element.nodes[index + 1];

        delta = _parseNode(
          node,
          delta,
          next,
          inList: element.localName == "li",
          parentAttributes: attributes,
          parentBlockAttributes: blockAttributes,
        );
      });
      if (parentBlockAttributes.isEmpty) {
        delta..insert('\n', blockAttributes);
      }
      return delta;
    } else if (type == _HtmlType.EMBED) {
      NotusDocument tempdocument;
      if (element.localName == "img") {
        delta..insert("\n");
        tempdocument = NotusDocument.fromDelta(delta);
        final int index = tempdocument.length;
        tempdocument.format(index - 1, 0,
            NotusAttribute.embed.image(element.attributes["src"]));
      }
      if (element.localName == "hr") {
        delta..insert("\n");
        tempdocument = NotusDocument.fromDelta(delta);
        final int index = tempdocument.length;
        tempdocument.format(index - 1, 0, NotusAttribute.embed.horizontalRule);
      }
      return tempdocument.toDelta();
    } else {
      if (element.localName == "em" || element.localName == "i") {
        attributes["i"] = true;
      }
      if (element.localName == "strong" || element.localName == "b") {
        attributes["b"] = true;
      }

      if (element.localName == "a") {
        attributes["a"] = element.attributes["href"];
      }

      if (element.children.isEmpty) {
        // The element has no child elements i.e. this is the leaf element
        if (attributes["a"] != null) {
          // It's a link
          delta..insert(element.text, attributes);
          if (inList == null || (inList != null && !inList)) {
            delta..insert("\n");
          }
        } else {
          delta
            ..insert(
              element.text,
              attributes.isNotEmpty ? attributes : null,
            );
          /* // If the next node is a br/p node then add a new line
          // TODO sometimes
          if (next is dom.Element &&
              (next.localName == "br" || next.localName == "p")) {
            delta
              ..insert(
                element.text + "\n",
                attributes.isNotEmpty ? attributes : null,
              );
          } else {
            // Deltas treat an enpty attribute map differently to a null one

            delta
              ..insert(
                element.text,
                attributes.isNotEmpty ? attributes : null,
              );
          } */
        }
        // TODO ADD ELSE TO CHECK IF IS PARGRAPH
      } else {
        // The element has child elements(subclass of node) and potentially
        // text(subclass of node)
        element.nodes.asMap().forEach((index, node) {
          dom.Node nextNode;

          /// If the current node isn't the final node then initialise [next] as the
          /// next node
          if (index + 1 < element.nodes.length) {
            nextNode = element.nodes[index + 1];
          }
          _parseNode(
            node,
            delta,
            nextNode,
            parentAttributes: attributes,
          );
        });
      }
      return delta;
    }
  }

  Map<String, _HtmlType> _supportedHTMLElements = {
    "img": _HtmlType.EMBED,
    "hr": _HtmlType.EMBED,
    "li": _HtmlType.BLOCK,
    "blockquote": _HtmlType.BLOCK,
    "code": _HtmlType.BLOCK,
    "div": _HtmlType.BLOCK,
    "h1": _HtmlType.BLOCK,
    "h2": _HtmlType.BLOCK,
    "h3": _HtmlType.BLOCK,
    // Italic
    "em": _HtmlType.INLINE,
    "i": _HtmlType.INLINE,
    // Bold
    "strong": _HtmlType.INLINE,
    "b": _HtmlType.INLINE,
    "a": _HtmlType.INLINE,
    "p": _HtmlType.INLINE,
  };
}

enum _HtmlType { BLOCK, INLINE, EMBED }
