library notustohtml;

import 'dart:convert';

import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart';
import 'package:notus/notus.dart';
import 'package:quill_delta/quill_delta.dart';

class NotusHtmlCodec extends Codec<Delta, String> {
  const NotusHtmlCodec();

  @override
  Converter<String, Delta> get decoder => _NotusHtmlDecoder();

  @override
  Converter<Delta, String> get encoder => _NotusHtmlEncoder();
}

class _NotusHtmlEncoder extends Converter<Delta, String> {
  static const kBold = 'b';
  static const kItalic = 'i';
  static final kSimpleBlocks = <NotusAttribute, String>{
    NotusAttribute.bq: 'blockquote',
    NotusAttribute.ul: 'ul',
    NotusAttribute.ol: 'ol',
  };

  @override
  String convert(Delta input) {
    final iterator = DeltaIterator(input);
    final buffer = StringBuffer();
    final lineBuffer = StringBuffer();
    NotusAttribute<String> currentBlockStyle;
    NotusStyle currentInlineStyle = NotusStyle();
    final List<String> currentBlockLines = [];

    void _handleBlock(NotusAttribute<String> blockStyle) {
      if (currentBlockLines.isEmpty) {
        return; // Empty block
      }

      if (blockStyle == null) {
        buffer.write(currentBlockLines.join('\n\n'));
        buffer.writeln();
      } else if (blockStyle == NotusAttribute.code) {
        _writeAttribute(buffer, blockStyle);
        buffer.write(currentBlockLines.join('\n'));
        _writeAttribute(buffer, blockStyle, close: true);
        buffer.writeln();
      } else if (blockStyle == NotusAttribute.bq) {
        _writeAttribute(buffer, blockStyle);
        buffer.write(currentBlockLines.join('\n'));
        _writeAttribute(buffer, blockStyle, close: true);
        buffer.writeln();
      } else if (blockStyle == NotusAttribute.ol ||
          blockStyle == NotusAttribute.ul) {
        _writeAttribute(buffer, blockStyle);
        buffer.write("<li>");
        buffer.write(currentBlockLines.join('</li><li>'));
        buffer.write("</li>");
        _writeAttribute(buffer, blockStyle, close: true);
        buffer.writeln();
      } else {
        for (String line in currentBlockLines) {
          _writeBlockTag(buffer, blockStyle);
          buffer.write(line);
          buffer.writeln();
        }
      }
      buffer.writeln();
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
      if (lineBlock == currentBlockStyle) {
        currentBlockLines.add(_writeLine(lineBuffer.toString(), style));
      } else {
        _handleBlock(currentBlockStyle);
        currentBlockLines.clear();
        currentBlockLines.add(_writeLine(lineBuffer.toString(), style));

        currentBlockStyle = lineBlock;
      }
      lineBuffer.clear();
    }

    while (iterator.hasNext) {
      final operation = iterator.next();
      final operationData = operation.data;
      final operationIsSingleLine = !operationData.contains('\n');

      if (operationIsSingleLine) {
        _handleSpan(operationData, operation.attributes);
      } else {
        final span = StringBuffer();
        for (int i = 0; i < operationData.length; i++) {
          // 0x0A is a new line
          // if (operationData.codeUnitAt(i) == 0x0A) {
          if (operationData[i] == '\n') {
            if (span.isNotEmpty) {
              // Write the span if it's not empty.
              _handleSpan(span.toString(), operation.attributes);
            }
            // Close any open inline styles.
            _handleSpan('', null);
            _handleLine(operation.attributes);
            span.clear();
          } else {
            span.write(operationData[i]);
            // span.writeCharCode(operationData.codeUnitAt(i));
          }
        }
        // Remaining span
        if (span.isNotEmpty) {
          _handleSpan(span.toString(), operation.attributes);
        }
      }
    }

    _handleBlock(currentBlockStyle); // Close the last block
    return buffer.toString().trim() /* .replaceAll("\n", "<br>") */;
  }

