import 'package:quill_delta/quill_delta.dart';
import 'package:test/test.dart';
import 'package:notustohtml/notustohtml.dart';
import 'package:notus/notus.dart';

void main() {
  final converter = NotusHtmlCodec();

  void testEncoder(Delta delta, String html) {
    test('[Encode]', () {
      // Asserts that the delta can be used to create a valid document
      NotusDocument.fromDelta(delta);
      final actualHtml = converter.encode(delta);
      expect(actualHtml, html);
    });
  }

  void testDecoder(String html, Delta delta) {
    test('[Decode]', () {
      // Asserts that the delta can be used to create a valid document
      NotusDocument.fromDelta(delta);
      final actualDelta = converter.decode(html);
      NotusDocument.fromDelta(actualDelta);
      expect(actualDelta, delta);
    });
  }

  void testConverter(String html, Delta delta) {
    testEncoder(delta, html);
    testDecoder(html, delta);
  }

  group('Basic text', () {
    group('Plain paragraph', () {
      final html = '<p>Hello World!</p>';

      final delta = Delta()..insert('Hello World!\n');

      testConverter(html, delta);
    });

    group('Bold paragraph(strong)', () {
      final html = '<p><strong>Hello World!</strong></p>';

      final delta = Delta()..insert('Hello World!\n', {'b': true});

      testConverter(html, delta);
    });

    group('Bold paragraph(b)', () {
      final encodeHtml = '<p><strong>Hello World!</strong></p>';
      final decodeHtml = '<p><b>Hello World!</b></p>';

      final delta = Delta()..insert('Hello World!\n', {'b': true});

      testEncoder(delta, encodeHtml);
      testDecoder(decodeHtml, delta);
    });

    group('Italic paragraph(em)', () {
      final html = '<p><em>Hello World!</em></p>';

      final delta = Delta()..insert('Hello World!\n', {'i': true});

      testConverter(html, delta);
    });
    group('Italic paragraph(i)', () {
      final encodeHtml = '<p><em>Hello World!</em></p>';
      final decodeHtml = '<p><i>Hello World!</i></p>';

      final delta = Delta()..insert('Hello World!\n', {'i': true});

      testEncoder(delta, encodeHtml);
      testDecoder(decodeHtml, delta);
    });

    group('Bold and Italic paragraph', () {
      final encodeHtml =
          '<p><em><strong>Hello World!</strong></em> <em><strong>How are you?</strong></em></p>';
      final decodeHtml =
          '<p><em><strong>Hello World!</strong></em> <i><b>How are you?</b></i></p>';

      final delta = Delta()
        ..insert('Hello World!', {'i': true, 'b': true})
        ..insert(' ')
        ..insert('How are you?\n', {'i': true, 'b': true});

      testEncoder(delta, encodeHtml);
      testDecoder(decodeHtml, delta);
    });

    group('Bold then Italic paragraph', () {
      final html = '<p><strong>Hello</strong> <em>World</em></p>';

      final delta = Delta()
        ..insert('Hello', {'b': true})
        ..insert(' ')
        ..insert('World\n', {'i': true});

      testConverter(html, delta);
    });
  });

  group('multi-line text', () {
    group('two lines', () {
      final html = '<p>Hello</p><p>World</p>';

      final delta = Delta()..insert('Hello\nWorld\n');

      testConverter(html, delta);
    });
    group('three lines', () {
      final html = '<p>The</p><p>quick</p><p>brown</p>';

      final delta = Delta()..insert('The\nquick\nbrown\n');

      testConverter(html, delta);
    });

    group('empty line', () {
      final html = '<p><br></p>';

      final delta = Delta()..insert('\n\n');

      testConverter(html, delta);
    });
    group('two empty lines', () {
      final html = '<p><br></p><p><br></p>';

      final delta = Delta()..insert('\n\n\n');
      testConverter(html, delta);
    });
  });

  group('Headings', () {
    group('1', () {
      final html = '<h1>Hello World!</h1>';

      final delta = Delta()
        ..insert('Hello World!')
        ..insert('\n', {'heading': 1});

      testConverter(html, delta);
    });

    group('2', () {
      final html = '<h2>Hello World!</h2>';

      final delta = Delta()
        ..insert('Hello World!')
        ..insert('\n', {'heading': 2});

      testConverter(html, delta);
    });

    group('3', () {
      final html = '<h3>Hello World!</h3>';

      final delta = Delta()
        ..insert('Hello World!')
        ..insert('\n', {'heading': 3});

      testConverter(html, delta);
    });
  });

  group('Blocks', () {
    // TODO test multi line blocks?
    group(
      'Single line quote',
      () {
        final html = '<blockquote>Hello World!</blockquote>';

        final delta = Delta()
          ..insert('Hello World!')
          ..insert('\n', {'block': 'quote'});

        testConverter(html, delta);
      },
    );

    group('Multi line quote', () {
      final html = '<blockquote>'
          '<p>Line 1</p>'
          '<p>Line 2</p>'
          '</blockquote>';

      final delta = Delta()
        ..insert('Line 1')
        ..insert('\n', {'block': 'quote'})
        ..insert('Line 2')
        ..insert('\n', {'block': 'quote'});

      testConverter(html, delta);
    });

    group(
      'Single-line code',
      () {
        final html = '<code>Hello World!</code>';

        final delta = Delta()
          ..insert('Hello World!')
          ..insert('\n', {'block': 'code'});

        testConverter(html, delta);
      },
    );
    group(
      'Multi-line code',
      () {
        final html = '<code>'
            '<p>Line 1</p>'
            '<p>Line 2</p>'
            '</code>';

        final delta = Delta()
          ..insert('Line 1')
          ..insert('\n', {'block': 'code'})
          ..insert('Line 2')
          ..insert('\n', {'block': 'code'});

        testConverter(html, delta);
      },
    );
    group('Ordered list 1', () {
      // Valid html
      final encodeHtml = '<ol><li>Hello World!</li></ol>';
      // Invalid but expected html
      final decodeHtml = '<p><ol><li>Hello World!</li></ol></p>';

      final delta = Delta()
        ..insert('Hello World!')
        ..insert('\n', {'block': 'ol'});

      testEncoder(delta, encodeHtml);
      testDecoder(decodeHtml, delta);
    });
    group('Ordered list 2', () {
      final html = '<p>Line 1</p>' '<ol><li>Hello World!</li></ol>';

      final delta = Delta()
        ..insert('Line 1\n')
        ..insert('Hello World!')
        ..insert('\n', {'block': 'ol'});

      testConverter(html, delta);
    });

    group('List with bold', () {
      final html = '<ol><li><strong>Hello World!</strong></li></ol>';

      final delta = Delta()
        ..insert('Hello World!', {'b': true})
        ..insert('\n', {'block': 'ol'});

      testConverter(html, delta);
    });
    group('Unordered list', () {
      final html = '<ul><li>Hello World!</li><li>Hello World!</li></ul>';

      final delta = Delta()
        ..insert('Hello World!')
        ..insert('\n', {'block': 'ul'})
        ..insert('Hello World!')
        ..insert('\n', {'block': 'ul'});

      testConverter(html, delta);
    });
  });

  group('Embeds', () {
    group('Image', () {
      final html = '<img src="http://fake.link/image.png">';
      final delta = Delta()..insert('\n');
      final document = NotusDocument.fromDelta(delta);
      var index = document.length;
      document.format(index - 1, 0,
          NotusAttribute.embed.image('http://fake.link/image.png'));

      testConverter(html, document.toDelta());
    });
    group('Line', () {
      final html = '<hr>';
      final delta = Delta()..insert('\n');
      final document = NotusDocument.fromDelta(delta);
      var index = document.length;
      document.format(index - 1, 0, NotusAttribute.embed.horizontalRule);

      testConverter(html, document.toDelta());
    });
  });

  group('Links', () {
    group('Plain', () {
      final html = '<p><a href="http://fake.link">Hello World!</a></p>';

      final delta = Delta()
        ..insert('Hello World!\n', {'a': 'http://fake.link'});

      testConverter(html, delta);
    });

    group('Italic', () {
      final html = '<a href=\'http://fake.link\'><em>Hello World!</em></a>';

      final delta = Delta()
        ..insert('Hello World!', {'a': 'http://fake.link', 'i': true})
        ..insert('\n');

      testConverter(html, delta);
    });

    group('In list', () {
      final html =
          '<ul><li><a href="http://fake.link">Hello World!</a></li></ul>';

      final delta = Delta()
        ..insert('Hello World!', {'a': 'http://fake.link'})
        ..insert('\n', {'block': 'ul'});

      testConverter(html, delta);
    });
  });

  group('nested inline styles', () {
    group('bold in italic', () {
      final html = '<p><em>Hello <strong>World!</strong></em></p>';

      final delta = Delta()
        ..insert('Hello ', {'i': true})
        ..insert('World!\n', {'i': true, 'b': true});

      testConverter(html, delta);
    });
    group('bold in italic 2', () {
      final html = '<p><em>The <strong>quick</strong> brown</em></p>';

      final delta = Delta()
        ..insert('The ', {'i': true})
        ..insert('quick', {'i': true, 'b': true})
        ..insert(' brown\n', {'i': true});

      testConverter(html, delta);
    });
    group('bold in italic 3', () {
      final html =
          '<p><em>The <strong>quick</strong> <strong>brown</strong></em></p>';

      final delta = Delta()
        ..insert('The ', {'i': true})
        ..insert('quick', {'i': true, 'b': true})
        ..insert(' ', {'i': true})
        ..insert('brown\n', {'i': true, 'b': true});

      testConverter(html, delta);
    });
  });

  group('integration test', () {
    final html = '<p>Plain text</p>'
        '<p><strong>Bold text</strong></p>'
        '<p><em>Italic text</em></p>'
        '<p><strong>Bold</strong> then <em>italic</em></p>'
        '<h1>Heading 1</h1>'
        '<p><br></p>'
        '<ul>'
        '<li>Unordered</li>'
        '<li>List</li>'
        '</ul>'
        '<ol>'
        '<li>Ordered</li>'
        '<li>List</li>'
        '</ol>';

    final Delta delta = Delta()
      ..insert('Plain text\n')
      ..insert('Bold text\n', {'b': true})
      ..insert('Italic text\n', {'i': true})
      ..insert('Bold', {'b': true})
      ..insert(' then ')
      ..insert('italic\n', {'i': true})
      ..insert('Heading 1')
      ..insert('\n', {'heading': 1})
      ..insert('\nUnordered')
      ..insert('\n', {'block': 'ul'})
      ..insert('List')
      ..insert('\n', {'block': 'ul'})
      ..insert('Ordered')
      ..insert('\n', {'block': 'ol'})
      ..insert('List')
      ..insert('\n', {'block': 'ol'});

    testConverter(html, delta);
  });
}

// TODO add test for br tags
