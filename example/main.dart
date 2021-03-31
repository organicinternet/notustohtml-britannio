import 'package:notus/notus.dart';
import 'package:notustohtml/notustohtml.dart';
import 'package:quill_delta/quill_delta.dart';
import 'dart:convert';

void main() {
  final converter = NotusHtmlCodec();

  // Replace with the document you have take from the Zefyr editor
  /*
  final doc = NotusDocument.fromJson(
    [
      {"insert": "Zefyr"},
      {
        "insert": "\n",
        "attributes": {"heading": 1}
      },
      {
        "insert": "Soft and gentle rich text editing for Flutter applications.",
        "attributes": {"i": true}
      },
      {
        "insert": "\n",
        "attributes": {"alignment": "right"}
      },
      {
        "insert": "​",
        "attributes": {
          "embed": {"type": "image", "source": "asset://images/breeze.jpg"}
        }
      },
      {"insert": "\n"},
      {
        "insert": "Photo by Hiroyuki Takeda.",
        "attributes": {"i": true}
      },
      {"insert": "\nZefyr is currently in "},
      {
        "insert": "early preview",
        "attributes": {"b": true}
      },
      {
        "insert":
            ". If you have a feature request or found a bug, please file it at the "
      },
      {
        "insert": "issue tracker",
        "attributes": {"a": "https://github.com/memspace/zefyr/issues"}
      },
      {"insert": ".\nDocumentation"},
      {
        "insert": "\n",
        "attributes": {"heading": 3}
      },
      {
        "insert": "Quick Start",
        "attributes": {
          "a":
              "https://github.com/memspace/zefyr/blob/master/doc/quick_start.md"
        }
      },
      {
        "insert": "\n",
        "attributes": {"block": "ul"}
      },
      {
        "insert": "Data Format and Document Model",
        "attributes": {
          "a":
              "https://github.com/memspace/zefyr/blob/master/doc/data_and_document.md"
        }
      },
      {
        "insert": "\n",
        "attributes": {"block": "ul"}
      },
      {
        "insert": "Style Attributes",
        "attributes": {
          "a": "https://github.com/memspace/zefyr/blob/master/doc/attributes.md"
        }
      },
      {
        "insert": "\n",
        "attributes": {"block": "ul"}
      },
      {
        "insert": "Heuristic Rules",
        "attributes": {
          "a": "https://github.com/memspace/zefyr/blob/master/doc/heuristics.md"
        }
      },
      {
        "insert": "\n",
        "attributes": {"block": "ul"}
      },
      {
        "insert": "FAQ",
        "attributes": {
          "a": "https://github.com/memspace/zefyr/blob/master/doc/faq.md"
        }
      },
      {
        "insert": "\n",
        "attributes": {"block": "ul"}
      },
      {"insert": "Clean and modern look"},
      {
        "insert": "\n",
        "attributes": {"heading": 2}
      },
      {
        "insert":
            "Zefyr’s rich text editor is built with simplicity and flexibility in mind. It provides clean interface for distraction-free editing. Think Medium.com-like experience.\nMarkdown inspired semantics"
      },
      {
        "insert": "\n",
        "attributes": {"heading": 2}
      },
      {
        "insert":
            "Ever needed to have a heading line inside of a quote block, like this:\nI’m a Markdown heading"
      },
      {
        "insert": "\n",
        "attributes": {"block": "quote", "heading": 3}
      },
      {"insert": "And I’m a regular paragraph"},
      {
        "insert": "\n",
        "attributes": {"block": "quote"}
      },
      {"insert": "Code blocks"},
      {
        "insert": "\n",
        "attributes": {"heading": 2}
      },
      {"insert": "Of course:\nimport ‘package:flutter/material.dart’;"},
      {
        "insert": "\n",
        "attributes": {"block": "code"}
      },
      {"insert": "import ‘package:zefyr/zefyr.dart’;"},
      {
        "insert": "\n\n",
        "attributes": {"block": "code"}
      },
      {"insert": "void main() {"},
      {
        "insert": "\n",
        "attributes": {"block": "code"}
      },
      {"insert": " runApp(MyZefyrApp());"},
      {
        "insert": "\n",
        "attributes": {"block": "code"}
      },
      {"insert": "}"},
      {
        "insert": "\n",
        "attributes": {"block": "code"}
      },
      {"insert": "\n\n\n"}
    ],
  );

  String html = converter.encode(doc.toDelta());
  print(html); // The HTML representation of the Notus document

  Delta delta = converter.decode(html); // Zefyr compatible Delta
  // Notus document ready to be loaded into Zefyr
  NotusDocument document = NotusDocument.fromDelta(delta);
  String jsonString = json.encode(document.toDelta());
  print(jsonString);
  */

  // String htmlNotes =
  //     '<p><a href="https://www.google.com/">Google</a> <strong>This</strong> <em>is</em> <u>some</u> <s>body</s> <span style="color: rgb(230, 0, 0);">one</span> <span style="background-color: rgb(230, 0, 0);">text</span> <strong>with <em>a <u>variety </u><s><u>of</u></s><u> formatting</u> inside</em> it</strong>&nbsp;</p><p class="body-one"><img src="https://firebasestorage.googleapis.com/v0/b/creative-toolkit-development.appspot.com/o/cards%2Fj9I1mrGxQXYcvcRhfNy7%2Forganiclogosquare.png-1612632373778.png?alt=media&amp;token=4b4d9ac6-6e7a-46a9-a3d6-3a3870885011"></p><h1>Heading 1</h1><h2>&nbsp;&nbsp;Heading 2</h2><h3>&nbsp;&nbsp;Heading 3</h3><h1 class="lightheader-one">&nbsp;&nbsp;Light H1</h1><h2 class="lightheader-two">&nbsp;&nbsp;Light H2</h2><h3 class="lightheader-three">&nbsp;&nbsp;Light H3</h3><p class="body-one">&nbsp;&nbsp;Body 1</p><p>&nbsp;&nbsp;Body 2</p><p class="body-three">&nbsp;&nbsp;Body 3</p><p class="body-four">&nbsp;&nbsp;Body 4</p><p class="listed">&nbsp;&nbsp;Listed</p><blockquote>&nbsp;&nbsp;Blockquote</blockquote><ol><li>&nbsp;&nbsp;Numbered list</li></ol><ul><li>&nbsp;&nbsp;Bullet list</li></ul><p><span class="ql-font-1">Ql Font 1</span><span class="ql-font-10">Ql Font 10</span></p>';
  // String htmlNotes =
  //     '<h2>Review: The Goat or Who is Sylvia | YorkMix</h2><p class="">YorkMix</p><p class="">And all of this knowledge helps us to come to terms with Albee’s much later work, <strong><em><u>The Goat or Who</u></strong> is Sylvia</em> <strong>which</strong> premiered on Broadway in 2002 and now comes before us in a brand new <span style="color: rgb(255, 255, 0)"><strong><em><u><s>production</span></s></u></em></strong> by Pick Me Up Theatre at 41 Monkgate until Saturday 29 February.</p><p class=""><u>Test</u></p><p class="">This is some formatted text</p><p class="">Hello.</p><p class=""><u>Helios</u></p>';
  // String htmlNotes =
  //     '<p><strong class="ql-font-8">Busyness</strong><span class="ql-font-8"> is the most dangerous enemy of joy</span></p><p><br></p><p><strong class="ql-font-7">– Herman Hesse</strong></p>';
  // String htmlNotes =
  //     '<p><span class="ql-font-8"><strong>Busyness</strong> is the most dangerous enemy of joy</span></p><p><br></p><p><span class="ql-font-7"><strong>– Herman Hesse</strong></span></p>';
  // String htmlNotes =
  //     '<p><span class="ql-font-7">left</span></p><p class="ql-align-center"><span class="ql-font-7">center</span></p><p class="ql-align-right"><span class="ql-font-7">right</span></p><p class="ql-align-center"><span class="ql-font-7">center</span></p><p><span class="ql-font-7">left</span></p><p class="ql-align-justify"><br></p>';
  // String htmlNotes =
  //     '<p><span style="color: rgb(255, 255, 0); background-color: rgb(230, 0, 0);">This text is highlighted red with a yellow font. </span></p><p><span style="color: rgb(255, 255, 0);">And if I colour this text without a highlight, it removes the highlight above.</span></p>';
  // String htmlNotes =
  //     '<p class=""><span style="color: rgb(255, 255, 0)"><span style="background-color: rgb(230, 0, 0)">This text is highlighted red with a yellow font. </span></span></p><p class=""><span style="color: rgb(255, 255, 0)">And if I colour this text without a highlight, it removes the highlight above.</span></p>';
  // String htmlNotes =
  //     '<p class="body-one">Some body one nonsense.</p><p class="body-two">And some body two nonsense.</p>';
  // String htmlNotes =
  //     '<p class="">A card to try the padding on.</p><p class="">Does it have paragraph breaks?</p><p class="">Doesn’t look like it.</p><p class="">How about this one?</p><p class="">Nah, still not working!</p><p class="">Lovely space, but is is just a br?</p><p class="">Who knows!</p><p><br></p><p>I’m simply toooy</p><p>Yeah yeah yeah</p>';
  // String htmlNotes =
  //     '<p>paragraph</p><p><img src="https://crtvtk.imgix.net/https%3A%2F%2Ffirebasestorage.googleapis.com%2Fv0%2Fb%2Fcreative-toolkit-development.appspot.com%2Fo%2Fcards%252F8B3FsYUZZ9W7RHUyCv0X%252F2B9EA6BB000005783208613imagea71440407626370.jpg-1614267041350.jpg%3Falt%3Dmedia%26token%3D66eb69a3-5ef2-4060-a111-31dae4b9c2a5?dpr=1&amp;auto=compress&amp;s=dd5950ca32c29d1b1a779095ed6fdc61" data-imgixed="true"></p><p>another paragraph</p><p><img src="https://crtvtk.imgix.net/https%3A%2F%2Ffirebasestorage.googleapis.com%2Fv0%2Fb%2Fcreative-toolkit-development.appspot.com%2Fo%2Fcards%252F8B3FsYUZZ9W7RHUyCv0X%252F34FA4842000005783627487imagem21465224839004.jpg-1614267066379.jpg%3Falt%3Dmedia%26token%3D78e412a0-25ba-49c8-981c-6d63d2099374?dpr=1&amp;auto=compress&amp;s=818969189ec7ad1bedb4fd57e9255713" data-imgixed="true"></p><p>and anither</p><p><img src="https://firebasestorage.googleapis.com/v0/b/creative-toolkit-development.appspot.com/o/cards%2F8B3FsYUZZ9W7RHUyCv0X%2F3A0E3558000005783910306OneImguruserwiththeusernameihopethiscomesoffwittywalkedim791478445965905.jpg-1614267228677.jpg?alt=media&amp;token=bbb415ac-1a47-494f-ba2b-2ddcc265615d"></p>';
  // String htmlNotes =
  //     '<p><a href="https://www.google.com/">paragraph</a></p><p><a href="https://www.google.com/" target="_blank"><img src="https://crtvtk.imgix.net/image.png" data-imgixed="true"></a></p>';
  // String htmlNotes =
  //     '<p class="body-one">Body text 1</p><p>Body text 2</p><p class="body-three">Body text 3</p><p class="body-four">Body text 4</p><p><br></p><p class="body-one ql-align-center">Body text 1 centered</p><p class="ql-align-center">Body text 2 centered</p><p class="body-three ql-align-center">Body text 3 centered</p><p class="body-four ql-align-center">Body text 4 centered</p><p class="body-four"><br></p><p class="body-one"><a href="https://www.bbc.co.uk/" rel="noopener noreferrer" target="_blank">Body text 1 hyperlink</a></p><p><a href="https://www.bbc.co.uk/" rel="noopener noreferrer" target="_blank" style="color: rgb(86, 80, 101);">Body text 2 hyperlink</a></p><p class="body-three"><a href="https://www.bbc.co.uk/" rel="noopener noreferrer" target="_blank" style="color: rgb(86, 80, 101);">Body text 3 hyperlink</a></p><p class="body-four"><a href="https://www.bbc.co.uk/" rel="noopener noreferrer" target="_blank" style="color: rgb(86, 80, 101);">Body text 4 hyperlink</a></p><p><br></p><p class="body-one ql-align-center"><a href="https://www.bbc.co.uk" rel="noopener noreferrer" target="_blank">Body text 1 hyperlink centered</a></p><p class="ql-align-center"><a href="https://www.bbc.co.uk" rel="noopener noreferrer" target="_blank" style="color: rgb(230, 0, 0);">Body text 2 hyperlink centered</a></p><p class="body-three ql-align-center"><a href="https://www.bbc.co.uk" rel="noopener noreferrer" target="_blank" style="color: rgb(86, 80, 101);">Body text 3 hyperlink centered</a></p><p class="body-four ql-align-center"><a href="https://www.bbc.co.uk" rel="noopener noreferrer" target="_blank" style="color: rgb(86, 80, 101);">Body text 4 hyperlink centered</a></p><p class="ql-align-center"><br></p><h1 class="ql-align-center"><span style="color: rgb(86, 80, 101);">Heading 1 centered</span></h1><h2 class="ql-align-center"><span style="color: rgb(86, 80, 101);">Heading 2 centered</span></h2><h3 class="ql-align-center"><span style="color: rgb(86, 80, 101);">Heading 3 centered</span></h3><p class="ql-align-center"><br></p><h1 class="lightheader-one ql-align-center">Light heading 1 centered</h1><h2 class="lightheader-two ql-align-center"><span style="color: rgb(86, 80, 101);">Light heading 2 centered</span></h2><h3 class="lightheader-three ql-align-center"><span style="color: rgb(86, 80, 101);">Light heading 3 centered</span></h3><p><br></p><h1 class="ql-align-center"><a href="https://www.bbc.co.uk" rel="noopener noreferrer" target="_blank" style="color: rgb(86, 80, 101);">Heading 1 hyperlink centered</a></h1><h2 class="ql-align-center"><a href="https://www.bbc.co.uk" rel="noopener noreferrer" target="_blank" style="color: rgb(86, 80, 101);">Heading 2 hyperlink centered</a></h2><h3 class="ql-align-center"><a href="https://www.bbc.co.uk" rel="noopener noreferrer" target="_blank" style="color: rgb(86, 80, 101);">Heading 3 hyperlink centered</a></h3><p class="ql-align-center"><br></p><p class="ql-align-center"><br></p><h1 class="lightheader-one ql-align-center"><a href="https://www.bbc.co.uk" rel="noopener noreferrer" target="_blank" style="color: rgb(86, 80, 101);">Light heading 1 hyperlink centered</a></h1><h2 class="lightheader-two ql-align-center"><a href="https://www.bbc.co.uk" rel="noopener noreferrer" target="_blank" style="color: rgb(86, 80, 101);">Light heading 2 hyperlink centered</a></h2><h3 class="lightheader-three ql-align-center"><a href="https://www.bbc.co.uk" rel="noopener noreferrer" target="_blank" style="color: rgb(86, 80, 101);">Light heading 3 hyperlink centered</a></h3><p class="ql-align-center"><br></p><p><br></p><p><br></p><p><br></p>';
  // String htmlNotes =
  //     '<p><img src="https://firebasestorage.googleapis.com/v0/b/creative-toolkit-development.appspot.com/o/cards%2FtMOuFC1CX1JQN0MBZlKm%2Fimgtemp-1617177011662.jpg-1617177015766.jpg?alt=media&token=f0d3b8f3-ecab-4e2f-afae-05000af676cd"></p>';
  // String htmlNotes =
  //     '<p><a href="https://www.google.com"><img src="https://firebasestorage.googleapis.com/v0/b/creative-toolkit-development.appspot.com/o/cards%2FtMOuFC1CX1JQN0MBZlKm%2Fimgtemp-1617177011662.jpg-1617177015766.jpg?alt=media&token=f0d3b8f3-ecab-4e2f-afae-05000af676cd"></a></p>';
  String htmlNotes = '<h1>Test</h1>';
  Delta htmlNotesDelta = converter.decode(htmlNotes); // Zefyr compatible Delta
  NotusDocument htmlNotesDocument = NotusDocument.fromDelta(htmlNotesDelta);
  String htmlNotesJsonString = json.encode(htmlNotesDocument.toDelta());
  print(htmlNotesJsonString);

  final htmlNotesDecodedDoc =
      NotusDocument.fromJson(json.decode(htmlNotesJsonString));
  String htmlNptesDecodeHtml = converter.encode(htmlNotesDecodedDoc.toDelta());
  print(htmlNptesDecodeHtml); // The HTML representation of the Notus document

  // <p class="body-one"><strong>This</strong> <em>is</em> <u>some</u> <s>body</s> <span style="color: #e43f5a">one</span> <span style="background-color: #fdff38">text</span> <strong>with <em>a <u>variety <s>of</s> formatting</u> inside</em> it</strong> </p><p><img src="https://firebasestorage.googleapis.com/v0/b/creative-toolkit-development.appspot.com/o/cards%2Fj9I1mrGxQXYcvcRhfNy7%2Forganiclogosquare.png-1612632373778.png?alt=media&token=4b4d9ac6-6e7a-46a9-a3d6-3a3870885011"></p><h1>Heading 1</h1><h2>  Heading 2</h2><h3>  Heading 3</h3><h1 class="lightheader-one">  Light H1</h1><h2 class="lightheader-two">  Light H2</h2><h3 class="lightheader-three">  Light H3</h3><p class="body-one">  Body 1</p><p class="">  Body 2</p><p class="body-three">  Body 3</p><p class="body-four">  Body 4</p><p class="listed">  Listed</p><blockquote>  Blockquote</blockquote><ol><li>  Numbered list</li></ol><ul><li>  Bullet list</li></ul>
}
