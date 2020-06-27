import 'package:quill_delta/quill_delta.dart';
import 'package:test/test.dart';
import 'package:notustohtml/notustohtml.dart';
import 'package:notus/notus.dart';
import 'package:meta/meta.dart';

void main() {
  final converter = NotusHtmlCodec();

  group('Encode', () {
    void compare(Delta delta, String expectedHtml) {
      // Asserts that the delta can be used to create a valid document
      NotusDocument.fromDelta(delta);
      final actualHtml = converter.encode(delta);
      expect(actualHtml, expectedHtml);
    }

    @isTest
    void testEncoder(String name, Delta delta, String expectedHtml) {
      test(name, () {
        compare(delta, expectedHtml);
      });
    }

    group('Basic text', () {
      testEncoder(
        'Plain paragraph',
        Delta()..insert('Hello World!\n'),
        '<p>Hello World!</p>',
      );
      test("Multi-line paragraph 1", () {
        final NotusDocument doc = NotusDocument.fromJson([
          {"insert": "Hello World!\nSecond line!\n"}
        ]);

        expect(
          converter.encode(doc.toDelta()),
          '<p>Hello World!</p><p>Second line!</p>',
        );
      });
      test("Multi-line paragraph 2", () {
        final NotusDocument doc = NotusDocument.fromJson([
          {"insert": "Hello World!\n\nSecond line!\n"}
        ]);

        expect(
          converter.encode(doc.toDelta()),
          '<p>Hello World!</p>' '<p><br></p>' '<p>Second line!</p>',
        );
      });

      test("Bold paragraph", () {
        final NotusDocument doc = NotusDocument.fromJson([
          {
            "insert": "Hello World!\n",
            "attributes": {"b": true}
          }
        ]);

        expect(
          converter.encode(doc.toDelta()),
          "<p><strong>Hello World!</strong></p>",
        );
      });

      test("Italic paragraph", () {
        final NotusDocument doc = NotusDocument.fromJson([
          {
            "insert": "Hello World!\n",
            "attributes": {"i": true}
          }
        ]);

        expect(converter.encode(doc.toDelta()), "<p><em>Hello World!</em></p>");
      });

      test("Bold and Italic paragraph", () {
        final NotusDocument doc = NotusDocument.fromJson([
          {
            "insert": "Hello World!\n",
            "attributes": {"i": true, "b": true}
          }
        ]);

        expect(
          converter.encode(doc.toDelta()),
          "<p><em><strong>Hello World!</strong></em></p>",
        );
      });
    });

    group('Headings', () {
      testEncoder(
        '1',
        Delta()..insert('Hello World!')..insert('\n', {'heading': 1}),
        '<h1>Hello World!</h1>',
      );

      testEncoder(
        '2',
        Delta()..insert('Hello World!')..insert('\n', {'heading': 2}),
        '<h2>Hello World!</h2>',
      );

      testEncoder(
        '3',
        Delta()..insert('Hello World!')..insert('\n', {'heading': 3}),
        '<h3>Hello World!</h3>',
      );

      testEncoder(
        'In list',
        Delta()
          ..insert('Hello World!')
          ..insert('\n', {'heading': 1, 'block': 'ul'}),
        '<ul><li><h1>Hello World!</h1></li></ul>',
      );
    });

    group('Blocks', () {
      test(
        "Quote",
        () {
          final NotusDocument doc = NotusDocument.fromJson([
            {"insert": "Hello World!"},
            {
              "insert": "\n",
              "attributes": {"block": "quote"}
            }
          ]);

          expect(converter.encode(doc.toDelta()),
              "<p><blockquote>Hello World!</blockquote></p>");
        },
        skip: true,
      );
      test(
        "Code",
        () {
          final NotusDocument doc = NotusDocument.fromJson([
            {"insert": "Hello World!"},
            {
              "insert": "\n",
              "attributes": {"block": "code"}
            }
          ]);

          expect(converter.encode(doc.toDelta()),
              "<p><code>Hello World!</code></p>");
        },
        skip: true,
      );
      test("Ordered list", () {
        final NotusDocument doc = NotusDocument.fromJson([
          {"insert": "Hello World!"},
          {
            "insert": "\n",
            "attributes": {"block": "ol"}
          }
        ]);

        expect(converter.encode(doc.toDelta()),
            "<p><ol><li>Hello World!</li></ol></p>");
      });
      test("List with bold", () {
        final NotusDocument doc = NotusDocument.fromJson([
          {
            "insert": "Hello World!",
            "attributes": {"b": true}
          },
          {
            "insert": "\n",
            "attributes": {"block": "ol"}
          }
        ]);

        expect(converter.encode(doc.toDelta()),
            "<p><ol><li><strong>Hello World!</strong></li></ol></p>");
      });
      test("Unordered list", () {
        final NotusDocument doc = NotusDocument.fromJson([
          {"insert": "Hello World!"},
          {
            "insert": "\n",
            "attributes": {"block": "ul"}
          },
          {"insert": "Hello World!"},
          {
            "insert": "\n",
            "attributes": {"block": "ul"}
          }
        ]);

        expect(converter.encode(doc.toDelta()),
            "<p><ul><li>Hello World!</li><li>Hello World!</li></ul></p>");
      });
    });

    group(
      'Embeds',
      () {
        test("Image", () {
          final NotusDocument doc = NotusDocument.fromJson([
            {
              "insert": "",
              "attributes": {
                "embed": {
                  "type": "image",
                  "source": "http://fake.link/image.png",
                },
              },
            },
            {"insert": "\n"}
          ]);

          expect(converter.encode(doc.toDelta()),
              '<p><img src="http://fake.link/image.png"></p>');
        });
        test("Horizontal rule", () {
          final NotusDocument doc = NotusDocument.fromJson([
            {
              "insert": "",
              "attributes": {
                "embed": {
                  "type": "hr",
                },
              },
            },
            {"insert": "\n"}
          ]);

          expect(converter.encode(doc.toDelta()), "<p><hr></p>");
        });
      },
      skip: true,
    );

    group(
      'Links',
      () {
        test("Plain", () {
          final delta = Delta()
            ..insert('Hello World!\n', {'a': 'http://fake.link'});

          expect(
            converter.encode(delta),
            '<p><a href="http://fake.link">Hello World!</a></p>',
          );
        });

        test("Italic", () {
          final delta = Delta()
            ..insert('Hello World!\n', {'a': 'http://fake.link', 'i': true});

          expect(
            converter.encode(delta),
            '<p><a href=\"http://fake.link\"><em>Hello World!</em></a></p>',
          );
        });

        test("In list", () {
          final delta = Delta()
            ..insert('Hello World!', {'a': 'http://fake.link'})
            ..insert('\n', {'block': 'ul'});

          expect(
            converter.encode(delta),
            '<p><ul><li><a href="http://fake.link">Hello World!</a></li></ul></p>',
          );
        });
      },
    );

    test('integration test', () {
      final Delta delta = Delta()
        ..insert('Plain text\n')
        ..insert('Bold text\n', {'b': true})
        ..insert('Italic text\n', {'i': true})
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

      final String html = '<p>Plain text</p>'
          '<p><strong>Bold text</strong></p>'
          '<p><em>Italic text</em></p>'
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

      compare(delta, html);
    });
  });

  group('Decode', () {
    void compare(String html, Delta expectedDelta) {
      // Asserts that the delta can be used to create a valid document
      NotusDocument.fromDelta(expectedDelta);
      final actualDelta = converter.decode(html);
      NotusDocument.fromDelta(actualDelta);
      expect(actualDelta, expectedDelta);
    }

    group('Basic text', () {
      test('Plain paragraph', () {
        final String html = "<p>Hello World!</p>";

        final delta = Delta()..insert('Hello World!\n');

        compare(html, delta);
      });

      test("Bold paragraph(strong)", () {
        final String html = "<p><strong>Hello World!</strong></p>";
        final NotusDocument expected = NotusDocument.fromJson([
          {
            "insert": "Hello World!\n",
            "attributes": {"b": true}
          }
        ]);
        final Delta result = converter.decode(html);

        expect(result, expected.toDelta());
      });

      test("Bold paragraph(b)", () {
        final String html = "<p><b>Hello World!</b></p>";
        final NotusDocument expected = NotusDocument.fromJson([
          {
            "insert": "Hello World!\n",
            "attributes": {"b": true}
          }
        ]);
        final Delta result = converter.decode(html);

        expect(result, expected.toDelta());
      });

      test("Italic paragraph(em)", () {
        final String html = "<p><em>Hello World!</em></p>";
        final NotusDocument doc = NotusDocument.fromJson([
          {
            "insert": "Hello World!\n",
            "attributes": {"i": true}
          }
        ]);

        expect(converter.decode(html), doc.toDelta());
      });
      test("Italic paragraph(i)", () {
        final String html = "<p><i>Hello World!</i></p>";
        final NotusDocument doc = NotusDocument.fromJson([
          {
            "insert": "Hello World!\n",
            "attributes": {"i": true}
          }
        ]);

        expect(converter.decode(html), doc.toDelta());
      });

      test("Bold and Italic paragraph", () {
        final String html =
            "<p><em><strong>Hello World!</strong></em> <i><b>How are you?</b></i></p>";
        final NotusDocument doc = NotusDocument.fromJson([
          {
            "insert": "Hello World!",
            "attributes": {"i": true, "b": true}
          },
          {"insert": " "},
          {
            "insert": "How are you?\n",
            "attributes": {"i": true, "b": true}
          },
        ]);

        expect(converter.decode(html), doc.toDelta());
      });

      test('Bold then Italic paragraph', () {
        final String html = '<p><strong>Hello</strong> <em>World</em></p>';
        final delta = Delta()
          ..insert('Hello', {'b': true})
          ..insert(' ')
          ..insert('World\n', {'i': true});

        compare(html, delta);
      });
    });

    group('multi-line text', () {
      test('two lines', () {
        final String html = '<p>Hello</p><p>World</p>';
        final delta = Delta()..insert('Hello\nWorld\n');

        compare(html, delta);
      });
      test('three lines', () {
        final String html = '<p>The</p><p>quick</p><p>brown</p>';
        final delta = Delta()..insert('The\nquick\nbrown\n');

        compare(html, delta);
      });

      test('empty line', () {
        final html = '<p><br></p>';
        final delta = Delta()..insert('\n\n');
        compare(html, delta);
      });
      test('two empty lines', () {
        final html = '<p><br></p><p><br></p>';
        final delta = Delta()..insert('\n\n\n');
        compare(html, delta);
      });
    });

    group('Headings', () {
      test("1", () {
        final String html = "<h1>Hello World!</h1>";
        final delta = Delta()
          ..insert('Hello World!')
          ..insert('\n', {'heading': 1});

        compare(html, delta);
      });

      test("2", () {
        final String html = "<h2>Hello World!</h2>";
        final delta = Delta()
          ..insert('Hello World!')
          ..insert('\n', {'heading': 2});

        compare(html, delta);
      });

      test("3", () {
        final String html = "<h3>Hello World!</h3>";
        final delta = Delta()
          ..insert('Hello World!')
          ..insert('\n', {'heading': 3});

        compare(html, delta);
      });
    });

    group('Blocks', () {
      test(
        "Quote",
        () {
          final String html = "<blockquote>Hello World!</blockquote>";

          final delta = Delta()
            ..insert('Hello World!')
            ..insert('\n', {'block': 'quote'});

          compare(html, delta);
        },
      );

      test(
        "Code",
        () {
          final String html = "<code>Hello World!</code>";
          final NotusDocument doc = NotusDocument.fromJson([
            {"insert": "Hello World!"},
            {
              "insert": "\n",
              "attributes": {"block": "code"}
            }
          ]);

          expect(converter.decode(html), doc.toDelta());
        },
      );
      test("Ordered list 1", () {
        final String html = '<p><ol><li>Hello World!</li></ol></p>';

        final delta = Delta()
          ..insert('Hello World!')
          ..insert('\n', {'block': 'ol'});

        compare(html, delta);
      });
      test("Ordered list 2", () {
        // Lists that don't start on the first line shouldn't be wrapped in p tags
        // TODO address this in the decoder
        final String html = '<p>Line 1</p>' '<ol><li>Hello World!</li></ol>';

        final delta = Delta()
          ..insert('Line 1\n')
          ..insert('Hello World!')
          ..insert('\n', {'block': 'ol'});

        compare(html, delta);
      });

      test("List with bold", () {
        final String html = "<ol><li><strong>Hello World!</strong></li></ol>";
        final NotusDocument doc = NotusDocument.fromJson([
          {
            "insert": "Hello World!",
            "attributes": {"b": true}
          },
          {
            "insert": "\n",
            "attributes": {"block": "ol"}
          }
        ]);

        expect(converter.decode(html), doc.toDelta());
      });
      test("Unordered list", () {
        final String html =
            "<ul><li>Hello World!</li><li>Hello World!</li></ul>";
        final NotusDocument doc = NotusDocument.fromJson([
          {"insert": "Hello World!"},
          {
            "insert": "\n",
            "attributes": {"block": "ul"}
          },
          {"insert": "Hello World!"},
          {
            "insert": "\n",
            "attributes": {"block": "ul"}
          }
        ]);

        expect(converter.decode(html), doc.toDelta());
      });
    });

    group('Embeds', () {
      test("Image", () {
        final String html = "<img src=\"http://fake.link/image.png\">";
        final delta = Delta()..insert("\n");
        NotusDocument tempdocument = NotusDocument.fromDelta(delta);
        var index = tempdocument.length;
        tempdocument.format(index - 1, 0,
            NotusAttribute.embed.image("http://fake.link/image.png"));
        final NotusDocument doc = tempdocument;

        expect(converter.decode(html), doc.toDelta());
      });
      test("Line", () {
        final String html = "<hr>";
        final delta = Delta()..insert("\n");
        NotusDocument tempdocument = NotusDocument.fromDelta(delta);
        var index = tempdocument.length;
        tempdocument.format(index - 1, 0, NotusAttribute.embed.horizontalRule);
        final NotusDocument doc = tempdocument;

        expect(converter.decode(html), doc.toDelta());
      });
    });

    group('Links', () {
      test("Plain", () {
        final String html = "<a href=\"http://fake.link\">Hello World!</a>";
        final NotusDocument doc = NotusDocument.fromJson([
          {
            "insert": "Hello World!",
            "attributes": {"a": "http://fake.link"},
          },
          {"insert": "\n"}
        ]);

        expect(converter.decode(html), doc.toDelta());
      });

      test("Italic", () {
        final String html =
            "<a href=\"http://fake.link\"><em>Hello World!</em></a>";
        final NotusDocument doc = NotusDocument.fromJson([
          {
            "insert": "Hello World!",
            "attributes": {"a": "http://fake.link", "i": true},
          },
          {"insert": "\n"}
        ]);

        expect(converter.decode(html), doc.toDelta());
      });

      test("In list", () {
        final String html =
            '<ul><li><a href="http://fake.link">Hello World!</a></li></ul>';
        final NotusDocument doc = NotusDocument.fromJson([
          {
            "insert": "Hello World!",
            "attributes": {"a": "http://fake.link"},
          },
          {
            "insert": "\n",
            "attributes": {"block": "ul"},
          }
        ]);

        expect(converter.decode(html), doc.toDelta());
      });
    });

    group('nested inline styles', () {
      test('bold in italic', () {
        final String html = '<p><em>Hello <strong>World!</strong></em></p>';
        final NotusDocument doc = NotusDocument.fromJson([
          {
            'insert': 'Hello ',
            'attributes': {'i': true},
          },
          {
            'insert': 'World!\n',
            'attributes': {'i': true, 'b': true},
          },
        ]);

        expect(converter.decode(html), doc.toDelta());
      });
      test('bold in italic 2', () {
        final String html = '<p><em>The <strong>quick</strong> brown</em></p>';
        final NotusDocument doc = NotusDocument.fromJson([
          {
            'insert': 'The ',
            'attributes': {'i': true},
          },
          {
            'insert': 'quick',
            'attributes': {'i': true, 'b': true},
          },
          {
            'insert': ' brown\n',
            'attributes': {'i': true},
          },
        ]);

        expect(converter.decode(html), doc.toDelta());
      });
      test('bold in italic 3', () {
        final String html =
            '<p><em>The <strong>quick</strong> <strong>brown</strong></em></p>';
        final NotusDocument doc = NotusDocument.fromJson([
          {
            'insert': 'The ',
            'attributes': {'i': true},
          },
          {
            'insert': 'quick',
            'attributes': {'i': true, 'b': true},
          },
          {
            'insert': ' ',
            'attributes': {'i': true},
          },
          {
            'insert': 'brown\n',
            'attributes': {'i': true, 'b': true},
          },
        ]);

        expect(converter.decode(html), doc.toDelta());
      });
    });

    test('integration test', () {
      final String html = '<p>Plain text</p>'
          '<p><strong>Bold text</strong></p>'
          '<p><em>Italic text</em></p>'
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

      compare(html, delta);
    });
  });
}

// TODO add test for br tags