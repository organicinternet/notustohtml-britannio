import 'package:quill_delta/quill_delta.dart';
import 'package:test/test.dart';
import 'package:notustohtml/notustohtml.dart';
import 'package:notus/notus.dart';

void main() {
  final converter = NotusHtmlCodec();

  group('Encode', () {
    group('Basic text', () {
      test("Plain paragraph", () {
        final NotusDocument doc = NotusDocument.fromJson([
          {"insert": "Hello World!\n"}
        ]);

        expect(converter.encode(doc.toDelta()), "<p>Hello World!</p>");
      });
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
          "<p>Hello World!</p><p><br></p><p>Second line!</p>",
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
      test("1", () {
        final NotusDocument doc = NotusDocument.fromJson([
          {
            "insert": "Hello World!\n",
            "attributes": {"heading": 1},
          }
        ]);

        expect(converter.encode(doc.toDelta()), "<p><h1>Hello World!</h1></p>");
      });

      test("2", () {
        final NotusDocument doc = NotusDocument.fromJson([
          {
            "insert": "Hello World!\n",
            "attributes": {"heading": 2}
          }
        ]);

        expect(converter.encode(doc.toDelta()), "<p><h2>Hello World!</h2></p>");
      });

      test("3", () {
        final NotusDocument doc = NotusDocument.fromJson([
          {
            "insert": "Hello World!\n",
            "attributes": {"heading": 3}
          },
        ]);

        expect(converter.encode(doc.toDelta()), "<p><h3>Hello World!</h3></p>");
      });

      test("In list", () {
        final NotusDocument doc = NotusDocument.fromJson([
          {
            "insert": "Hello World!",
            "attributes": {"heading": 1}
          },
          {
            "insert": "\n",
            "attributes": {"block": "ul"},
          }
        ]);

        expect(converter.encode(doc.toDelta()),
            "<p><ul><li><h1>Hello World!</h1></li></ul></p>");
      });
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

          expect(converter.encode(doc.toDelta()), "<code>Hello World!</code>");
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

        expect(
            converter.encode(doc.toDelta()), "<ol><li>Hello World!</li></ol>");
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
              "<img src=\"http://fake.link/image.png\">");
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

          expect(converter.encode(doc.toDelta()), "<hr>");
        });
      },
      skip: true,
    );

    group(
      'Links',
      () {
        test("Plain", () {
          final NotusDocument doc = NotusDocument.fromJson([
            {
              "insert": "Hello World!",
              "attributes": {"a": "http://fake.link"},
            },
            {"insert": "\n"}
          ]);

          expect(converter.encode(doc.toDelta()),
              r'<a href="http://fake.link">Hello World!</a>');
        });

        test("Italic", () {
          final NotusDocument doc = NotusDocument.fromJson([
            {
              "insert": "Hello World!",
              "attributes": {"a": "http://fake.link", "i": true},
            },
            {"insert": "\n"}
          ]);

          expect(converter.encode(doc.toDelta()),
              "<a href=\"http://fake.link\"><em>Hello World!</em></a>");
        });

        test("In list", () {
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

          expect(converter.encode(doc.toDelta()),
              "<ul><li><a href=\"http://fake.link\">Hello World!</a></li></ul>");
        });
      },
      skip: true,
    );
  });

  group('Decode', () {
    void compare(String html, Delta delta) {
      expect(converter.decode(html), delta);
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
            "<p><em><strong>Hello World!</strong></em><i><b>How are you?</b></i></p>";
        final NotusDocument doc = NotusDocument.fromJson([
          {
            "insert": "Hello World!",
            "attributes": {"i": true, "b": true}
          },
          {
            "insert": "How are you?\n",
            "attributes": {"i": true, "b": true}
          },
        ]);

        expect(converter.decode(html), doc.toDelta());
      });
    });

    group('multi-line text', () {
      test('plain', () {
        final String html = '<p>Hello</p><p>World</p>';
        final delta = Delta()..insert('Hello\nWorld\n');

        compare(html, delta);
      });
    });

    group('Headings', () {
      test("1", () {
        final String html = "<p><h1>Hello World!</h1></p>";
        final NotusDocument doc = NotusDocument.fromJson([
          {
            "insert": "Hello World!\n",
            "attributes": {"heading": 1}
          },
        ]);

        expect(converter.decode(html), doc.toDelta());
      });

      test("2", () {
        final String html = "<p><h2>Hello World!</h2></p>";
        final NotusDocument doc = NotusDocument.fromJson([
          {
            "insert": "Hello World!\n",
            "attributes": {"heading": 2}
          },
        ]);

        expect(converter.decode(html), doc.toDelta());
      });

      test("3", () {
        final String html = "<p><h3>Hello World!</h3></p>";
        final NotusDocument doc = NotusDocument.fromJson([
          {
            "insert": "Hello World!\n",
            "attributes": {"heading": 3}
          },
        ]);

        expect(converter.decode(html), doc.toDelta());
      });

      test("In list", () {
        final String html = "<p><ul><li><h1>Hello World!</h1></li></ul></p>";
        final NotusDocument doc = NotusDocument.fromJson([
          {
            "insert": "Hello World!",
            "attributes": {"heading": 1}
          },
          {
            "insert": "\n",
            "attributes": {"block": "ul"},
          }
        ]);

        expect(converter.decode(html), doc.toDelta());
      });
    });

    group('Blocks', () {
      test(
        "Quote",
        () {
          final String html = "<p><blockquote>Hello World!</blockquote></p>";
          final NotusDocument doc = NotusDocument.fromJson([
            {"insert": "Hello World!"},
            {
              "insert": "\n",
              "attributes": {"block": "quote"}
            }
          ]);

          expect(converter.decode(html), doc.toDelta());
        },
        skip: true,
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
        skip: true,
      );
      test("Ordered list", () {
        final String html = "<p><ol><li>Hello World!</li></ol></p>";

        final delta = Delta()
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
            "<ul><li><a href=\"http://fake.link\">Hello World!</a></li></ul>";
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
        final String html = '<em>Hello <strong>World!</strong></em>';
        final NotusDocument doc = NotusDocument.fromJson([
          {
            'insert': 'Hello ',
            'attributes': {'i': true},
          },
          {
            'insert': 'World\n',
            'attributes': {'i': true, 'b': true},
          },
        ]);

        expect(converter.decode(html), doc.toDelta());
      });
      test('bold in italic 2', () {
        final String html = '<em>The <strong>quick</strong> brown<em>';
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
            'insert': 'brown',
            'attributes': {'i': true},
          },
        ]);

        expect(converter.decode(html), doc.toDelta());
      });
      test('bold in italic 3', () {
        final String html =
            '<em>The <strong>quick</strong> <strong>brown</strong><em>';
        final NotusDocument doc = NotusDocument.fromJson([
          {
            'insert': 'The ',
            'attributes': {'i': true},
          },
          {
            'insert': 'Quick',
            'attributes': {'i': true, 'b': true},
          },
          {
            'insert': ' ',
            'attributes': {'i': true},
          },
          {
            'insert': 'Brown\n',
            'attributes': {'i': true, 'b': true},
          },
        ]);

        expect(converter.decode(html), doc.toDelta());
      });
    });
  });
}
