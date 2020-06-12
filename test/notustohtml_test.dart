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
          r'<p>Hello World!<\p><p>Second line!<\p>',
        );
      });
      test("Multi-line paragraph 2", () {
        final NotusDocument doc = NotusDocument.fromJson([
          {"insert": "Hello World!\n\nSecond line!\n"}
        ]);

        expect(
          converter.encode(doc.toDelta()),
          r"<p>Hello World!<\p><p><br><\p><p>Second line!<\p>",
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
          "<strong>Hello World!</strong>",
        );
      });

      test("Italic paragraph", () {
        final NotusDocument doc = NotusDocument.fromJson([
          {
            "insert": "Hello World!\n",
            "attributes": {"i": true}
          }
        ]);

        expect(converter.encode(doc.toDelta()), "<em>Hello World!</em>");
      });

      test("Bold and Italic paragraph", () {
        final NotusDocument doc = NotusDocument.fromJson([
          {
            "insert": "Hello World!\n",
            "attributes": {"i": true, "b": true}
          }
        ]);

        expect(converter.encode(doc.toDelta()),
            "<em><strong>Hello World!</em></strong>");
      });
    });

    group('Headings', () {
      test("1", () {
        final NotusDocument doc = NotusDocument.fromJson([
          {"insert": "Hello World!"},
          {
            "insert": "\n",
            "attributes": {"heading": 1}
          }
        ]);

        expect(converter.encode(doc.toDelta()), "<h1>Hello World!</h1>");
      });

      test("2", () {
        final NotusDocument doc = NotusDocument.fromJson([
          {"insert": "Hello World!"},
          {
            "insert": "\n",
            "attributes": {"heading": 2}
          }
        ]);

        expect(converter.encode(doc.toDelta()), "<h2>Hello World!</h2>");
      });

      test("3", () {
        final NotusDocument doc = NotusDocument.fromJson([
          {"insert": "Hello World!"},
          {
            "insert": "\n",
            "attributes": {"heading": 3}
          }
        ]);

        expect(converter.encode(doc.toDelta()), "<h3>Hello World!</h3>");
      });

      test("In list", () {
        final NotusDocument doc = NotusDocument.fromJson([
          {"insert": "Hello World!"},
          {
            "insert": "\n",
            "attributes": {"block": "ul", "heading": 1},
          }
        ]);

        expect(converter.encode(doc.toDelta()),
            "<ul><li><h1>Hello World!</h1></li></ul>");
      });
    });

    group('Blocks', () {
      test("Quote", () {
        final NotusDocument doc = NotusDocument.fromJson([
          {"insert": "Hello World!"},
          {
            "insert": "\n",
            "attributes": {"block": "quote"}
          }
        ]);

        expect(converter.encode(doc.toDelta()),
            "<blockquote>Hello World!</blockquote>");
      });
      test("Code", () {
        final NotusDocument doc = NotusDocument.fromJson([
          {"insert": "Hello World!"},
          {
            "insert": "\n",
            "attributes": {"block": "code"}
          }
        ]);

        expect(converter.encode(doc.toDelta()), "<code>Hello World!</code>");
      });
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
            "<ol><li><strong>Hello World!</strong></li></ol>");
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
            "<ul><li>Hello World!</li><li>Hello World!</li></ul>");
      });
    });

    group('Embeds', () {
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
    });

    group('Links', () {
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
    });
  });

  group('Decode', () {
    group('Basic text', () {
      test('Plain paragraph', () {
        final String html = "Hello World!";
        final NotusDocument doc = NotusDocument.fromJson([
          {"insert": "Hello World!\n"}
        ]);

        expect(converter.decode(html), doc.toDelta());
      });

      test("Bold paragraph(strong)", () {
        final String html = "<strong>Hello World!</strong>";
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
        final String html = "<b>Hello World!</b>";
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
        final String html = "<em>Hello World!</em>";
        final NotusDocument doc = NotusDocument.fromJson([
          {
            "insert": "Hello World!\n",
            "attributes": {"i": true}
          }
        ]);

        expect(converter.decode(html), doc.toDelta());
      });
      test("Italic paragraph(i)", () {
        final String html = "<i>Hello World!</i>";
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
            "<em><strong>Hello World!</em></strong><i><b>How are you?</i></i>";
        final NotusDocument doc = NotusDocument.fromJson([
          {
            "insert": "Hello World!\n",
            "attributes": {"i": true, "b": true}
          }
        ]);

        expect(converter.decode(html), doc.toDelta());
      });
    });

    group('Headings', () {
      test("1", () {
        final String html = "<h1>Hello World!</h1>";
        final NotusDocument doc = NotusDocument.fromJson([
          {"insert": "Hello World!"},
          {
            "insert": "\n",
            "attributes": {"heading": 1}
          }
        ]);

        expect(converter.decode(html), doc.toDelta());
      });

      test("2", () {
        final String html = "<h2>Hello World!</h2>";
        final NotusDocument doc = NotusDocument.fromJson([
          {"insert": "Hello World!"},
          {
            "insert": "\n",
            "attributes": {"heading": 2}
          }
        ]);

        expect(converter.decode(html), doc.toDelta());
      });

      test("3", () {
        final String html = "<h3>Hello World!</h3>";
        final NotusDocument doc = NotusDocument.fromJson([
          {"insert": "Hello World!"},
          {
            "insert": "\n",
            "attributes": {"heading": 3}
          }
        ]);

        expect(converter.decode(html), doc.toDelta());
      });

      test("In list", () {
        final String html = "<ul><li><h1>Hello World!</h1></li></ul>";
        final NotusDocument doc = NotusDocument.fromJson([
          {"insert": "Hello World!"},
          {
            "insert": "\n",
            "attributes": {"block": "ul", "heading": 1},
          }
        ]);

        expect(converter.decode(html), doc.toDelta());
      });
    });

    group('Blocks', () {
      test("Quote", () {
        final String html = "<blockquote>Hello World!</blockquote>";
        final NotusDocument doc = NotusDocument.fromJson([
          {"insert": "Hello World!"},
          {
            "insert": "\n",
            "attributes": {"block": "quote"}
          }
        ]);

        expect(converter.decode(html), doc.toDelta());
      });
      test("Code", () {
        final String html = "<code>Hello World!</code>";
        final NotusDocument doc = NotusDocument.fromJson([
          {"insert": "Hello World!"},
          {
            "insert": "\n",
            "attributes": {"block": "code"}
          }
        ]);

        expect(converter.decode(html), doc.toDelta());
      });
      test("Ordered list", () {
        final String html = "<ol><li>Hello World!</li></ol>";
        final NotusDocument doc = NotusDocument.fromJson([
          {"insert": "Hello World!"},
          {
            "insert": "\n",
            "attributes": {"block": "ol"}
          }
        ]);

        expect(converter.decode(html), doc.toDelta());
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
  });
}
