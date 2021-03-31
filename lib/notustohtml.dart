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
  static const kUnderline = 'u';
  static const kStrikethrough = 's';
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
      case 11:
        return kHeading1;
      case 2:
      case 12:
        return kHeading2;
      case 3:
      case 13:
        return kHeading3;
      default:
        throw UnsupportedError(
          'Unsupported heading level: $level, does your style contain a heading'
          ' attribute?',
        );
    }
  }

  String _getHeadingClass(NotusStyle style) {
    if (!style.contains(NotusAttribute.heading)) return '';
    final level = style.value<int>(NotusAttribute.heading);
    switch (level) {
      case 11:
        return 'lightheader-one';
      case 12:
        return 'lightheader-two';
      case 13:
        return 'lightheader-three';
      default:
        return null;
    }
  }

  String _getAlignmentClass(NotusStyle style) {
    if (!style.contains(NotusAttribute.alignment)) return '';
    if (style.value<String>(NotusAttribute.alignment) ==
        NotusAttribute.leftAlignment.value) {
      return ' ql-align-left';
    }
    if (style.value<String>(NotusAttribute.alignment) ==
        NotusAttribute.centerAlignment.value) {
      return ' ql-align-center';
    }
    if (style.value<String>(NotusAttribute.alignment) ==
        NotusAttribute.rightAlignment.value) {
      return ' ql-align-right';
    }
    if (style.value<String>(NotusAttribute.alignment) ==
        NotusAttribute.justifyAlignment.value) {
      return ' ql-align-justify';
    }
    return '';
  }

  void _parseLineNode(LineNode node, {inBlockQuote = false}) {
    final bool isHeading = node.style.contains(NotusAttribute.heading);
    final bool isList = node.style.containsSame(NotusAttribute.ul) ||
        node.style.containsSame(NotusAttribute.ol);
    final bool isNewLine =
        node.isEmpty && node.style.isEmpty && node.next != null;

    // Opening heading/paragraph tag
    String tag;
    String cssClass;
    if (isHeading) {
      tag = _getHeadingTag(node.style);
      cssClass = _getHeadingClass(node.style);
      cssClass = (cssClass ?? '') + _getAlignmentClass(node.style);
    } else if (isList) {
      tag = kListItem;
    } else {
      tag = kParagraph;
      if (node.style != null && node.style.contains(NotusAttribute.p)) {
        cssClass = node.style.value<String>(NotusAttribute.p);
      }
      if (node.style != null && node.style.contains(NotusAttribute.alignment)) {
        cssClass = (cssClass ?? '') + _getAlignmentClass(node.style);
      }
      // throw UnsupportedError('Unsupported LineNode style: ${node.style}');
    }

    if (isNewLine) {
      _writeTag(kParagraph);
      _writeTag(kLineBreak);
      _writeTag(kParagraph, close: true);
    } else if (inBlockQuote) {
      node.children.cast<LeafNode>().forEach(_parseLeafNode);
    } else if (node.isNotEmpty) {
      _writeTag(tag, cssClass: cssClass);
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
    node.children.cast<LineNode>().forEach(
        (childNode) => _parseLineNode(childNode, inBlockQuote: tag == kQuote));
    _writeTag(tag, close: true);
  }

  void _parseLeafNode(LeafNode node) {
    bool isBold(LeafNode node) =>
        node.style?.containsSame(NotusAttribute.bold) ?? false;
    bool isItalic(LeafNode node) =>
        node.style?.containsSame(NotusAttribute.italic) ?? false;
    bool isUnderline(LeafNode node) =>
        node.style?.containsSame(NotusAttribute.underline) ?? false;
    bool isStrikethrough(LeafNode node) =>
        node.style?.containsSame(NotusAttribute.strikethrough) ?? false;
    bool isColor(LeafNode node) =>
        node.style?.contains(NotusAttribute.color) ?? false;
    bool isBackgroundColor(LeafNode node) =>
        node.style?.contains(NotusAttribute.backgroundColor) ?? false;
    bool isSpan(LeafNode node) =>
        node.style?.contains(NotusAttribute.span) ?? false;
    bool isLink(LeafNode node) =>
        node.style?.contains(NotusAttribute.link) ?? false;

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
      if (isUnderline(node) &&
          // First LeafNode in the LineNode that is underlined
          (!previousNodeHasStyle || !isUnderline(previousNode))) {
        tagsToOpen.add(kUnderline);
      }
      if (isStrikethrough(node) &&
          // First LeafNode in the LineNode that is strikethrough
          (!previousNodeHasStyle || !isStrikethrough(previousNode))) {
        tagsToOpen.add(kStrikethrough);
      }
      // TODO use tagsToOpen ideally (with attributes)
      if (isColor(node) &&
          // First LeafNode in the LineNode that is colored
          (!previousNodeHasStyle || !isColor(previousNode))) {
        htmlBuffer.write(
            '<span style="color: ${node.style.value<String>(NotusAttribute.color)}">');
      }
      // TODO use tagsToOpen ideally (with attributes)
      if (isBackgroundColor(node) &&
          // First LeafNode in the LineNode that is colored
          (!previousNodeHasStyle || !isColor(previousNode))) {
        htmlBuffer.write(
            '<span style="background-color: ${node.style.value<String>(NotusAttribute.backgroundColor)}">');
      }
      // TODO use tagsToOpen ideally (with attributes)
      if (isSpan(
              node) /* &&
          // First LeafNode in the LineNode that has ql font
          (!previousNodeHasStyle || !isSpan(previousNode))*/
          ) {
        htmlBuffer.write(
            '<span class="${node.style.value<String>(NotusAttribute.span)}">');
      }
      if (isLink(node)) {
        htmlBuffer.write(
            '<a href="${node.style.value<String>(NotusAttribute.link)}">');
      }

      if (tagsToOpen.isNotEmpty) _writeTagsOrdered(tagsToOpen);

      // Write the content
      htmlBuffer.write(node.value);

      // Close styles
      final Set<String> tagsToClose = {};

      if (isLink(
              node) /* &&
          // First LeafNode in the LineNode that has ql font
          (!nextNodeHasStyle || !isSpan(nextNode))*/
          ) {
        htmlBuffer.write('</a>');
      }
      if (isSpan(
              node) /* &&
          // First LeafNode in the LineNode that has ql font
          (!nextNodeHasStyle || !isSpan(nextNode))*/
          ) {
        htmlBuffer.write('</span>');
      }

      if (isBackgroundColor(node) &&
          // First LeafNode in the LineNode that is colored
          (!nextNodeHasStyle || !isBackgroundColor(nextNode))) {
        htmlBuffer.write('</span>');
      }

      if (isColor(node) &&
          // First LeafNode in the LineNode that is colored
          (!nextNodeHasStyle || !isColor(nextNode))) {
        htmlBuffer.write('</span>');
      }

      if (isStrikethrough(node) &&
          (!nextNodeHasStyle || !isStrikethrough(nextNode))) {
        // Last LeafNode in the LineNode that is strikethrough
        tagsToClose.add(kStrikethrough);
      }
      if (isUnderline(node) && (!nextNodeHasStyle || !isUnderline(nextNode))) {
        // Last LeafNode in the LineNode that is underlined
        tagsToClose.add(kUnderline);
      }
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
      var value = node.style.value(NotusAttribute.embed);
      var linkValue = node.style.contains(NotusAttribute.link)
          ? node.style.value(NotusAttribute.link)
          : null;
      if (value['type'] == 'image') {
        if (linkValue != null) {
          htmlBuffer.write('<a href="$linkValue" target="_blank">');
        }
        htmlBuffer.write('<img src="${value['source']}">');
        if (linkValue != null) {
          htmlBuffer.write('</a>');
        }
      }
    } else {
      throw 'Unsupported LeafNode';
    }
  }

  void _writeTag(String tag, {String cssClass, bool close = false}) {
    // and storing the current order of open tags so they can be
    // closed in the correct order
    if (cssClass != null) {
      htmlBuffer.write(close ? '</$tag>' : '<$tag class="$cssClass">');
    } else {
      htmlBuffer.write(close ? '</$tag>' : '<$tag>');
    }
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

        // get the custom class if available
        if (element.className.contains('body-one')) {
          blockAttributes['p'] = 'body-one';
        } else if (element.className.contains('body-three')) {
          blockAttributes['p'] = 'body-three';
        } else if (element.className.contains('body-four')) {
          blockAttributes['p'] = 'body-four';
        } else if (element.className.contains('listed')) {
          blockAttributes['p'] = 'listed';
        } else {
          blockAttributes['p'] = 'body-two';
        }

        if (element.className.contains('ql-align-left')) {
          blockAttributes['alignment'] = 'left';
        } else if (element.className.contains('ql-align-center')) {
          blockAttributes['alignment'] = 'center';
        } else if (element.className.contains('ql-align-right')) {
          blockAttributes['alignment'] = 'right';
        } else if (element.className.contains('ql-align-justify')) {
          blockAttributes['alignment'] = 'justify';
        }

        // TODO find a simpler way to express this
        if (nodes.length == 1 &&
            nodes.first is dom.Element &&
            (nodes.first as dom.Element).localName == 'br') {
          // The p tag looks like <p><br></p> so we should treat it as a blank
          // line
          return delta..insert('\n');
        } else if (nodes.length == 1 &&
            nodes.first is dom.Element &&
            (nodes.first as dom.Element).localName == 'img') {
          // if (blockAttributes['alignment'] == null &&
          //     blockAttributes['p'] == null) {
          //   // it won't get the \n added later
          //   delta..insert('\n');
          // }
          NotusDocument tempdocument;
          tempdocument = NotusDocument.fromDelta(delta);
          final int index = tempdocument.length;
          tempdocument.format(
              index - 1,
              0,
              NotusAttribute.embed
                  .image((nodes.first as dom.Element).attributes['src']));
          return tempdocument.toDelta();
          // attributes['embed'] = NotusAttribute.embed
          //     .image((nodes.first as dom.Element).attributes['src']);

          // NotusDocument tempdocument = NotusDocument.fromDelta(delta);
          // final int index = tempdocument.length;
          // tempdocument.format(index - 1, 0,
          //     NotusAttribute.embed.image(element.attributes['src']));
          // if (attributes['a'] != null) {
          //   print('DOING THE LINK');
          //   tempdocument.format(
          //       index - 1, 1, NotusAttribute.link.fromString(attributes['a']));
          // }
          // return tempdocument.toDelta();
        } else {
          for (int i = 0; i < nodes.length; i++) {
            delta = _parseNode(
              nodes[i],
              delta,
              parentAttributes: attributes,
              parentBlockAttributes: null,
            );
          }

          if (blockAttributes['alignment'] != null ||
              blockAttributes['p'] != null) {
            if (delta.last.data == '\n') {
              if (delta.last.attributes != null)
                delta.last.attributes.addAll(blockAttributes);
            } else {
              delta..insert('\n', blockAttributes);
            }
          } else {
            if (delta.isEmpty ||
                !(delta.last.data is String &&
                    (delta.last.data as String).endsWith('\n'))) {
              delta = _appendNewLine(delta);
            }
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
      if (element.className.contains('ql-align-left')) {
        blockAttributes['alignment'] = 'left';
      } else if (element.className.contains('ql-align-center')) {
        blockAttributes['alignment'] = 'center';
      } else if (element.className.contains('ql-align-right')) {
        blockAttributes['alignment'] = 'right';
      } else if (element.className.contains('ql-align-justify')) {
        blockAttributes['alignment'] = 'justify';
      }
      if (element.localName == 'h1') {
        if (element.className.contains('lightheader-one')) {
          blockAttributes['heading'] = 11;
        } else {
          blockAttributes['heading'] = 1;
        }
      }
      if (element.localName == 'h2') {
        if (element.className.contains('lightheader-two')) {
          blockAttributes['heading'] = 12;
        } else {
          blockAttributes['heading'] = 2;
        }
      }
      if (element.localName == 'h3') {
        if (element.className.contains('lightheader-three')) {
          blockAttributes['heading'] = 13;
        } else {
          blockAttributes['heading'] = 3;
        }
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
        if (delta.last.data is String &&
            (delta.last.data as String).endsWith('\n')) {
        } else {
          delta.insert('\n');
        }
        tempdocument = NotusDocument.fromDelta(delta);
        final int index = tempdocument.length;
        tempdocument.format(index - 1, 0,
            NotusAttribute.embed.image(element.attributes['src']));
        if (attributes['a'] != null) {
          // print('DOING THE LINK ' + attributes['a']);
          tempdocument.format(
              index - 1, 2, NotusAttribute.link.fromString(attributes['a']));
        }
      }
      if (element.localName == 'hr') {
        delta.insert('\n');
        tempdocument = NotusDocument.fromDelta(delta);
        final int index = tempdocument.length;
        tempdocument.format(index - 1, 0, NotusAttribute.embed.horizontalRule);
      }
      return tempdocument.toDelta();
    } else {
      if (element.localName == 'em' || element.localName == 'i') {
        attributes['i'] = true;
      }
      if (element.localName == 'strong' || element.localName == 'b') {
        attributes['b'] = true;
      }
      if (element.localName == 'u') {
        attributes['u'] = true;
      }
      if (element.localName == 's') {
        attributes['s'] = true;
      }

      if (element.localName == 'a') {
        attributes['a'] = element.attributes['href'];
      }

      if (true || element.localName == 'span') {
        // could be color, backgroundColor or ql-font
        if (element.attributes['style'] != null) {
          if (element.attributes['style']
              .contains('background-color: rgb(0, 0, 0)')) {
            attributes[NotusAttribute.backgroundColor.key] =
                NotusAttribute.bcblack.value;
          }
          if (element.attributes['style']
              .contains('background-color: rgb(230, 0, 0)')) {
            attributes[NotusAttribute.backgroundColor.key] =
                NotusAttribute.bcred.value;
          }
          if (element.attributes['style']
              .contains('background-color: rgb(255, 153, 0)')) {
            attributes[NotusAttribute.backgroundColor.key] =
                NotusAttribute.bcorange.value;
          }
          if (element.attributes['style']
              .contains('background-color: rgb(255, 255, 0)')) {
            attributes[NotusAttribute.backgroundColor.key] =
                NotusAttribute.bcyellow.value;
          }
          if (element.attributes['style']
              .contains('background-color: rgb(0, 138, 0)')) {
            attributes[NotusAttribute.backgroundColor.key] =
                NotusAttribute.bcgreen.value;
          }
          if (element.attributes['style']
              .contains('background-color: rgb(0, 102, 204)')) {
            attributes[NotusAttribute.backgroundColor.key] =
                NotusAttribute.bcblue.value;
          }
          if (element.attributes['style']
              .contains('background-color: rgb(153, 51, 255)')) {
            attributes[NotusAttribute.backgroundColor.key] =
                NotusAttribute.bcpurple.value;
          }
          if (element.attributes['style']
              .contains('background-color: rgb(255, 255, 255)')) {
            attributes[NotusAttribute.backgroundColor.key] =
                NotusAttribute.bcwhite.value;
          }
          if (element.attributes['style']
              .contains('background-color: rgb(250, 204, 204)')) {
            attributes[NotusAttribute.backgroundColor.key] =
                NotusAttribute.bcpink.value;
          }
          if (element.attributes['style']
              .contains('background-color: rgb(255, 235, 204)')) {
            attributes[NotusAttribute.backgroundColor.key] =
                NotusAttribute.bcmagnolia.value;
          }
          if (element.attributes['style']
              .contains('background-color: rgb(255, 255, 204)')) {
            attributes[NotusAttribute.backgroundColor.key] =
                NotusAttribute.bccream.value;
          }
          if (element.attributes['style']
              .contains('background-color: rgb(204, 232, 204)')) {
            attributes[NotusAttribute.backgroundColor.key] =
                NotusAttribute.bcmint.value;
          }
          if (element.attributes['style']
              .contains('background-color: rgb(204, 224, 245)')) {
            attributes[NotusAttribute.backgroundColor.key] =
                NotusAttribute.bceggshell.value;
          }
          if (element.attributes['style']
              .contains('background-color: rgb(235, 214, 255)')) {
            attributes[NotusAttribute.backgroundColor.key] =
                NotusAttribute.bcmauve.value;
          }
          if (element.attributes['style']
              .contains('background-color: rgb(187, 187, 187)')) {
            attributes[NotusAttribute.backgroundColor.key] =
                NotusAttribute.bclightGrey.value;
          }
          if (element.attributes['style']
              .contains('background-color: rgb(240, 102, 102)')) {
            attributes[NotusAttribute.backgroundColor.key] =
                NotusAttribute.bcrosy.value;
          }
          if (element.attributes['style']
              .contains('background-color: rgb(255, 194, 102)')) {
            attributes[NotusAttribute.backgroundColor.key] =
                NotusAttribute.bcamber.value;
          }
          if (element.attributes['style']
              .contains('background-color: rgb(255, 255, 102)')) {
            attributes[NotusAttribute.backgroundColor.key] =
                NotusAttribute.bccanary.value;
          }
          if (element.attributes['style']
              .contains('background-color: rgb(102, 185, 102)')) {
            attributes[NotusAttribute.backgroundColor.key] =
                NotusAttribute.bcregent.value;
          }
          if (element.attributes['style']
              .contains('background-color: rgb(102, 163, 224)')) {
            attributes[NotusAttribute.backgroundColor.key] =
                NotusAttribute.bceuston.value;
          }
          if (element.attributes['style']
              .contains('background-color: rgb(194, 133, 255)')) {
            attributes[NotusAttribute.backgroundColor.key] =
                NotusAttribute.bcpremier.value;
          }
          if (element.attributes['style']
              .contains('background-color: rgb(136, 136, 136)')) {
            attributes[NotusAttribute.backgroundColor.key] =
                NotusAttribute.bcmidGrey.value;
          }
          if (element.attributes['style']
              .contains('background-color: rgb(161, 0, 0)')) {
            attributes[NotusAttribute.backgroundColor.key] =
                NotusAttribute.bcmaroon.value;
          }
          if (element.attributes['style']
              .contains('background-color: rgb(178, 107, 0)')) {
            attributes[NotusAttribute.backgroundColor.key] =
                NotusAttribute.bcmustard.value;
          }
          if (element.attributes['style']
              .contains('background-color: rgb(178, 178, 0)')) {
            attributes[NotusAttribute.backgroundColor.key] =
                NotusAttribute.bcsick.value;
          }
          if (element.attributes['style']
              .contains('background-color: rgb(0, 97, 0)')) {
            attributes[NotusAttribute.backgroundColor.key] =
                NotusAttribute.bcsnooker.value;
          }
          if (element.attributes['style']
              .contains('background-color: rgb(0, 71, 178)')) {
            attributes[NotusAttribute.backgroundColor.key] =
                NotusAttribute.bceverton.value;
          }
          if (element.attributes['style']
              .contains('background-color: rgb(107, 36, 178)')) {
            attributes[NotusAttribute.backgroundColor.key] =
                NotusAttribute.bclenny.value;
          }
          if (element.attributes['style']
              .contains('background-color: rgb(68, 68, 68)')) {
            attributes[NotusAttribute.backgroundColor.key] =
                NotusAttribute.bccharcoal.value;
          }
          if (element.attributes['style']
              .contains('background-color: rgb(92, 0, 0)')) {
            attributes[NotusAttribute.backgroundColor.key] =
                NotusAttribute.bcbudget.value;
          }
          if (element.attributes['style']
              .contains('background-color: rgb(102, 61, 0)')) {
            attributes[NotusAttribute.backgroundColor.key] =
                NotusAttribute.bcbrown.value;
          }
          if (element.attributes['style']
              .contains('background-color: rgb(102, 102, 0)')) {
            attributes[NotusAttribute.backgroundColor.key] =
                NotusAttribute.bcbean.value;
          }
          if (element.attributes['style']
              .contains('background-color: rgb(0, 55, 0)')) {
            attributes[NotusAttribute.backgroundColor.key] =
                NotusAttribute.bcaftereight.value;
          }
          if (element.attributes['style']
              .contains('background-color: rgb(0, 41, 102)')) {
            attributes[NotusAttribute.backgroundColor.key] =
                NotusAttribute.bcocean.value;
          }
          if (element.attributes['style']
              .contains('background-color: rgb(61, 20, 102)')) {
            attributes[NotusAttribute.backgroundColor.key] =
                NotusAttribute.bcbruise.value;
          }

          if (element.attributes['style'].startsWith('color: rgb(0, 0, 0)') ||
              element.attributes['style'].contains(' color: rgb(0, 0, 0)')) {
            attributes[NotusAttribute.color.key] = NotusAttribute.black.value;
          }
          if (element.attributes['style'].startsWith('color: rgb(230, 0, 0)') ||
              element.attributes['style'].contains(' color: rgb(230, 0, 0)')) {
            attributes[NotusAttribute.color.key] = NotusAttribute.red.value;
          }
          if (element.attributes['style']
                  .startsWith('color: rgb(255, 153, 0)') ||
              element.attributes['style']
                  .contains(' color: rgb(255, 153, 0)')) {
            attributes[NotusAttribute.color.key] = NotusAttribute.orange.value;
          }
          if (element.attributes['style']
                  .startsWith('color: rgb(255, 255, 0)') ||
              element.attributes['style']
                  .contains(' color: rgb(255, 255, 0)')) {
            attributes[NotusAttribute.color.key] = NotusAttribute.yellow.value;
          }
          if (element.attributes['style'].startsWith('color: rgb(0, 138, 0)') ||
              element.attributes['style'].contains(' color: rgb(0, 138, 0)')) {
            attributes[NotusAttribute.color.key] = NotusAttribute.green.value;
          }
          if (element.attributes['style']
                  .startsWith('color: rgb(0, 102, 204)') ||
              element.attributes['style']
                  .contains(' color: rgb(0, 102, 204)')) {
            attributes[NotusAttribute.color.key] = NotusAttribute.blue.value;
          }
          if (element.attributes['style']
                  .startsWith('color: rgb(153, 51, 255)') ||
              element.attributes['style']
                  .contains(' color: rgb(153, 51, 255)')) {
            attributes[NotusAttribute.color.key] = NotusAttribute.purple.value;
          }
          if (element.attributes['style']
                  .startsWith('color: rgb(255, 255, 255)') ||
              element.attributes['style']
                  .contains(' color: rgb(255, 255, 255)')) {
            attributes[NotusAttribute.color.key] = NotusAttribute.white.value;
          }
          if (element.attributes['style']
                  .startsWith('color: rgb(250, 204, 204)') ||
              element.attributes['style']
                  .contains(' color: rgb(250, 204, 204)')) {
            attributes[NotusAttribute.color.key] = NotusAttribute.pink.value;
          }
          if (element.attributes['style']
                  .startsWith('color: rgb(255, 235, 204)') ||
              element.attributes['style']
                  .contains(' color: rgb(255, 235, 204)')) {
            attributes[NotusAttribute.color.key] =
                NotusAttribute.magnolia.value;
          }
          if (element.attributes['style']
                  .startsWith('color: rgb(255, 255, 204)') ||
              element.attributes['style']
                  .contains(' color: rgb(255, 255, 204)')) {
            attributes[NotusAttribute.color.key] = NotusAttribute.cream.value;
          }
          if (element.attributes['style']
                  .startsWith('color: rgb(204, 232, 204)') ||
              element.attributes['style']
                  .contains(' color: rgb(204, 232, 204)')) {
            attributes[NotusAttribute.color.key] = NotusAttribute.mint.value;
          }
          if (element.attributes['style']
                  .startsWith('color: rgb(204, 224, 245)') ||
              element.attributes['style']
                  .contains(' color: rgb(204, 224, 245)')) {
            attributes[NotusAttribute.color.key] =
                NotusAttribute.eggshell.value;
          }
          if (element.attributes['style']
                  .startsWith('color: rgb(235, 214, 255)') ||
              element.attributes['style']
                  .contains(' color: rgb(235, 214, 255)')) {
            attributes[NotusAttribute.color.key] = NotusAttribute.mauve.value;
          }
          if (element.attributes['style']
                  .startsWith('color: rgb(187, 187, 187)') ||
              element.attributes['style']
                  .contains(' color: rgb(187, 187, 187)')) {
            attributes[NotusAttribute.color.key] =
                NotusAttribute.lightGrey.value;
          }
          if (element.attributes['style']
                  .startsWith('color: rgb(240, 102, 102)') ||
              element.attributes['style']
                  .contains(' color: rgb(240, 102, 102)')) {
            attributes[NotusAttribute.color.key] = NotusAttribute.rosy.value;
          }
          if (element.attributes['style']
                  .startsWith('color: rgb(255, 194, 102)') ||
              element.attributes['style']
                  .contains(' color: rgb(255, 194, 102)')) {
            attributes[NotusAttribute.color.key] = NotusAttribute.amber.value;
          }
          if (element.attributes['style']
                  .startsWith('color: rgb(255, 255, 102)') ||
              element.attributes['style']
                  .contains(' color: rgb(255, 255, 102)')) {
            attributes[NotusAttribute.color.key] = NotusAttribute.canary.value;
          }
          if (element.attributes['style']
                  .startsWith('color: rgb(102, 185, 102)') ||
              element.attributes['style']
                  .contains(' color: rgb(102, 185, 102)')) {
            attributes[NotusAttribute.color.key] = NotusAttribute.regent.value;
          }
          if (element.attributes['style']
                  .startsWith('color: rgb(102, 163, 224)') ||
              element.attributes['style']
                  .contains(' color: rgb(102, 163, 224)')) {
            attributes[NotusAttribute.color.key] = NotusAttribute.euston.value;
          }
          if (element.attributes['style']
                  .startsWith('color: rgb(194, 133, 255)') ||
              element.attributes['style']
                  .contains(' color: rgb(194, 133, 255)')) {
            attributes[NotusAttribute.color.key] = NotusAttribute.premier.value;
          }
          if (element.attributes['style']
                  .startsWith('color: rgb(136, 136, 136)') ||
              element.attributes['style']
                  .contains(' color: rgb(136, 136, 136)')) {
            attributes[NotusAttribute.color.key] = NotusAttribute.midGrey.value;
          }
          if (element.attributes['style'].startsWith('color: rgb(161, 0, 0)') ||
              element.attributes['style'].contains(' color: rgb(161, 0, 0)')) {
            attributes[NotusAttribute.color.key] = NotusAttribute.maroon.value;
          }
          if (element.attributes['style']
                  .startsWith('color: rgb(178, 107, 0)') ||
              element.attributes['style']
                  .contains(' color: rgb(178, 107, 0)')) {
            attributes[NotusAttribute.color.key] = NotusAttribute.mustard.value;
          }
          if (element.attributes['style']
                  .startsWith('color: rgb(178, 178, 0)') ||
              element.attributes['style']
                  .contains(' color: rgb(178, 178, 0)')) {
            attributes[NotusAttribute.color.key] = NotusAttribute.sick.value;
          }
          if (element.attributes['style'].startsWith('color: rgb(0, 97, 0)') ||
              element.attributes['style'].contains(' color: rgb(0, 97, 0)')) {
            attributes[NotusAttribute.color.key] = NotusAttribute.snooker.value;
          }
          if (element.attributes['style']
                  .startsWith('color: rgb(0, 71, 178)') ||
              element.attributes['style'].contains(' color: rgb(0, 71, 178)')) {
            attributes[NotusAttribute.color.key] = NotusAttribute.everton.value;
          }
          if (element.attributes['style']
                  .startsWith('color: rgb(107, 36, 178)') ||
              element.attributes['style']
                  .contains(' color: rgb(107, 36, 178)')) {
            attributes[NotusAttribute.color.key] = NotusAttribute.lenny.value;
          }
          if (element.attributes['style']
                  .startsWith('color: rgb(68, 68, 68)') ||
              element.attributes['style'].contains(' color: rgb(68, 68, 68)')) {
            attributes[NotusAttribute.color.key] =
                NotusAttribute.charcoal.value;
          }
          if (element.attributes['style'].startsWith('color: rgb(92, 0, 0)') ||
              element.attributes['style'].contains(' color: rgb(92, 0, 0)')) {
            attributes[NotusAttribute.color.key] = NotusAttribute.budget.value;
          }
          if (element.attributes['style']
                  .startsWith('color: rgb(102, 61, 0)') ||
              element.attributes['style'].contains(' color: rgb(102, 61, 0)')) {
            attributes[NotusAttribute.color.key] = NotusAttribute.brown.value;
          }
          if (element.attributes['style']
                  .startsWith('color: rgb(102, 102, 0)') ||
              element.attributes['style']
                  .contains(' color: rgb(102, 102, 0)')) {
            attributes[NotusAttribute.color.key] = NotusAttribute.bean.value;
          }
          if (element.attributes['style'].startsWith('color: rgb(0, 55, 0)') ||
              element.attributes['style'].contains(' color: rgb(0, 55, 0)')) {
            attributes[NotusAttribute.color.key] =
                NotusAttribute.aftereight.value;
          }
          if (element.attributes['style']
                  .startsWith('color: rgb(0, 41, 102)') ||
              element.attributes['style'].contains(' color: rgb(0, 41, 102)')) {
            attributes[NotusAttribute.color.key] = NotusAttribute.ocean.value;
          }
          if (element.attributes['style']
                  .startsWith('color: rgb(61, 20, 102)') ||
              element.attributes['style']
                  .contains(' color: rgb(61, 20, 102)')) {
            attributes[NotusAttribute.color.key] = NotusAttribute.bruise.value;
          }
        }
      }
      if (element.className != null &&
          element.className.startsWith('ql-font-')) {
        if (element.className.contains('ql-font-10')) {
          attributes[NotusAttribute.span.key] =
              NotusAttribute.span.fontQl10.value;
        } else if (element.className.contains('ql-font-1')) {
          attributes[NotusAttribute.span.key] =
              NotusAttribute.span.fontQl1.value;
        } else if (element.className.contains('ql-font-2')) {
          attributes[NotusAttribute.span.key] =
              NotusAttribute.span.fontQl2.value;
        } else if (element.className.contains('ql-font-3')) {
          attributes[NotusAttribute.span.key] =
              NotusAttribute.span.fontQl3.value;
        } else if (element.className.contains('ql-font-4')) {
          attributes[NotusAttribute.span.key] =
              NotusAttribute.span.fontQl4.value;
        } else if (element.className.contains('ql-font-5')) {
          attributes[NotusAttribute.span.key] =
              NotusAttribute.span.fontQl5.value;
        } else if (element.className.contains('ql-font-6')) {
          attributes[NotusAttribute.span.key] =
              NotusAttribute.span.fontQl6.value;
        } else if (element.className.contains('ql-font-7')) {
          attributes[NotusAttribute.span.key] =
              NotusAttribute.span.fontQl7.value;
        } else if (element.className.contains('ql-font-8')) {
          attributes[NotusAttribute.span.key] =
              NotusAttribute.span.fontQl8.value;
        } else if (element.className.contains('ql-font-9')) {
          attributes[NotusAttribute.span.key] =
              NotusAttribute.span.fontQl9.value;
        }
      }

      if (element.children.isEmpty) {
        // The element has no child elements i.e. this is the leaf element
        if (attributes['a'] != null) {
          // It's a link
          delta.insert(element.text, attributes);
          // TODO don't break after links
          // if (inList == null || (inList != null && !inList)) {
          //   delta.insert('\n');
          // }
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

    'u': _HtmlType.INLINE,
    's': _HtmlType.INLINE,
    'a': _HtmlType.INLINE,
    'p': _HtmlType.BLOCK,
    'span': _HtmlType.INLINE,
  };
}

enum _HtmlType { BLOCK, INLINE, EMBED }