  String _writeLine(String text, NotusStyle style) {
    final buffer = StringBuffer();
    // Open heading
    if (style.contains(NotusAttribute.heading)) {
      _writeAttribute(buffer, style.get<int>(NotusAttribute.heading));
    }
    // Write the text itself
    buffer.write(text);
    // Close the heading
    if (style.contains(NotusAttribute.heading)) {
      _writeAttribute(buffer, style.get<int>(NotusAttribute.heading),
          close: true);
    }
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
    StringBuffer buffer,
    String text,
    NotusStyle style,
    NotusStyle currentStyle,
  ) {
    NotusAttribute wasA;
    // First close any current styles if needed
    for (NotusAttribute value in currentStyle.values) {
      if (value.scope == NotusAttributeScope.line) continue;
      if (value.key == "a") {
        wasA = value;
        continue;
      }
      if (style.containsSame(value)) continue;
      final padding = _trimRight(buffer);
      _writeAttribute(buffer, value, close: true);
      if (padding.isNotEmpty) buffer.write(padding);
    }
    if (wasA != null) {
      _writeAttribute(buffer, wasA, close: true);
    }
    // Now open any new styles.
    for (NotusAttribute value in style.values) {
      if (value.scope == NotusAttributeScope.line) continue;
      if (currentStyle.containsSame(value)) continue;
      final originalText = text;
      text = text.trimLeft();
      final padding = ' ' * (originalText.length - text.length);
      if (padding.isNotEmpty) buffer.write(padding);
      _writeAttribute(buffer, value);
    }
    // Write the text itself
    buffer.write(text);
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

class _NotusHtmlDecoder extends Converter<String, Delta> {
  // TODO add new line to end of paragraphs
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
      delta = _parseNode(htmlNode, delta, nextNode);
    });

    return delta;
  }

  Delta _parseNode(
    dom.Node node,
    Delta delta,
    dom.Node next, {
    bool inList,
    Map<String, dynamic> inBlock,
  }) {
    final bool nodeIsElement = node.runtimeType == dom.Element;
    final bool nodeIsText = node.runtimeType == dom.Text;
    if (nodeIsElement) {
      // The html node is an element
      dom.Element element = node;
      if (element.localName == "ul") {
        // Unordered list
        element.children.forEach((child) {
          delta = _parseElement(
            child,
            delta,
            _supportedHTMLElements[child.localName],
            listType: "ul",
            next: next,
            inList: inList,
            inBlock: inBlock,
          );
        });
        return delta;
      } else if (element.localName == "ol") {
        // Ordered list
        element.children.forEach((child) {
          delta = _parseElement(
            child,
            delta,
            _supportedHTMLElements[child.localName],
            listType: "ol",
            next: next,
            inList: inList,
            inBlock: inBlock,
          );
        });
        return delta;
      } else if (_supportedHTMLElements[element.localName] == null) {
        // Not a supported element
        return delta;
      } else {
        // A supported element that isn't an ordered or unordered list
        delta = _parseElement(
          element,
          delta,
          _supportedHTMLElements[element.localName],
          next: next,
          inList: inList,
          inBlock: inBlock,
        );
        return delta;
      }
    } else if (nodeIsText) {
      // The html node is text
      dom.Text text = node;
      /*  if (next != null &&
          next.runtimeType == dom.Element &&
          (next as dom.Element).localName == "br") {
        delta.insert(text.text + "\n");
      } else {
        delta.insert(text.text);
      } */
      delta.insert(text.text);
      return delta;
    } else {
      // The html node isn't an element or text e.g. if it's a comment
      return delta;
    }
  }

  Delta _parseElement(
    dom.Element element,
    Delta delta,
    String type, {
    Map<String, dynamic> attributes,
    String listType,
    dom.Node next,
    bool inList,
    Map<String, dynamic> inBlock,
  }) {
    if (type == "block") {
      Map<String, dynamic> blockAttributes = {};
      if (inBlock != null) blockAttributes = inBlock;
      if (element.localName == "h1") {
        blockAttributes["heading"] = 1;
      }
      if (element.localName == "h2") {
        blockAttributes["heading"] = 2;
      }
      if (element.localName == "h3") {
        blockAttributes["heading"] = 3;
      }
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
            inList: element.localName == "li", inBlock: blockAttributes);
      });
      if (inBlock == null) {
        delta..insert("\n", blockAttributes);
      }
      return delta;
    } else if (type == "embed") {
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
      if (element.localName == "a") {
        attributes["a"] = element.attributes["href"];
      }
      if (element.children.isEmpty) {
        if (attributes["a"] != null) {
          delta..insert(element.text, attributes);
          if (inList == null || (inList != null && !inList)) {
            delta..insert("\n");
          }
        } else {
          if (next != null &&
              next.runtimeType == dom.Element &&
              (next as dom.Element).localName == "br") {
            delta..insert(element.text + "\n", attributes);
          } else {
            delta..insert(element.text, attributes);
          }
        }
      } else {
        element.children.forEach((element) {
          if (_supportedHTMLElements[element.localName] == null) {
            return;
          }
          delta = _parseElement(
            element,
            delta,
            _supportedHTMLElements[element.localName],
            attributes: attributes,
            next: next,
          );
        });
      }
      return delta;
    }
  }

  Map<String, String> _supportedHTMLElements = {
    "li": "block",
    "blockquote": "block",
    "code": "block",
    "h1": "block",
    "h2": "block",
    "h3": "block",
    "div": "block",
    // Italic
    "em": "inline",
    "i": "inline",
    // Bold
    "strong": "inline",
    "b": "inline",
    "a": "inline",
    "p": "inline",
    "img": "embed",
    "hr": "embed",
  };
}
