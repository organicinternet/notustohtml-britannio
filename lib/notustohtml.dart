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
      print('_handleLine: $attributes');
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
          print('--- ${operationData[i].replaceAll('\n', '⏎')}');
          if (operationData[i] == '\n') {
            if (spanBuffer.isNotEmpty) {
              // Write the span if it's not empty.
              print('spanBuffer isNotEmpty');
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
    print('_writeLine: style: $style');
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

    // Deltas must end with a newline aka \n
    if (delta.isNotEmpty && delta.last.data.endsWith('\n')) {
      return delta;
    } else {
      return delta..insert('\n');
    }
  }

  Delta _parseNode(
    dom.Node htmlNode,
    Delta delta,
    dom.Node nextHtmlNode, {
    bool inList,
    Map<String, dynamic> parentAttributes,
  }) {
    print('- _parseNode: $htmlNode');

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
            attributes: parentAttributes,
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
            attributes: parentAttributes,
          );
        });
        return delta;
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
          attributes: parentAttributes,
        );
        return delta;
      }
    } else if (htmlNode is dom.Text) {
      print('$htmlNode is Text');
      // The html node is text
      dom.Text text = htmlNode;
      /*  if (next != null &&
          next.runtimeType == dom.Element &&
          (next as dom.Element).localName == "br") {
        delta.insert(text.text + "\n");
      } else {
        delta.insert(text.text);
      } */

      delta.insert(
        text.text,
        parentAttributes?.isNotEmpty ?? false ? parentAttributes : null,
      );
      return delta;
    } else {
      // The html node isn't an element or text e.g. if it's a comment
      return delta;
    }
  }

  Delta _parseElement(
    dom.Element element,
    Delta delta, {
    Map<String, dynamic> attributes,
    @required String listType,
    @required dom.Node next,
    @required bool inList,
  }) {
    final type = _supportedHTMLElements[element.localName];
    if (type == _HtmlType.BLOCK) {
      Map<String, dynamic> blockAttributes = {};
      if (attributes != null) blockAttributes = attributes;
      /*  if (element.localName == "h1") {
        blockAttributes["heading"] = 1;
      }
      if (element.localName == "h2") {
        blockAttributes["heading"] = 2;
      }
      if (element.localName == "h3") {
        blockAttributes["heading"] = 3;
      } */
      if (element.localName == "blockquote") {
        blockAttributes["block"] = "quote";
      }
      if (element.localName == "code") {
        blockAttributes["block"] = "code";
      }
      if (element.localName == "li") {
        blockAttributes["block"] = listType;
      }
      element.nodes.asMap().forEach((index, node) {
        dom.Node next;
        if (index + 1 < element.nodes.length) next = element.nodes[index + 1];
        delta = _parseNode(node, delta, next,
            inList: element.localName == "li",
            parentAttributes: blockAttributes);
      });
      if (attributes == null) {
        delta..insert("\n", blockAttributes);
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
      attributes ??= {};
      if (element.localName == "em" || element.localName == "i") {
        attributes["i"] = true;
      }
      if (element.localName == "strong" || element.localName == "b") {
        attributes["b"] = true;
      }
      if (element.localName == "h1") {
        attributes["heading"] = 1;
      }
      if (element.localName == "h2") {
        attributes["heading"] = 2;
      }
      if (element.localName == "h3") {
        attributes["heading"] = 3;
      }
      if (element.localName == "a") {
        attributes["a"] = element.attributes["href"];
      }

      if (element.children.isEmpty) {
        // The element has no child elements i.e. this is the leaf element
        if (attributes["a"] != null) {
          delta..insert(element.text, attributes);
          if (inList == null || (inList != null && !inList)) {
            delta..insert("\n");
          }
        } else {
          if (next is dom.Element && next.localName == "br") {
            delta..insert(element.text + "\n", attributes);
          } else {
            // Deltas treat an enpty attribute map differently to a null one

            delta
              ..insert(
                element.text,
                attributes.isNotEmpty ? attributes : null,
              );
          }
        }
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

          /* if (_supportedHTMLElements[element.localName] == null) {
            return;
          }
          delta = _parseElement(
            element,
            delta,
            attributes: attributes,
            next: next,
          ); */
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
    "h1": _HtmlType.INLINE,
    "h2": _HtmlType.INLINE,
    "h3": _HtmlType.INLINE,
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
