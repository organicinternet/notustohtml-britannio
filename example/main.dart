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
  // String htmlNotes =
  //     """<h2 class="lightheader-two"><strong>Example boxes</strong></h2><p>We've pulled together a few examples of Shoogleboxes other people have shared with us – and why they've told us they've found them invaluable:</p><p class="ql-align-center"><a href="https://www.home.shooglebox.com/examples/2n/post-pandemic-ways-of-working" rel="noopener noreferrer" target="_blank"><img src="https://crtvtk.imgix.net/https%3A%2F%2Ffirebasestorage.googleapis.com%2Fv0%2Fb%2Fcreative-toolkit-production.appspot.com%2Fo%2Fcards%252Fq7ISdimIOYDh2hKNfdqb%252Fpos1.jpg-1617105394905.jpg%3Falt%3Dmedia%26token%3D4db596e9-503c-4403-a78e-da99a80a081b?dpr=1&amp;auto=compress&amp;s=d4b1c8b333a02da474926186e6ecf102" width="188"></a> <a href="https://www.home.shooglebox.com/examples/2l/britain-50-years-ago%3A-a-look-back-at-1971" rel="noopener noreferrer" target="_blank"><img src="https://crtvtk.imgix.net/https%3A%2F%2Ffirebasestorage.googleapis.com%2Fv0%2Fb%2Fcreative-toolkit-production.appspot.com%2Fo%2Fcards%252Fq7ISdimIOYDh2hKNfdqb%252Fpost2.jpg-1617105459852.jpg%3Falt%3Dmedia%26token%3Df8610ea7-3cff-4bb6-aaf6-e46bfd8cdb70?dpr=1&amp;auto=compress&amp;s=c32b548ed8d7a64bafc7d099255d1ffd" width="188"></a> <a href="https://www.home.shooglebox.com/examples/2l/live-feed-tracking-mps-tweeting-about-the-bbc" rel="noopener noreferrer" target="_blank"><img src="https://crtvtk.imgix.net/https%3A%2F%2Ffirebasestorage.googleapis.com%2Fv0%2Fb%2Fcreative-toolkit-production.appspot.com%2Fo%2Fcards%252Fq7ISdimIOYDh2hKNfdqb%252Fpos3.jpg-1617105482113.jpg%3Falt%3Dmedia%26token%3D5d9d42da-237c-4fc7-934c-ecf7f95d0c4a?dpr=1&amp;auto=compress&amp;s=e0e30e292598dc46ddd09013be7a7891" width="188"></a></p><p class="ql-align-center"><a href="https://www.home.shooglebox.com/examples/2l/a-place-to-squirrel-away-random-inspiration" rel="noopener noreferrer" target="_blank"><img src="https://crtvtk.imgix.net/https%3A%2F%2Ffirebasestorage.googleapis.com%2Fv0%2Fb%2Fcreative-toolkit-production.appspot.com%2Fo%2Fcards%252Fq7ISdimIOYDh2hKNfdqb%252Fos4e.jpg-1617105953989.jpg%3Falt%3Dmedia%26token%3D323221a2-3f6d-4044-b98f-202990562074?dpr=1&amp;auto=compress&amp;s=2c4044065538657ccab502a5fb3004dc" width="190"></a> <a href="https://www.home.shooglebox.com/examples/3nf/directing-a-theatre-production" rel="noopener noreferrer" target="_blank"><img src="https://crtvtk.imgix.net/https%3A%2F%2Ffirebasestorage.googleapis.com%2Fv0%2Fb%2Fcreative-toolkit-production.appspot.com%2Fo%2Fcards%252Fq7ISdimIOYDh2hKNfdqb%252Fpos5c.jpg-1617105858224.jpg%3Falt%3Dmedia%26token%3D29dbfcae-8e65-4ef0-93f0-96f9d41a56e9?dpr=1&amp;auto=compress&amp;s=b632be141dd0f1f4a06f884a612ec18e" width="187"></a> <a href="https://www.home.shooglebox.com/examples/2l/first-recorded-use-of-new-words" rel="noopener noreferrer" target="_blank"><img src="https://crtvtk.imgix.net/https%3A%2F%2Ffirebasestorage.googleapis.com%2Fv0%2Fb%2Fcreative-toolkit-production.appspot.com%2Fo%2Fcards%252Fq7ISdimIOYDh2hKNfdqb%252Fpos6.jpg-1617105869865.jpg%3Falt%3Dmedia%26token%3Dcbef9f80-0812-428d-a0d8-99db0695c171?dpr=1&amp;auto=compress&amp;s=44c24f85ea5de4e6957bc2f49341bf20" width="188"></a></p><p class="ql-align-center"><a href="https://www.home.shooglebox.com/examples/4lf/tree-of-the-day-%E2%80%93-a-collection-of-photos" rel="noopener noreferrer" target="_blank"><img src="https://crtvtk.imgix.net/https%3A%2F%2Ffirebasestorage.googleapis.com%2Fv0%2Fb%2Fcreative-toolkit-production.appspot.com%2Fo%2Fcards%252Fq7ISdimIOYDh2hKNfdqb%252F5p.jpg-1617106605826.jpg%3Falt%3Dmedia%26token%3D144a1da7-2bf8-4e19-89ad-e78762c25b58?dpr=1&amp;auto=compress&amp;s=a2f7584905420c59fd7d26822a58dc9b" width="188"></a> <a href="https://www.home.shooglebox.com/examples/2l/remembering-games-we-used-to-play-on-the-c64" rel="noopener noreferrer" target="_blank"><img src="https://crtvtk.imgix.net/https%3A%2F%2Ffirebasestorage.googleapis.com%2Fv0%2Fb%2Fcreative-toolkit-production.appspot.com%2Fo%2Fcards%252Fq7ISdimIOYDh2hKNfdqb%252Fpos88.jpg-1617106263526.jpg%3Falt%3Dmedia%26token%3Dff45ab2b-e961-43e2-904e-0acc869a6a33?dpr=1&amp;auto=compress&amp;s=498cc6e403c3fe59a4a909243f120082" width="187"></a> <a href="https://www.home.shooglebox.com/examples/2n/customer-advocacy-on-social-media" rel="noopener noreferrer" target="_blank"><img src="https://crtvtk.imgix.net/https%3A%2F%2Ffirebasestorage.googleapis.com%2Fv0%2Fb%2Fcreative-toolkit-production.appspot.com%2Fo%2Fcards%252Fq7ISdimIOYDh2hKNfdqb%252Fp9.jpg-1617106282219.jpg%3Falt%3Dmedia%26token%3D4fd0d7bc-72d1-41b6-a495-cc125981ba53?dpr=1&amp;auto=compress&amp;s=7cf84ad36b5130746d7d064d99c89279" width="188"></a></p><p class="ql-align-center"><a href="https://home.shooglebox.com/examples" rel="noopener noreferrer" target="_blank"><img src="https://crtvtk.imgix.net/https%3A%2F%2Ffirebasestorage.googleapis.com%2Fv0%2Fb%2Fcreative-toolkit-production.appspot.com%2Fo%2Fcards%252Fq7ISdimIOYDh2hKNfdqb%252Fbuttonlink.jpg-1617107755261.jpg%3Falt%3Dmedia%26token%3D98cea22a-cfc0-4adb-926e-a8bd0baf8ead?dpr=1&amp;auto=compress&amp;s=0633b4a5d2c9523abcc84b9c56157fbe"></a></p><p><br></p>""";
  String htmlNotes =
      """<h1>Get the Shooglebox app for Apple and Android devices</h1><p>The Shooglebox app for Apple and Android devices makes it really quick and easy to pop things into Shooglebox whenever and wherever you come across them.</p><p><img src="https://crtvtk.imgix.net/https%3A%2F%2Ffirebasestorage.googleapis.com%2Fv0%2Fb%2Fcreative-toolkit-production.appspot.com%2Fo%2Fcards%252Fi0UeBRTkWRSymaGzAVkm%252FShoogleboxappv2.png-1616766547527.png%3Falt%3Dmedia%26token%3D4874be59-88da-40fb-a382-b217855b7738?dpr=1&amp;auto=compress&amp;s=af2244b685d053abbb0fd3bc245951e8"></p><p>Download the Shooglebox app for your <a href="https://itunes.apple.com/app/shooglebox/id1447397485" rel="noopener noreferrer" target="_blank">Apple</a> or <a href="https://play.google.com/store/apps/details?id=com.impmedia.shooglebox" rel="noopener noreferrer" target="_blank">Android</a> device:</p><p class="ql-align-center"><a href="https://itunes.apple.com/app/shooglebox/id1447397485" rel="noopener noreferrer" target="_blank"><img src="https://crtvtk.imgix.net/https%3A%2F%2Ffirebasestorage.googleapis.com%2Fv0%2Fb%2Fcreative-toolkit-production.appspot.com%2Fo%2Fcards%252Fi0UeBRTkWRSymaGzAVkm%252FAppleAppStore.jpeg-1617112045375.jpeg%3Falt%3Dmedia%26token%3De582a2f8-e099-4e5e-aa45-b0cfecf26da3?dpr=1&amp;auto=compress&amp;s=c837fe7df8998d59c58391a3dc3010d5" width="444" style=""></a></p><p class="ql-align-center"><a href="https://play.google.com/store/apps/details?id=com.impmedia.shooglebox" rel="noopener noreferrer" target="_blank"><img src="https://crtvtk.imgix.net/https%3A%2F%2Ffirebasestorage.googleapis.com%2Fv0%2Fb%2Fcreative-toolkit-production.appspot.com%2Fo%2Fcards%252Fi0UeBRTkWRSymaGzAVkm%252FGooglePlayStore.jpeg-1617112133753.jpeg%3Falt%3Dmedia%26token%3D9c2f0f3e-bb61-4aa4-873d-48e9c2068ac3?dpr=1&amp;auto=compress&amp;s=a82fa01699381e79893ee843869c137c" width="443" style=""></a></p><p>Once you've logged in to the Shooglebox app you can&nbsp;create new cards and save content direct from other apps including the camera, web browsers, photos, Facebook, Twitter, Instagram, YouTube, Notes and audio recorders.</p><h3>Setting up Shooglebox as a share destination on iPhone and iPad</h3><p>Before you can share web links, photos and other content directly into Shooglebox on an iOS device, you need to follow these quick steps to add it as one of your favourite destinations:</p><p><img src="https://crtvtk.imgix.net/https%3A%2F%2Ffirebasestorage.googleapis.com%2Fv0%2Fb%2Fcreative-toolkit-production.appspot.com%2Fo%2Fcards%252FackF8BU8KiJpNeNVrxQM%252Fsharing2.png-1596735499007.png%3Falt%3Dmedia%26token%3Dcc1b290d-89e0-44c7-b5f0-12a6dd206d69?dpr=1&amp;auto=compress&amp;s=43cd28e84f65e31a9c737c44e0977988"></p><ol><li>In an app like Photos or Safari, tap the share button – usually a box with an upward arrow – and scroll along the list of options until you see the&nbsp;<strong>More</strong>&nbsp;option.</li><li>Tap&nbsp;<strong>More</strong>&nbsp;and then click <strong>Edit</strong> on the top menu bar.</li><li>Scroll down to&nbsp;<strong>Shooglebox</strong>&nbsp;and press the green <strong>+ button</strong> next to Shooglebox. You can also drag Shooglebox further up the list of favourites so it appears sooner in the list when sharing.</li><li>Click <strong>Done</strong>. The next time you share an item from another app, Shooglebox will now appear in the list of options.</li></ol><h3>Sharing things from an Android device</h3><p>You can save things straight into Shooglebox from web browsers, the camera, Gallery and other apps on your Android device.</p><p>In most apps – such as&nbsp;Gallery, Facebook and Twitter – you'll see the&nbsp;<strong>Share</strong>&nbsp;icon next to the item you want to save. Tap on it and select&nbsp;<strong>Shooglebox</strong>&nbsp;from the list of options.</p><p>In some – including Chrome and Instagram – you'll need to tap the&nbsp;<strong>three-dot</strong>&nbsp;menu&nbsp;button&nbsp;in the top-right corner of the screen to access the&nbsp;<strong>Share</strong>&nbsp;feature.&nbsp;</p>""";
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
