library notustohtml;

import 'dart:collection';
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
  static const kParagraph = 'p';
  static const kLineBreak = 'br';
  static const kHeading1 = 'h1';
  static const kHeading2 = 'h2';
  static const kHeading3 = 'h3';
  static const kListItem = 'li';
  static const kUnorderedList = 'ul';
  static const kOrderedList = 'ol';
  static const kCode = 'code';
  static const kQuote = 'blockquote';

  final LinkedHashSet<String> openTags = LinkedHashSet<String>();

  StringBuffer htmlBuffer;

  @override
  String convert(Delta input) {
    htmlBuffer = StringBuffer();
    final LinkedList<Node> nodes = NotusDocument.fromDelta(input).root.children;

    nodes.forEach(_parseNode);

    return htmlBuffer.toString();
  }

  void _parseNode(Node node) {
    if (node is LineNode) {
      _parseLineNode(node);
    } else if (node is BlockNode) {
      _parseBlockNode(node);
    } else {
      throw UnsupportedError(
        '$node is not supported by _NotusHtmlEncoder._parseNode',
      );
    }
  }

  /// Assumes that the style contains a heading
  String _getHeadingTag(NotusStyle style) {
    final level = style.value<int>(NotusAttribute.heading);
    switch (level) {
      case 1:
        return kHeading1;
      case 2:
        return kHeading2;
      case 3:
        return kHeading3;
      default:
        throw UnsupportedError(
          'Unsupported heading level: $level, does your style contain a heading'
          ' attribute?',
        );
    }
  }

  void _parseLineNode(LineNode node) {
    final bool isHeading = node.style.contains(NotusAttribute.heading);
    final bool isList = node.style.containsSame(NotusAttribute.ul) ||
        node.style.containsSame(NotusAttribute.ol);
    final bool isNewLine =
        node.isEmpty && node.style.isEmpty && node.next != null;

    // Opening heading/paragraph tag
    String tag;
    if (isHeading) {
      tag = _getHeadingTag(node.style);
    } else if (isList) {
      tag = kListItem;
    } else {
      tag = kParagraph;
      // throw UnsupportedError('Unsupported LineNode style: ${node.style}');
    }

    if (isNewLine) {
      _writeTag(kParagraph);
      _writeTag(kLineBreak);
      _writeTag(kParagraph, close: true);
    } else if (node.isNotEmpty) {
      _writeTag(tag);
      node.children.cast<LeafNode>().forEach(_parseLeafNode);
      _writeTag(tag, close: true);
    }
  }

  void _parseBlockNode(BlockNode node) {
    String tag;
    if (node.style.containsSame(NotusAttribute.ul)) {
      tag = kUnorderedList;
    } else if (node.style.containsSame(NotusAttribute.ol)) {
      tag = kOrderedList;
    } else if (node.style.containsSame(NotusAttribute.code)) {
      tag = kCode;
    } else if (node.style.containsSame(NotusAttribute.bq)) {
      tag = kQuote;
    } else {
      throw UnsupportedError('Unsupported BlockNode: $node');
    }
    _writeTag(tag);
    node.children.cast<LineNode>().forEach(_parseLineNode);
    _writeTag(tag, close: true);
  }

  void _parseLeafNode(LeafNode node) {
    bool isBold(LeafNode node) =>
        node.style?.containsSame(NotusAttribute.bold) ?? false;
    bool isItalic(LeafNode node) =>
        node.style?.containsSame(NotusAttribute.italic) ?? false;

    if (node is TextNode) {
      // Open style tag if `node.prev` doesn't contain it but `node` does
      // Write text
      // Close style tag if node.next doesn't contain it but `node` does

      final LeafNode previousNode = node.previous;
      final LeafNode nextNode = node.next;

      // TODO check if I should only check for previous textNodes?
      final previousNodeHasStyle = previousNode?.style?.isNotEmpty ?? false;
      final nextNodeHasStyle = nextNode?.style?.isNotEmpty ?? false;

      // Open styles
      final Set<String> tagsToOpen = {};
      if (isBold(node) && (!previousNodeHasStyle || !isBold(previousNode))) {
        // First LeafNode in the LineNode that is bold
        tagsToOpen.add(kBold);
      }
      if (isItalic(node) &&
          // First LeafNode in the LineNode that is italic
          (!previousNodeHasStyle || !isItalic(previousNode))) {
        tagsToOpen.add(kItalic);
      }

      if (tagsToOpen.isNotEmpty) _writeTagsOrdered(tagsToOpen);

      // Write the content
      htmlBuffer.write(node.value);

      // Close styles
      final Set<String> tagsToClose = {};
      if (isItalic(node) && (!nextNodeHasStyle || !isItalic(nextNode))) {
        // Last LeafNode in the LineNode that is italic
        tagsToClose.add(kItalic);
      }
      if (isBold(node) && (!nextNodeHasStyle || !isBold(nextNode))) {
        // Last LeafNode in the LineNode that is bold
        tagsToClose.add(kBold);
      }
      if (tagsToClose.isNotEmpty) _writeTagsOrdered(tagsToClose);
    } else if (node is EmbedNode) {
      // TODO add EmbedNode support
    } else {
      throw 'Unsupported LeafNode';
    }
  }

  void _writeTag(String tag, {bool close = false}) {
    // and storing the current order of open tags so they can be
    // closed in the correct order
    htmlBuffer.write(close ? '</$tag>' : '<$tag>');
  }

  /// Takes a set of tags and opens them if they're unopened otherwise
  /// it closes them in the reverse order they were opened in.
  /// This should only be used for tags with the same heirarchy e.g.
  /// bold/italic/link and not headings, paragraphs, line breaks etc
  void _writeTagsOrdered(Set<String> tags) {
    /// Close tags from [tags] if they are open
    List<String>.from(openTags.toList().reversed).forEach((tag) {
      if (tags.contains(tag)) {
        // Remove this tag
        openTags.remove(tag);
        tags.remove(tag);
        _writeTag(tag, close: true);
      }
    });

    /// The remaining [tags] need to be opened
    tags.forEach((tag) {
      _writeTag(tag);
      openTags.add(tag);
    });
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
    htmlNodes.forEach((htmlNode) => delta = _parseNode(htmlNode, delta));

    if (delta.isEmpty ||
        !(delta.last.data is String &&
            (delta.last.data as String).endsWith('\n'))) {
      delta = _appendNewLine(delta);
    }

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
    Delta delta, {
    bool inList,
    Map<String, dynamic> parentAttributes,
    Map<String, dynamic> parentBlockAttributes,
  }) {
    final Map<String, dynamic> attributes = Map.from(parentAttributes ?? {});
    final Map<String, dynamic> blockAttributes =
        Map.from(parentBlockAttributes ?? {});
    if (htmlNode is dom.Element) {
      // The html node is an element
      final dom.Element element = htmlNode;
      final String elementName = htmlNode.localName;
      if (elementName == 'ul') {
        // Unordered list
        element.children.forEach((child) {
          delta = _parseElement(
            child,
            delta,
            listType: 'ul',
            inList: inList,
            parentAttributes: attributes,
            parentBlockAttributes: blockAttributes,
          );
        });
        return delta;
      } else if (elementName == 'ol') {
        // Ordered list
        element.children.forEach((child) {
          delta = _parseElement(
            child,
            delta,
            listType: 'ol',
            inList: inList,
            parentAttributes: attributes,
            parentBlockAttributes: blockAttributes,
          );
        });
        return delta;
      } else if (elementName == 'p') {
        // Paragraph
        final nodes = element.nodes;

        // TODO find a simpler way to express this
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
              parentAttributes: attributes,
              parentBlockAttributes: blockAttributes,
            );
          }
          if (delta.isEmpty ||
              !(delta.last.data is String &&
                  (delta.last.data as String).endsWith('\n'))) {
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
          inList: inList,
          parentAttributes: attributes,
          parentBlockAttributes: blockAttributes,
        );
        return delta;
      }
    } else if (htmlNode is dom.Text) {
      // The html node is text
      final dom.Text text = htmlNode;

      delta.insert(
        text.text,
        attributes.isNotEmpty ? attributes : null,
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
    Map<String, dynamic> parentAttributes,
    Map<String, dynamic> parentBlockAttributes,
    String listType,
    // bool addTrailingLineBreak = false,
    @required bool inList,
  }) {
    final Map<String, dynamic> attributes = Map.from(parentAttributes ?? {});
    final type = _supportedHTMLElements[element.localName];
    if (type == _HtmlType.BLOCK) {
      final Map<String, dynamic> blockAttributes =
          Map.from(parentBlockAttributes ?? {});

      if (element.localName == 'blockquote') {
        blockAttributes['block'] = 'quote';
      }
      if (element.localName == 'code') {
        blockAttributes['block'] = 'code';
      }
      if (element.localName == 'li') {
        blockAttributes['block'] = listType;
      }
      if (element.localName == 'h1') {
        blockAttributes['heading'] = 1;
      }
      if (element.localName == 'h2') {
        blockAttributes['heading'] = 2;
      }
      if (element.localName == 'h3') {
        blockAttributes['heading'] = 3;
      }
      element.nodes.forEach((node) {
        delta = _parseNode(
          node,
          delta,
          inList: element.localName == 'li',
          parentAttributes: attributes,
          parentBlockAttributes: blockAttributes,
        );
      });
      if (parentBlockAttributes.isEmpty) {
        delta.insert('\n', blockAttributes);
      }
      return delta;
    } else if (type == _HtmlType.EMBED) {
      NotusDocument tempdocument;
      if (element.localName == 'img') {
        /* delta.insert('\n');
        tempdocument = NotusDocument.fromDelta(delta);
        final int index = tempdocument.length;
        tempdocument.format(index - 1, 0,
            NotusAttribute.embed.image(element.attributes['src'])); */
      }
      if (element.localName == 'hr') {
        /*  delta.insert('\n');
        tempdocument = NotusDocument.fromDelta(delta);
        final int index = tempdocument.length;
        tempdocument.format(index - 1, 0, NotusAttribute.embed.horizontalRule); */
      }
      return tempdocument.toDelta();
    } else {
      if (element.localName == 'em' || element.localName == 'i') {
        attributes['i'] = true;
      }
      if (element.localName == 'strong' || element.localName == 'b') {
        attributes['b'] = true;
      }

      if (element.localName == 'a') {
        attributes['a'] = element.attributes['href'];
      }

      if (element.children.isEmpty) {
        // The element has no child elements i.e. this is the leaf element
        if (attributes['a'] != null) {
          // It's a link
          delta.insert(element.text, attributes);
          if (inList == null || (inList != null && !inList)) {
            delta.insert('\n');
          }
        } else {
          delta.insert(
            element.text,
            attributes.isNotEmpty ? attributes : null,
          );
        }
      } else {
        // The element has child elements(subclass of node) and potentially
        // text(subclass of node)
        element.nodes.forEach(
          (node) {
            delta = _parseNode(
              node,
              delta,
              parentAttributes: attributes,
            );
          },
        );
      }
      return delta;
    }
  }

  final Map<String, _HtmlType> _supportedHTMLElements = {
    'img': _HtmlType.EMBED,
    'hr': _HtmlType.EMBED,
    'li': _HtmlType.BLOCK,
    'blockquote': _HtmlType.BLOCK,
    'code': _HtmlType.BLOCK,
    'div': _HtmlType.BLOCK,
    'h1': _HtmlType.BLOCK,
    'h2': _HtmlType.BLOCK,
    'h3': _HtmlType.BLOCK,
    // Italic
    'em': _HtmlType.INLINE,
    'i': _HtmlType.INLINE,
    // Bold
    'strong': _HtmlType.INLINE,
    'b': _HtmlType.INLINE,
    'a': _HtmlType.INLINE,
    'p': _HtmlType.INLINE,
  };
}

enum _HtmlType { BLOCK, INLINE, EMBED }
