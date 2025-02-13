import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:microsoft_viewer/data/alphabets.dart';
import 'package:microsoft_viewer/models/document.dart';
import 'package:microsoft_viewer/models/ms_image.dart';
import 'package:microsoft_viewer/models/ms_ss_table.dart';
import 'package:microsoft_viewer/models/ms_table.dart';
import 'package:microsoft_viewer/models/ms_text_span.dart';
import 'package:microsoft_viewer/models/paragraph.dart';
import 'package:microsoft_viewer/models/presentation.dart';
import 'package:microsoft_viewer/models/presentation_paragraph.dart';
import 'package:microsoft_viewer/models/presentation_shape.dart';
import 'package:microsoft_viewer/models/presentation_text.dart';
import 'package:microsoft_viewer/models/presentation_text_box.dart';
import 'package:microsoft_viewer/models/relationship.dart';
import 'package:microsoft_viewer/models/sheet.dart';
import 'package:microsoft_viewer/models/slide.dart';
import 'package:microsoft_viewer/models/spreadsheet.dart';
import 'package:microsoft_viewer/models/styles.dart';
import 'package:microsoft_viewer/models/word_page.dart';
import 'package:path_provider/path_provider.dart';
import 'package:xml/xml.dart' as xml;
import 'package:collection/collection.dart';
import 'models/shared_string.dart';

///The main dart file that takes the bytes data passed and then parses the files and displays the information.
class MicrosoftViewer extends StatefulWidget {
  final List<int> fileBytes;

  const MicrosoftViewer(this.fileBytes, {super.key});

  @override
  State<StatefulWidget> createState() => MicrosoftViewerState();
}

class MicrosoftViewerState extends State<MicrosoftViewer> {
  ZipDecoder? _zipDecoder;
  String wordOutputDirectory = "";
  String spreadSheetOutputDirectory = "";
  String presentationOutputDirectory = "";
  String fileType = "";
  late Archive archive;
  List<Relationship> relationShips = [];
  List<SharedString> sharedStrings = [];
  int elementDepth = 0;
  int seqNo = 0;
  Document wordDocument = Document("empty word document");
  Presentation presentation = Presentation("empty presentation document");
  SpreadSheet spreadSheet = SpreadSheet("empty spread sheet");
  WordPage currentPage = WordPage(1);
  List<Styles> stylesList = [];
  List<Widget> wordWidgets = [];
  List<Widget> spreadSheetWidgets = [];
  List<Widget> presentationWidgets = [];
  @override
  void initState() {
    parseAndShowData();
    super.initState();
  }

  Future<void> parseAndShowData() async {
    _zipDecoder ??= ZipDecoder();
    archive = _zipDecoder!.decodeBytes(widget.fileBytes);
    await setupDirectory();
    if (archive.any((archiveFile) {
      return archiveFile.name == 'word/document.xml';
    })) {
      fileType = "word";
    } else if (archive.any((archiveFile) {
      return archiveFile.name == 'xl/workbook.xml';
    })) {
      setState(() {
        fileType = "spreadsheet";
      });
    } else if (archive.any((archiveFile) {
      return archiveFile.name == 'ppt/presentation.xml';
    })) {
      setState(() {
        fileType = "presentation";
      });
    }
    if (fileType == "word") {
      wordDocument.pages.add(currentPage);
      var relFile = archive.singleWhere((archiveFile) {
        return archiveFile.name.endsWith("document.xml.rels");
      });
      getRelationships(relFile);
      var mediaFile = archive.where((archiveFile) {
        return archiveFile.name.startsWith('word/media/');
      });
      for (var medFile in mediaFile) {
        extractMedia(medFile, wordOutputDirectory);
      }
      var stylesFile = archive.singleWhere((archiveFile) {
        return archiveFile.name.endsWith("word/styles.xml");
      });
      processStylesFile(stylesFile);
      var wordFile = archive.singleWhere((archiveFile) {
        return archiveFile.name == 'word/document.xml';
      });
      processWordFile(wordFile);
      displayWordFile();
    } else if (fileType == "spreadsheet") {
      var relFile = archive.singleWhere((archiveFile) {
        return archiveFile.name.endsWith("workbook.xml.rels");
      });
      getRelationships(relFile);
      var shareStringsFile = archive.singleWhere((archiveFile) {
        return archiveFile.name.endsWith("sharedStrings.xml");
      });
      getSharedStrings(shareStringsFile);
      var workbookFile = archive.singleWhere((archiveFile) {
        return archiveFile.name.endsWith("xl/workbook.xml");
      });
      getSpreadSheetDetails(workbookFile);
      readAllSheets();
      displaySpreadSheet();
    } else if (fileType == "presentation") {
      var relFile = archive.singleWhere((archiveFile) {
        return archiveFile.name.endsWith("presentation.xml.rels");
      });
      getRelationships(relFile);
      var mediaFile = archive.where((archiveFile) {
        return archiveFile.name.startsWith('ppt/media/');
      });
      for (var medFile in mediaFile) {
        extractMedia(medFile, presentationOutputDirectory);
      }
      var presentationFile = archive.singleWhere((archiveFile) {
        return archiveFile.name.endsWith("ppt/presentation.xml");
      });
      getPresentationDetails(presentationFile);

      readAllSlides();
      displayPresentation();
    }
  }

  Future<void> setupDirectory() async {
    var applicationSupportDirectory = await getApplicationSupportDirectory();
    wordOutputDirectory = "${applicationSupportDirectory.path}/word/";
    spreadSheetOutputDirectory =
        "${applicationSupportDirectory.path}/spreadSheet/";
    presentationOutputDirectory =
        "${applicationSupportDirectory.path}/presentation/";
    var wordDir = Directory(wordOutputDirectory);
    if (wordDir.existsSync()) {
      wordDir.deleteSync(recursive: true);
    }
    wordDir.createSync(recursive: true);
    var xlsDir = Directory(spreadSheetOutputDirectory);
    if (xlsDir.existsSync()) {
      xlsDir.deleteSync(recursive: true);
    }
    xlsDir.createSync(recursive: true);
    var pptDir = Directory(presentationOutputDirectory);
    if (pptDir.existsSync()) {
      pptDir.deleteSync(recursive: true);
    }
    pptDir.createSync(recursive: true);
  }

  void getRelationships(ArchiveFile relFile) {
    final fileContent = utf8.decode(relFile.content);

    final document = xml.XmlDocument.parse(fileContent);
    final relationshipsElement = document.findAllElements("Relationship");
    relationShips = [];
    for (var rel in relationshipsElement) {
      if (rel.getAttribute("Id") != null) {
        relationShips.add(Relationship(rel.getAttribute("Id").toString(),
            rel.getAttribute("Target").toString()));
      }
    }
  }

  void getSharedStrings(ArchiveFile shareStringsFile) {
    final fileContent = utf8.decode(shareStringsFile.content);
    final document = xml.XmlDocument.parse(fileContent);
    sharedStrings = [];
    int index = 0;
    document.findAllElements('si').forEach((node) {
      sharedStrings
          .add(SharedString(index, node.getElement("t")?.innerText ?? ""));
      index++;
    });
  }

  Future<void> extractMedia(ArchiveFile mediaFile, String dirPath) async {
    final String outputFilePath = dirPath + mediaFile.name.split("/").last;
    final File outFile = File(outputFilePath);
    try {
      await outFile.writeAsBytes(mediaFile.content as List<int>);
    } on PathNotFoundException {}
  }

  void processWordFile(ArchiveFile wordFile) {
    final fileContent = utf8.decode(wordFile.content);
    final document = xml.XmlDocument.parse(fileContent);
    var chkBody = document.findAllElements("w:body");
    if (chkBody.isNotEmpty) {
      for (var childElements in chkBody.first.childElements) {
        processWordElements(childElements);
      }
    }
  }

  void processWordElements(xml.XmlElement wordElements) {
    if (wordElements.name.local == "tbl") {
      processWordTable(wordElements, elementDepth);
    } else if (wordElements.name.local == "p") {
      processParagraph(wordElements);
    }
  }

  void processParagraph(xml.XmlElement paragraphElement) {
    var pStyle = "";
    var chkPProperties = paragraphElement.findAllElements("w:pPr");
    Map<String, String> tabs = {};
    if (chkPProperties.isNotEmpty) {
      var chkPStyle = chkPProperties.first.findAllElements("w:pStyle");
      if (chkPStyle.isNotEmpty) {
        var tempPStyle = chkPStyle.first.getAttribute("w:val");
        if (tempPStyle != null) {
          pStyle = tempPStyle;
        }
      }
      var chkTabs = chkPProperties.first.findAllElements("w:tab");
      if (chkTabs.isNotEmpty) {
        var tempVal = chkTabs.first.getAttribute("w:val");
        if (tempVal != null) {
          tabs["val"] = tempVal;
        }
        var tempLeader = chkTabs.first.getAttribute("w:leader");
        if (tempLeader != null) {
          tabs["leader"] = tempLeader;
        }
      }
    }
    Paragraph paragraph = Paragraph(seqNo, pStyle);
    if (tabs.isNotEmpty) {
      paragraph.tabDetails = tabs;
    }
    seqNo++;
    int pSeqNo = 0;
    var runElements = paragraphElement.findAllElements("w:r");
    if (runElements.isNotEmpty) {
      for (var run in runElements) {
        List<String> formats = [];
        String tStyle = "";
        int fontSize = 0;
        String textColor = "";
        String highlightColor = "";
        Map<String, String> fonts = {};
        var runProperty = run.findAllElements("w:rPr");
        if (runProperty.isNotEmpty) {
          var boldProperty = runProperty.first.findAllElements("w:b");
          if (boldProperty.isNotEmpty) {
            formats.add("bold");
          }
          var italicProperty = runProperty.first.findAllElements("w:i");
          if (italicProperty.isNotEmpty) {
            formats.add("italic");
          }
          var underlineProperty = runProperty.first.findAllElements("w:u");
          if (underlineProperty.isNotEmpty) {
            if (underlineProperty.first.getAttribute("w:val") == "single") {
              formats.add("single-underline");
            } else if (underlineProperty.first.getAttribute("w:val") ==
                "double") {
              formats.add("double-underline");
            }
          }
          var strikeProperty = runProperty.first.findAllElements("w:strike");
          if (strikeProperty.isNotEmpty) {
            formats.add("strike");
          }
          var scriptProperty = runProperty.first.findAllElements("w:vertAlign");
          if (scriptProperty.isNotEmpty) {
            if (scriptProperty.first.getAttribute("w:val") == "superscript") {
              formats.add("superscript");
            } else if (scriptProperty.first.getAttribute("w:val") ==
                "subscript") {
              formats.add("subscript");
            }
          }
          var colorProperty = runProperty.first.findAllElements("w:color");
          if (colorProperty.isNotEmpty) {
            var tempTextColor = colorProperty.first.getAttribute("w:val");
            if (tempTextColor != null) {
              textColor = tempTextColor;
            }
          }
          var highlightColorProperty =
              runProperty.first.findAllElements("w:highlight");
          if (highlightColorProperty.isNotEmpty) {
            var tempHighlightColor =
                highlightColorProperty.first.getAttribute("w:val");
            if (tempHighlightColor != null) {
              highlightColor = tempHighlightColor;
            }
          }
          var styleProperty = runProperty.first.findAllElements("w:rStyle");
          if (styleProperty.isNotEmpty) {
            var tempStyle = styleProperty.first.getAttribute("w:val");
            if (tempStyle != null) {
              tStyle = tempStyle;
            }
          }
          var fontSizeProperty = runProperty.first.findAllElements("w:sz");
          if (fontSizeProperty.isNotEmpty) {
            var tempFontSize = fontSizeProperty.first.getAttribute("w:val");
            if (tempFontSize != null) {
              fontSize = int.parse(tempFontSize);
            }
          }
          var fontsProperty = runProperty.first.findAllElements("w:rFonts");
          if (fontsProperty.isNotEmpty) {
            var tempAscii = fontsProperty.first.getAttribute("w:ascii");
            if (tempAscii != null) {
              fonts["ascii"] = tempAscii;
            }
            var temphAnsi = fontsProperty.first.getAttribute("w:hAnsi");
            if (temphAnsi != null) {
              fonts["hAnsi"] = temphAnsi;
            }
          }
        }
        var textElements = run.findAllElements("w:t");
        if (textElements.isNotEmpty) {
          if (paragraph.tabDetails.isNotEmpty) {
            for (int i = 0; i < textElements.length; i++) {
              if (pSeqNo > 0) {
                paragraph.textSpans.add(MsTextSpan(
                    pSeqNo,
                    textElements.elementAt(i).innerText,
                    tStyle,
                    formats,
                    fontSize,
                    textColor,
                    highlightColor,
                    fonts));
                pSeqNo++;
              } else {
                String innerTex = textElements.elementAt(i).innerText;
                if (paragraph.tabDetails["leader"] == "dot") {
                  if (paragraph.tabDetails["val"] == "left") {
                    innerTex = "......................$innerTex";
                  } else {
                    innerTex = "$innerTex......................";
                  }
                } else if (paragraph.tabDetails["leader"] == "hyphen") {
                  if (paragraph.tabDetails["val"] == "left") {
                    innerTex = "--------------------$innerTex";
                  } else {
                    innerTex = "$innerTex--------------------";
                  }
                } else if (paragraph.tabDetails["leader"] == "space") {
                  if (paragraph.tabDetails["val"] == "left") {
                    innerTex = "                      $innerTex";
                  } else {
                    innerTex = "$innerTex                   ";
                  }
                }
                paragraph.textSpans.add(MsTextSpan(pSeqNo, innerTex, tStyle,
                    formats, fontSize, textColor, highlightColor, fonts));
                pSeqNo++;
              }
            }
          } else {
            for (var textE in textElements) {
              paragraph.textSpans.add(MsTextSpan(pSeqNo, textE.innerText,
                  tStyle, formats, fontSize, textColor, highlightColor, fonts));
              pSeqNo++;
            }
          }
        }
        var drawingElements = run.findAllElements("w:drawing");
        if (drawingElements.isNotEmpty) {
          for (var draw in drawingElements) {
            var imageBlip = draw.findAllElements("a:blip");
            if (imageBlip.isNotEmpty) {
              String imagePath = "";
              String imageType = "";
              int imgCX = 0;
              int imgCY = 0;
              var imageRid = imageBlip.first.getAttribute("r:embed");
              var imageRelation = relationShips.firstWhere((rel) {
                return rel.id == imageRid;
              });
              String imageName = imageRelation.target.split("/").last;
              imagePath = "$wordOutputDirectory/$imageName";
              var imageInline = draw.findAllElements("wp:inline");
              if (imageInline.isNotEmpty) {
                imageType = "inline";
                var imageExtent =
                    imageInline.first.findAllElements("wp:extent");
                if (imageExtent.isNotEmpty) {
                  var tempImageCX = imageExtent.first.getAttribute("cx");
                  if (tempImageCX != null) {
                    imgCX = int.parse(tempImageCX);
                  }
                  var tempImageCY = imageExtent.first.getAttribute("cy");
                  if (tempImageCY != null) {
                    imgCY = int.parse(tempImageCY);
                  }
                }
              }
              var imageAnchor = draw.findAllElements("wp:anchor");
              if (imageAnchor.isNotEmpty) {
                imageType = "anchor";
                var imageExtent =
                    imageAnchor.first.findAllElements("wp:extent");
                if (imageExtent.isNotEmpty) {
                  var tempImageCX = imageExtent.first.getAttribute("cx");
                  if (tempImageCX != null) {
                    imgCX = int.parse(tempImageCX);
                  }
                  var tempImageCY = imageExtent.first.getAttribute("cy");
                  if (tempImageCY != null) {
                    imgCY = int.parse(tempImageCY);
                  }
                }
              }
              paragraph.images
                  .add(MsImage(pSeqNo, imagePath, imageType, imgCX, imgCY));
              pSeqNo++;
            }
          }
        }
      }
    }
    bool newPage = false;
    for (var style in stylesList) {
      if (style.styleId == paragraph.style) {
        if (style.pageBreakBefore != null && style.pageBreakBefore == true) {
          newPage = true;
        }
      }
    }
    if (newPage) {
      WordPage wordPage = WordPage(wordDocument.pages.length + 1);
      wordDocument.pages.add(wordPage);
      currentPage = wordPage;
    }
    currentPage.components.add(paragraph);
  }

  void processWordTable(xml.XmlElement xmlElement, int elementDepth) {
    String tblStyle = "";
    String rightFromText = "";
    String bottomFromText = "";
    String vertAnchor = "";
    String tblpY = "";
    String tblWidth = "";
    String tblWType = "";
    String tblLook = "";
    var chkTblStyle = xmlElement.findAllElements("w:tblStyle");
    if (chkTblStyle.isNotEmpty) {
      var tempTblStyle = chkTblStyle.first.getAttribute("w:val");
      if (tempTblStyle != null) {
        tblStyle = tempTblStyle;
      }
    }
    var chkTblPr = xmlElement.findAllElements("w:tblpPr");
    if (chkTblPr.isNotEmpty) {
      var tempRightFromText = chkTblPr.first.getAttribute("w:rightFromText");
      if (tempRightFromText != null) {
        rightFromText = tempRightFromText;
      }
      var tempBottomFromText = chkTblPr.first.getAttribute("w:bottomFromText");
      if (tempBottomFromText != null) {
        bottomFromText = tempBottomFromText;
      }
      var tempVertAnchor = chkTblPr.first.getAttribute("w:vertAnchor");
      if (tempVertAnchor != null) {
        vertAnchor = tempVertAnchor;
      }
      var tempTblpY = chkTblPr.first.getAttribute("w:tblpY");
      if (tempTblpY != null) {
        tblpY = tempTblpY;
      }
    }
    var chkTblW = xmlElement.findAllElements("w:tblW");
    if (chkTblW.isNotEmpty) {
      var tempTblW = chkTblW.first.getAttribute("w:w");
      if (tempTblW != null) {
        tblWidth = tempTblW;
      }
      var tempWType = chkTblW.first.getAttribute("w:type");
      if (tempWType != null) {
        tblWType = tempWType;
      }
    }
    MsTable table = MsTable(seqNo, tblStyle, rightFromText, bottomFromText,
        vertAnchor, tblpY, tblWidth, tblWType, tblLook);
    seqNo++;
    final rows = xmlElement.findAllElements('w:tr');

    for (var row in rows) {
      bool isHeader = false;
      final chkCnfStyle = row.findAllElements("w:cnfStyle");
      if (chkCnfStyle.isNotEmpty) {
        var cnfStyleVal = chkCnfStyle.first.getAttribute("w:val");
        if (cnfStyleVal != null && cnfStyleVal.startsWith("10")) {
          isHeader = true;
        }
      }

      MsTableRow tableRow = MsTableRow(isHeader);
      final cells = row.findAllElements('w:tc');
      if (table.colNums != cells.length && table.colNums < cells.length) {
        table.colNums = cells.length;
      }

      for (var cell in cells) {
        int cellWidth = 0;
        final cellWidthElement = cell.findAllElements("w:tcW");
        if (cellWidthElement.isNotEmpty) {
          var tempCellWidth = cellWidthElement.first.getAttribute("w:w");
          if (tempCellWidth != null) {
            cellWidth = int.parse(tempCellWidth);
          }
        }
        final cellData = cell.findAllElements('w:t');
        String colText = "";
        for (var cellText in cellData) {
          colText += cellText.innerText;
        }
        MsTableCell tableCell = MsTableCell(colText, cellWidth);
        tableRow.cells.add(tableCell);
      }
      table.rows.add(tableRow);
    }
    currentPage.components.add(table);
  }

  void processStylesFile(ArchiveFile stylesFile) {
    stylesList = [];
    final fileContent = utf8.decode(stylesFile.content);
    final stylesDoc = xml.XmlDocument.parse(fileContent);
    var stylesRoot = stylesDoc.findAllElements("w:styles");
    if (stylesRoot.isNotEmpty) {
      var allStyles = stylesRoot.first.findAllElements("w:style");
      if (allStyles.isNotEmpty) {
        for (var style in allStyles) {
          String name = "";
          String type = "";
          String styleId = "";
          var tempType = style.getAttribute("w:type");
          if (tempType != null) {
            type = tempType;
          }
          var tempStyleId = style.getAttribute("w:styleId");
          if (tempStyleId != null) {
            styleId = tempStyleId;
          }
          var checkName = style.findAllElements("w:name");
          if (checkName.isNotEmpty) {
            var tempName = checkName.first.getAttribute("w:val");
            if (tempName != null) {
              name = tempName;
            }
          }

          Styles tempStyles = Styles(name, type, styleId);
          var checkParaProp = style.findAllElements("w:pPr");
          if (checkParaProp.isNotEmpty) {
            var indProp = checkParaProp.first.findAllElements("w:ind");
            if (indProp.isNotEmpty) {
              var tempFirstLine = indProp.first.getAttribute("w:firstLine");
              if (tempFirstLine != null) {
                tempStyles.firstLineInd = int.parse(tempFirstLine);
              }
            }
            var chkKeepNext = checkParaProp.first.findAllElements("w:keepNext");
            if (chkKeepNext.isNotEmpty) {
              tempStyles.keepNext = true;
            }
            var chkKeepLines =
                checkParaProp.first.findAllElements("w:keepLines");
            if (chkKeepLines.isNotEmpty) {
              tempStyles.keepLines = true;
            }
            var chkPageBreakBefore =
                checkParaProp.first.findAllElements("w:pageBreakBefore");
            if (chkPageBreakBefore.isNotEmpty) {
              tempStyles.pageBreakBefore = true;
            }
            var chkSpacing = checkParaProp.first.findAllElements("w:spacing");
            if (chkSpacing.isNotEmpty) {
              var tempBefore = chkSpacing.first.getAttribute("w:before");
              if (tempBefore != null) {
                tempStyles.spacingBefore = int.parse(tempBefore);
              }
              var tempAfter = chkSpacing.first.getAttribute("w:after");
              if (tempAfter != null) {
                tempStyles.spacingAfter = int.parse(tempAfter);
              }
            }
            var chkOutlineLvl =
                checkParaProp.first.findAllElements("w:outlineLvl");
            if (chkOutlineLvl.isNotEmpty) {
              var tempOutlineLvl = chkOutlineLvl.first.getAttribute("w:val");
              if (tempOutlineLvl != null) {
                tempStyles.outlineLvl = int.parse(tempOutlineLvl);
              }
            }
            var chkJc = checkParaProp.first.findAllElements("w:jc");
            if (chkJc.isNotEmpty) {
              var tempJc = chkJc.first.getAttribute("w:val");
              if (tempJc != null) {
                tempStyles.jc = tempJc;
              }
            }
          }
          var runProperty = style.findAllElements("w:rPr");
          if (runProperty.isNotEmpty) {
            var boldProperty = runProperty.first.findAllElements("w:b");
            if (boldProperty.isNotEmpty) {
              tempStyles.formats.add("bold");
            }
            var italicProperty = runProperty.first.findAllElements("w:i");
            if (italicProperty.isNotEmpty) {
              tempStyles.formats.add("italic");
            }
            var underlineProperty = runProperty.first.findAllElements("w:u");
            if (underlineProperty.isNotEmpty) {
              if (underlineProperty.first.getAttribute("w:val") == "single") {
                tempStyles.formats.add("single-underline");
              } else if (underlineProperty.first.getAttribute("w:val") ==
                  "double") {
                tempStyles.formats.add("double-underline");
              }
            }
            var strikeProperty = runProperty.first.findAllElements("w:strike");
            if (strikeProperty.isNotEmpty) {
              tempStyles.formats.add("strike");
            }
            var scriptProperty =
                runProperty.first.findAllElements("w:vertAlign");
            if (scriptProperty.isNotEmpty) {
              if (scriptProperty.first.getAttribute("w:val") == "superscript") {
                tempStyles.formats.add("superscript");
              } else if (scriptProperty.first.getAttribute("w:val") ==
                  "subscript") {
                tempStyles.formats.add("subscript");
              }
            }
            var colorProperty = runProperty.first.findAllElements("w:color");
            if (colorProperty.isNotEmpty) {
              var tempTextColor = colorProperty.first.getAttribute("w:val");
              if (tempTextColor != null) {
                tempStyles.textColor = tempTextColor;
              }
            }

            var fontSizeProperty = runProperty.first.findAllElements("w:sz");
            if (fontSizeProperty.isNotEmpty) {
              var tempFontSize = fontSizeProperty.first.getAttribute("w:val");
              if (tempFontSize != null) {
                tempStyles.fontSize = int.parse(tempFontSize);
              }
            }
            var fontsProperty = runProperty.first.findAllElements("w:rFonts");
            if (fontsProperty.isNotEmpty) {
              var tempAscii = fontsProperty.first.getAttribute("w:ascii");
              if (tempAscii != null) {
                tempStyles.fonts["ascii"] = tempAscii;
              }
              var temphAnsi = fontsProperty.first.getAttribute("w:hAnsi");
              if (temphAnsi != null) {
                tempStyles.fonts["hAnsi"] = temphAnsi;
              }
            }
          }
          var tableProp = style.findAllElements("w:tblPr");
          if (tableProp.isNotEmpty) {
            var borderProp = tableProp.first.findAllElements("w:tblBorders");
            if (borderProp.isNotEmpty) {
              Map<String, String> tempTableProp = {};
              var topPro = borderProp.first.findAllElements("w:top");
              if (topPro.isNotEmpty) {
                var topVal = topPro.first.getAttribute("w:val");
                if (topVal != null) {
                  tempTableProp["top-va"] = topVal;
                }
                var topSz = topPro.first.getAttribute("w:sz");
                if (topSz != null) {
                  tempTableProp["top-sz"] = topSz;
                }
                var topColor = topPro.first.getAttribute("w:color");
                if (topColor != null) {
                  tempTableProp["top-color"] = topColor;
                }
              }
              var leftPro = borderProp.first.findAllElements("w:left");
              if (leftPro.isNotEmpty) {
                var leftVal = leftPro.first.getAttribute("w:val");
                if (leftVal != null) {
                  tempTableProp["left-va"] = leftVal;
                }
                var leftSz = leftPro.first.getAttribute("w:sz");
                if (leftSz != null) {
                  tempTableProp["left-sz"] = leftSz;
                }
                var leftColor = leftPro.first.getAttribute("w:color");
                if (leftColor != null) {
                  tempTableProp["left-color"] = leftColor;
                }
              }
              var bottomPro = borderProp.first.findAllElements("w:top");
              if (bottomPro.isNotEmpty) {
                var bottomVal = bottomPro.first.getAttribute("w:val");
                if (bottomVal != null) {
                  tempTableProp["bottom-va"] = bottomVal;
                }
                var bottomSz = bottomPro.first.getAttribute("w:sz");
                if (bottomSz != null) {
                  tempTableProp["bottom-sz"] = bottomSz;
                }
                var bottomColor = bottomPro.first.getAttribute("w:color");
                if (bottomColor != null) {
                  tempTableProp["bottom-color"] = bottomColor;
                }
              }
              var rightPro = borderProp.first.findAllElements("w:top");
              if (rightPro.isNotEmpty) {
                var rightVal = rightPro.first.getAttribute("w:val");
                if (rightVal != null) {
                  tempTableProp["right-va"] = rightVal;
                }
                var rightSz = rightPro.first.getAttribute("w:sz");
                if (rightSz != null) {
                  tempTableProp["right-sz"] = rightSz;
                }
                var rightColor = rightPro.first.getAttribute("w:color");
                if (rightColor != null) {
                  tempTableProp["right-color"] = rightColor;
                }
              }
            }
          }
          stylesList.add(tempStyles);
        }
      }
    }
  }

  void displayWordFile() {
    if (fileType == "word") {
      List<Widget> tempList = [];
      for (int i = 0; i < wordDocument.pages.length; i++) {
        List<Widget> pageWidgets = [];
        for (int j = 0; j < wordDocument.pages[i].components.length; j++) {
          if (wordDocument.pages[i].components[j].runtimeType.toString() ==
              "Paragraph") {
            List<MsTextSpan> textSpans =
                wordDocument.pages[i].components[j].textSpans;
            List<MsImage> images = wordDocument.pages[i].components[j].images;
            List<InlineSpan> paragraphWidget = [];
            for (int k = 0; k < (textSpans.length + images.length); k++) {
              MsTextSpan? textSpan = textSpans.firstWhereOrNull((span) {
                return span.pSeqNo == k;
              });
              MsImage? image = images.firstWhereOrNull((img) {
                return img.pSeqNo == k;
              });
              if (textSpan != null) {
                paragraphWidget.add(getTextSpan(textSpan));
              }
              if (image != null) {
                paragraphWidget
                    .add(WidgetSpan(child: Image.file(File(image.imagePath))));
              }
            }
            pageWidgets.addAll(getRichText(
                wordDocument.pages[i].components[j], paragraphWidget));
          } else if (wordDocument.pages[i].components[j].runtimeType
                  .toString() ==
              "MsTable") {
            MsTable msTable = wordDocument.pages[i].components[j];
            List<TableRow> tableRows = [];
            Map<int, TableColumnWidth> columnWidths = {};
            for (int i = 0; i < msTable.colNums; i++) {
              columnWidths[i] = const FlexColumnWidth(1);
            }
            for (int i = 0; i < msTable.rows.length; i++) {
              List<String> cellText = [];
              for (int j = 0; j < msTable.colNums; j++) {
                if (j < msTable.rows[i].cells.length) {
                  cellText.add(msTable.rows[i].cells[j].cellText);
                } else {
                  cellText.add(" ");
                }
              }
              TableRow tableRow = TableRow(children: [
                for (int j = 0; j < cellText.length; j++) Text(cellText[j])
              ]);
              tableRows.add(tableRow);
            }
            Table table = Table(
              border: getRowBorder(msTable),
              columnWidths: columnWidths,
              children: tableRows,
            );
            pageWidgets.add(table);
          }
        }
        tempList.add(Container(
          color: Colors.white,
          margin: const EdgeInsets.all(8),
          child: Column(
            children: pageWidgets,
          ),
        ));
      }
      setState(() {
        wordWidgets = tempList;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
        constraints: const BoxConstraints.expand(),
        child: InteractiveViewer(
          scaleEnabled: false,
          child: Container(
            color: Colors.grey,
            child: SingleChildScrollView(
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: fileType == "word"
                  ? wordWidgets
                  : fileType == "spreadsheet"
                      ? spreadSheetWidgets
                      : presentationWidgets,
            )),
          ),
        ));
  }

  TextSpan getTextSpan(MsTextSpan textSpan) {
    TextStyle textStyle = const TextStyle();
    String tempSpanText = textSpan.text;

    if (textSpan.fontSize != 0) {
      textStyle = textStyle.copyWith(fontSize: textSpan.fontSize.toDouble());
    }
    if (textSpan.formats.contains("italic")) {
      textStyle = textStyle.copyWith(fontStyle: FontStyle.italic);
    }
    if (textSpan.formats.contains("bold")) {
      textStyle = textStyle.copyWith(fontWeight: FontWeight.bold);
    }
    if (textSpan.formats.contains("single-underline")) {
      textStyle = textStyle.copyWith(decoration: TextDecoration.underline);
    }
    if (textSpan.formats.contains("double-underline")) {
      textStyle = textStyle.copyWith(
          decoration: TextDecoration.underline,
          decorationStyle: TextDecorationStyle.double);
    }
    if (textSpan.formats.contains("strike")) {
      textStyle = textStyle.copyWith(decoration: TextDecoration.lineThrough);
    }
    if (textSpan.formats.contains("subscript")) {
      textStyle =
          textStyle.copyWith(fontFeatures: [const FontFeature.subscripts()]);
    }
    if (textSpan.textColor.isNotEmpty && textSpan.textColor != "auto") {
      Color selectedColor =
          Color(int.parse("FF${textSpan.textColor}", radix: 16));

      textStyle = textStyle.copyWith(color: selectedColor);
    }
    if (textSpan.fonts.isNotEmpty) {
      textStyle = textStyle.copyWith(fontFamily: textSpan.fonts["ascii"]);
    }
    TextSpan textSpanRet = TextSpan(text: tempSpanText, style: textStyle);

    return textSpanRet;
  }

  List<Widget> getRichText(
      Paragraph paragraph, List<InlineSpan> paragraphWidget) {
    TextStyle textStyle = const TextStyle();
    String jc = "";
    String indentText = "";
    List<Widget> pageWidgets = [];
    int spaceBefore = 0;
    int spaceAfter = 0;
    if (paragraph.style.isNotEmpty) {
      Styles? paraStyles = stylesList.firstWhereOrNull((style) {
        return style.styleId == paragraph.style;
      });
      if (paraStyles != null) {
        if (paraStyles.fontSize != 0) {
          textStyle =
              textStyle.copyWith(fontSize: paraStyles.fontSize.toDouble());
        }
        if (paraStyles.formats.contains("italic")) {
          textStyle = textStyle.copyWith(fontStyle: FontStyle.italic);
        }
        if (paraStyles.formats.contains("bold")) {
          textStyle = textStyle.copyWith(fontWeight: FontWeight.bold);
        }
        if (paraStyles.formats.contains("single-underline")) {
          textStyle = textStyle.copyWith(decoration: TextDecoration.underline);
        }
        if (paraStyles.formats.contains("double-underline")) {
          textStyle = textStyle.copyWith(
              decoration: TextDecoration.underline,
              decorationStyle: TextDecorationStyle.double);
        }
        if (paraStyles.formats.contains("strike")) {
          textStyle =
              textStyle.copyWith(decoration: TextDecoration.lineThrough);
        }
        if (paraStyles.formats.contains("subscript")) {
          textStyle = textStyle
              .copyWith(fontFeatures: [const FontFeature.subscripts()]);
        }
        if (paraStyles.textColor != null && paraStyles.textColor != "auto") {
          Color selectedColor =
              Color(int.parse("FF${paraStyles.textColor!}", radix: 16));

          textStyle = textStyle.copyWith(color: selectedColor);
        } else {
          textStyle = textStyle.copyWith(color: Colors.black);
        }
        if (paraStyles.fonts.isNotEmpty) {
          textStyle = textStyle.copyWith(fontFamily: paraStyles.fonts["ascii"]);
        }
        if (paraStyles.jc != null && paraStyles.jc!.isNotEmpty) {
          jc = paraStyles.jc!;
        }
        if (paraStyles.firstLineInd != 0) {
          for (int i = 0; i < paraStyles.firstLineInd / 10; i++) {
            indentText += " ";
          }
        }
        if (paraStyles.spacingBefore != 0) {
          spaceBefore = paraStyles.spacingBefore;
        }
        if (paraStyles.spacingAfter != 0) {
          spaceAfter = paraStyles.spacingAfter;
        }
        if (paraStyles.styleId == "ListParagraph") {
          indentText = "\u2022 $indentText";
        }
      }
    } else {
      textStyle = textStyle.copyWith(color: Colors.black);
    }

    RichText richText = RichText(
      text: TextSpan(
          text: indentText, style: textStyle, children: paragraphWidget),
      textAlign: TextAlign.start,
    );

    switch (jc) {
      case "center":
        richText = RichText(
          text: TextSpan(
              text: indentText, style: textStyle, children: paragraphWidget),
          textAlign: TextAlign.center,
        );
        break;
    }
    if (spaceBefore != 0) {
      pageWidgets.add(SizedBox(
        height: spaceBefore.toDouble() / 10,
      ));
    }
    pageWidgets.add(richText);
    if (spaceAfter != 0) {
      pageWidgets.add(SizedBox(
        height: spaceAfter.toDouble() / 10,
      ));
    }
    return pageWidgets;
  }

  TableBorder getRowBorder(MsTable msTable) {
    BorderSide topBorder = const BorderSide();
    BorderSide leftBorder = const BorderSide();
    BorderSide bottomBorder = const BorderSide();
    BorderSide rightBorder = const BorderSide();
    if (msTable.tblStyle.isNotEmpty) {
      Styles? tableStyles = stylesList.firstWhereOrNull((style) {
        return style.styleId == msTable.tblStyle;
      });
      if (tableStyles != null) {
        if (tableStyles.tableBorder.isNotEmpty) {
          if (tableStyles.tableBorder["top-val"] != null) {
            topBorder = topBorder.copyWith(style: BorderStyle.solid);
          }
          if (tableStyles.tableBorder["top-sz"] != null) {
            topBorder = topBorder.copyWith(
                width:
                    double.parse(tableStyles.tableBorder["top-sz"].toString()));
          }
          if (tableStyles.tableBorder["top-color"] != null) {
            topBorder = topBorder.copyWith(
                color: Color(int.parse(
                    "FF${tableStyles.tableBorder["top-color"]}",
                    radix: 16)));
          }

          if (tableStyles.tableBorder["left-val"] != null) {
            leftBorder = leftBorder.copyWith(style: BorderStyle.solid);
          }
          if (tableStyles.tableBorder["left-sz"] != null) {
            leftBorder = leftBorder.copyWith(
                width: double.parse(
                    tableStyles.tableBorder["left-sz"].toString()));
          }
          if (tableStyles.tableBorder["left-color"] != null) {
            leftBorder = leftBorder.copyWith(
                color: Color(int.parse(
                    "FF${tableStyles.tableBorder["left-color"]}",
                    radix: 16)));
          }

          if (tableStyles.tableBorder["bottom-val"] != null) {
            bottomBorder = bottomBorder.copyWith(style: BorderStyle.solid);
          }
          if (tableStyles.tableBorder["bottom-sz"] != null) {
            bottomBorder = bottomBorder.copyWith(
                width: double.parse(
                    tableStyles.tableBorder["bottom-sz"].toString()));
          }
          if (tableStyles.tableBorder["bottom-color"] != null) {
            bottomBorder = bottomBorder.copyWith(
                color: Color(int.parse(
                    "FF${tableStyles.tableBorder["bottom-color"]}",
                    radix: 16)));
          }

          if (tableStyles.tableBorder["right-val"] != null) {
            rightBorder = rightBorder.copyWith(style: BorderStyle.solid);
          }
          if (tableStyles.tableBorder["right-sz"] != null) {
            rightBorder = rightBorder.copyWith(
                width: double.parse(
                    tableStyles.tableBorder["right-sz"].toString()));
          }
          if (tableStyles.tableBorder["right-color"] != null) {
            rightBorder = rightBorder.copyWith(
                color: Color(int.parse(
                    "FF${tableStyles.tableBorder["right-color"]}",
                    radix: 16)));
          }
        }
      }
    }
    TableBorder tableBorder = TableBorder(
        top: topBorder,
        left: leftBorder,
        bottom: bottomBorder,
        right: rightBorder);
    return tableBorder;
  }

  void getSpreadSheetDetails(ArchiveFile workbookFile) {
    final fileContent = utf8.decode(workbookFile.content);
    final workbookDoc = xml.XmlDocument.parse(fileContent);
    var sheetsRoot = workbookDoc.findAllElements("sheets");
    if (sheetsRoot.isNotEmpty) {
      var allSheets = sheetsRoot.first.findAllElements("sheet");
      if (allSheets.isNotEmpty) {
        for (var sheets in allSheets) {
          String sName = "";
          String sId = "";
          String rId = "";
          var tempName = sheets.getAttribute("name");
          if (tempName != null) {
            sName = tempName;
          }
          var tempId = sheets.getAttribute("sheetId");
          if (tempId != null) {
            sId = tempId;
          }
          var tempRId = sheets.getAttribute("r:id");
          if (tempRId != null) {
            rId = tempRId;
          }
          spreadSheet.sheets.add(Sheet(sName, sId, rId));
        }
      }
    }
  }

  void readAllSheets() {
    for (int i = 0; i < spreadSheet.sheets.length; i++) {
      var sheetRelation = relationShips.firstWhereOrNull((rel) {
        return rel.id == spreadSheet.sheets[i].rId;
      });
      if (sheetRelation != null) {
        var sheetFile = archive.singleWhere((archiveFile) {
          return archiveFile.name.endsWith(sheetRelation.target);
        });
        if (sheetFile.isFile) {
          final fileContent = utf8.decode(sheetFile.content);
          final workbookDoc = xml.XmlDocument.parse(fileContent);
          MsSsTable table = MsSsTable();
          var cols = workbookDoc.findAllElements("cols");
          if (cols.isNotEmpty) {
            var col = cols.first.findAllElements("col");
            if (col.isNotEmpty) {
              List<MsSsCol> colList = [];
              for (var tempCol in col) {
                int min = 0;
                int max = 0;
                double width = 0;
                int customWidth = 0;
                var tempMin = tempCol.getAttribute("min");
                if (tempMin != null) {
                  min = int.parse(tempMin);
                }
                var tempMax = tempCol.getAttribute("max");
                if (tempMax != null) {
                  max = int.parse(tempMax);
                }
                var tempWidth = tempCol.getAttribute("width");
                if (tempWidth != null) {
                  width = double.parse(tempWidth);
                }
                var tempCustWidth = tempCol.getAttribute("customWidth");
                if (tempCustWidth != null) {
                  customWidth = int.parse(tempCustWidth);
                }
                colList.add(MsSsCol(min, max, width, customWidth));
              }
              table.cols.addAll(colList);
            }
          }
          var sheetData = workbookDoc.findAllElements("sheetData");
          if (sheetData.isNotEmpty) {
            var rows = sheetData.first.findAllElements("row");
            List<MsSsRow> rowList = [];
            if (rows.isNotEmpty) {
              for (var row in rows) {
                int rowId = 0;
                String spans = "";
                double height = 0;
                var tempRowId = row.getAttribute("r");
                if (tempRowId != null) {
                  rowId = int.parse(tempRowId);
                }
                var tempSpans = row.getAttribute("spans");
                if (tempSpans != null) {
                  spans = tempSpans;
                }
                var tempHeight = row.getAttribute("ht");
                if (tempHeight != null) {
                  height = double.parse(tempHeight);
                }
                MsSsRow msSsRow = MsSsRow(rowId, spans, height);
                var cells = row.findAllElements("c");
                if (cells.isNotEmpty) {
                  List<MsSsCell> msCells = [];
                  for (var cell in cells) {
                    int colNo = 0;
                    String type = "";
                    String value = "";
                    var tempColNo = cell.getAttribute("r");
                    if (tempColNo != null) {
                      colNo = getCellColNo(tempColNo, rowId);
                    }
                    var tempType = cell.getAttribute("t");
                    if (tempType != null) {
                      type = tempType;
                    }
                    var tempValue = cell.findAllElements("v");
                    if (tempValue.isNotEmpty) {
                      value = tempValue.first.innerText;
                    }
                    msCells.add(MsSsCell(colNo, type, value));
                  }
                  msSsRow.cells.addAll(msCells);
                }
                rowList.add(msSsRow);
              }
            }
            table.rows.addAll(rowList);
          }
          spreadSheet.sheets[i].tables.add(table);
        }
      }
    }
  }

  int getCellColNo(String colNoStr, int rowId) {
    int colNo = 0;
    String colNoOnlyStr = colNoStr.replaceAll(rowId.toString(), "");

    for (int i = 0; i < colNoOnlyStr.length; i++) {
      if (i == colNoOnlyStr.length - 1) {
        colNo = colNo + Alphabet.alphabets.indexOf(colNoOnlyStr[i]) + 1;
      } else {
        colNo =
            colNo + ((Alphabet.alphabets.indexOf(colNoOnlyStr[i]) + 1) * 26);
      }
    }

    return colNo;
  }

  void displaySpreadSheet() {
    List<Widget> tempList = [];
    List<Widget> sheetWidgets = [];
    for (int i = 0; i < spreadSheet.sheets.length; i++) {
      sheetWidgets.add(Text(spreadSheet.sheets[i].name));
      String htmlString = "<html><body>";
      for (int j = 0; j < spreadSheet.sheets[i].tables.length; j++) {
        htmlString =
            "$htmlString<table style='border: 3px solid black; border-collapse: collapse;'>";
        for (int k = 0; k < spreadSheet.sheets[i].tables[j].rows.length; k++) {
          htmlString =
              "$htmlString<tr height=${spreadSheet.sheets[i].tables[j].rows[k].height}px>";
          String colSpan = "0";
          bool rowStarted = false;
          for (int l = 0;
              l < spreadSheet.sheets[i].tables[j].rows[k].cells.length;
              l++) {
            if (l < spreadSheet.sheets[i].tables[j].rows[k].cells.length - 1) {
              if (spreadSheet.sheets[i].tables[j].rows[k].cells[l + 1].colNo !=
                  spreadSheet.sheets[i].tables[j].rows[k].cells[l].colNo + 1) {
                colSpan = (spreadSheet
                            .sheets[i].tables[j].rows[k].cells[l + 1].colNo -
                        spreadSheet.sheets[i].tables[j].rows[k].cells[l].colNo)
                    .toString();
              }
            } else {
              int totalCols = int.parse(
                  spreadSheet.sheets[i].tables[j].rows[k].spans.split(":")[1]);
              if (spreadSheet.sheets[i].tables[j].rows[k].cells[l].colNo !=
                  totalCols) {
                colSpan = (totalCols -
                        spreadSheet.sheets[i].tables[j].rows[k].cells[l].colNo)
                    .toString();
              }
            }
            if (!rowStarted &&
                spreadSheet.sheets[i].tables[j].rows[k].cells[l].colNo != 1) {
              for (int blanki = 1;
                  blanki <
                      spreadSheet.sheets[i].tables[j].rows[k].cells[l].colNo;
                  blanki++) {
                htmlString = "$htmlString<td> </td>";
              }
            }
            htmlString =
                "$htmlString<td style='border: 3px solid black; border-collapse: collapse;' colSpan=$colSpan>";
            htmlString = htmlString +
                getCellValue(spreadSheet.sheets[i].tables[j].rows[k].cells[l]);
            htmlString = "$htmlString</td>";
            rowStarted = true;
          }
          if (spreadSheet.sheets[i].tables[j].rows[k].cells.isEmpty) {
            htmlString = "$htmlString<td> </td>";
          }

          htmlString = "$htmlString</tr>";
        }

        htmlString = "$htmlString</table>";
      }

      htmlString = '$htmlString</body></html>';
      sheetWidgets.add(
        Container(
            color: Colors.white,
            child: SingleChildScrollView(child: HtmlWidget(htmlString))),
      );
    }

    tempList.add(
      Container(color: Colors.grey, child: Column(children: sheetWidgets)),
    );
    setState(() {
      spreadSheetWidgets = tempList;
    });
  }

  String getCellValue(MsSsCell cell) {
    String value = "";
    switch (cell.type) {
      // sharedString
      case 's':
        var sharedString = sharedStrings.firstWhereOrNull((sharedString) {
          return sharedString.index == int.parse(cell.value);
        });
        if (sharedString != null) {
          value = sharedString.text;
        }
        break;
      // boolean
      case 'b':
        value = cell.value == '1' ? "true" : "false";
        break;
      // error
      case 'e':
      // formula
      case 'str':
        value = cell.value;
        break;
      // inline string
      case 'inlineStr':
        value = cell.value;
        break;
      // number
      case 'n':
      default:
        value = cell.value;
    }
    return value;
  }

  void getPresentationDetails(ArchiveFile presentationFile) {
    final fileContent = utf8.decode(presentationFile.content);
    final presentationDoc = xml.XmlDocument.parse(fileContent);
    var slidesRoot = presentationDoc.findAllElements("p:sldIdLst");
    if (slidesRoot.isNotEmpty) {
      var slides = slidesRoot.first.findAllElements("p:sldId");
      if (slides.isNotEmpty) {
        for (var slide in slides) {
          int id = 0;
          String rId = "";
          var tempId = slide.getAttribute("id");
          if (tempId != null) {
            id = int.parse(tempId);
          }
          var tempRid = slide.getAttribute("r:id");
          if (tempRid != null) {
            rId = tempRid;
          }
          presentation.slides.add(Slide(id, rId, ""));
        }
      }
    }
    var masterSlidesRoot = presentationDoc.findAllElements("p:sldMasterIdLst");
    if (masterSlidesRoot.isNotEmpty) {
      var masterSlides =
          masterSlidesRoot.first.findAllElements("p:sldMasterId");
      if (masterSlides.isNotEmpty) {
        for (var slide in masterSlides) {
          int id = 0;
          String rId = "";
          var tempId = slide.getAttribute("id");
          if (tempId != null) {
            id = int.parse(tempId);
          }
          var tempRid = slide.getAttribute("r:id");
          if (tempRid != null) {
            rId = tempRid;
          }
          presentation.masterSlides.add(Slide(id, rId, ""));
        }
      }
    }
  }

  void getAllShapes(ArchiveFile presentationFile, Slide slide) {
    final fileContent = utf8.decode(presentationFile.content);
    final diagramDoc = xml.XmlDocument.parse(fileContent);
    var diagramsRoot = diagramDoc.findAllElements("dsp:sp");
    if (diagramsRoot.isNotEmpty) {
      for (var diagram in diagramsRoot) {
        String id = "";
        String text = "";
        //double offsetx = 0;
        double offsety = 0;
        Offset offset = const Offset(0, 0);
        Size size = const Size(0, 0);
        var tempId = diagram.getAttribute("modelId");
        if (tempId != null) {
          id = tempId;
        }
        var checkTxtBody = diagram.findAllElements("dsp:txBody");
        if (checkTxtBody.isNotEmpty) {
          var checkParaElement = checkTxtBody.first.findAllElements("a:p");
          if (checkParaElement.isNotEmpty) {
            var txtElement = checkParaElement.first.findAllElements("a:t");
            if (txtElement.isNotEmpty) {
              text = txtElement.first.innerText;
            }
          }
        }
        var checkSlFrm = diagram.findAllElements("a:xfrm");
        if (checkSlFrm.isNotEmpty) {
          var checkOffE = checkSlFrm.first.findAllElements("a:off");
          if (checkOffE.isNotEmpty) {
            var tempX = checkOffE.first.getAttribute("x");
            if (tempX != null) {
              //offsetx = double.parse(tempX);
            }
            var tempY = checkOffE.first.getAttribute("y");
            if (tempY != null) {
              offsety = double.parse(tempY);
            }
          }
        }

        var checkTxFrm = diagram.findAllElements("dsp:txXfrm");
        if (checkTxFrm.isNotEmpty) {
          var checkOffE = checkTxFrm.first.findAllElements("a:off");
          if (checkOffE.isNotEmpty) {
            double x = 0;
            double y = 0;
            var tempX = checkOffE.first.getAttribute("x");
            if (tempX != null) {
              x = double.parse(tempX);
            }
            var tempY = checkOffE.first.getAttribute("y");
            if (tempY != null) {
              y = double.parse(tempY);
            }
            offset = Offset(x, y + offsety);
          }
          var checkExtE = checkTxFrm.first.findAllElements("a:ext");
          if (checkExtE.isNotEmpty) {
            double x = 0;
            double y = 0;
            var tempX = checkExtE.first.getAttribute("cx");
            if (tempX != null) {
              x = double.parse(tempX);
            }
            var tempY = checkExtE.first.getAttribute("cy");
            if (tempY != null) {
              y = double.parse(tempY);
            }
            size = Size(x, y);
          }
        }
        slide.presentationShapes.add(PresentationShape(id, text, offset, size));
      }
    }
  }

  void readAllSlides() {
    for (int i = 0; i < presentation.slides.length; i++) {
      var slideRelation = relationShips.firstWhereOrNull((rel) {
        return rel.id == presentation.slides[i].rId;
      });
      if (slideRelation != null) {
        var slideFile = archive.singleWhere((archiveFile) {
          return archiveFile.name.endsWith(slideRelation.target);
        });
        if (slideFile.isFile) {
          final fileContent = utf8.decode(slideFile.content);
          final slideDoc = xml.XmlDocument.parse(fileContent);
          presentation.slides[i].fileName = slideFile.name.split("/").last;
          var spElement = slideDoc.findAllElements("p:sp");
          if (spElement.isNotEmpty) {
            for (int j = 0; j < spElement.length; j++) {
              Offset offset = const Offset(0, 0);
              Size size = const Size(0, 0);
              double offsetY = 0;
              double offsetX = 0;
              if (spElement.elementAt(j).parentElement != null &&
                  spElement.elementAt(j).parentElement?.name.toString() ==
                      "p:grpSp") {
                var grpSpPr = spElement
                    .elementAt(j)
                    .parentElement
                    ?.findAllElements("p:grpSpPr");
                if (grpSpPr != null && grpSpPr.isNotEmpty) {
                  var chckOff = grpSpPr.first.findAllElements("a:off");
                  if (chckOff.isNotEmpty) {
                    var offX = chckOff.first.getAttribute("x");
                    if (offX != null) {
                      offsetX = double.parse(offX);
                    }
                    var offY = chckOff.first.getAttribute("y");
                    if (offY != null) {
                      offsetY = double.parse(offY);
                    }
                  }
                }
              }
              var xfrmElement =
                  spElement.elementAt(j).findAllElements("a:xfrm");
              if (xfrmElement.isNotEmpty) {
                var chkOff = xfrmElement.first.findAllElements("a:off");
                if (chkOff.isNotEmpty) {
                  var offX = chkOff.first.getAttribute("x");
                  var offY = chkOff.first.getAttribute("y");
                  if (offX != null && offY != null) {
                    offset = Offset(double.parse(offX) + offsetX,
                        double.parse(offY) + offsetY);
                  }
                }
                var chkExt = xfrmElement.first.findAllElements("a:ext");
                if (chkExt.isNotEmpty) {
                  var extX = chkExt.first.getAttribute("cx");
                  var extY = chkExt.first.getAttribute("cy");
                  if (extX != null && extY != null) {
                    size = Size(double.parse(extX), double.parse(extY));
                  }
                }
              }
              List<PresentationParagraph> presentationParagraphs = [];
              spElement.elementAt(j).findAllElements("p:txBody").forEach((txt) {
                var chkPara = txt.findAllElements("a:p");
                List<PresentationText> presentationTexts = [];
                if (chkPara.isNotEmpty) {
                  for (var para in chkPara) {
                    presentationTexts = [];
                    var chkR = para.findAllElements("a:r");
                    if (chkR.isNotEmpty) {
                      for (var r in chkR) {
                        double fontSize = 20;
                        var rPr = r.findAllElements("a:rPr");
                        if (rPr.isNotEmpty) {
                          var tempSize = rPr.first.getAttribute("sz");
                          if (tempSize != null) {
                            fontSize = double.parse(tempSize) / 150;
                          }
                        }
                        var text = "";
                        r.findAllElements("a:t").forEach((txt2) {
                          text += txt2.innerText;
                        });

                        if (text.isNotEmpty) {
                          presentationTexts
                              .add(PresentationText(text, fontSize));
                        }
                      }
                    }
                    if (presentationTexts.isNotEmpty) {
                      PresentationParagraph paragraph = PresentationParagraph();
                      paragraph.textSpans = presentationTexts;
                      presentationParagraphs.add(paragraph);
                    }
                  }
                }
              });
              if (presentationParagraphs.isNotEmpty) {
                PresentationTextBox presentationTextBox =
                    PresentationTextBox(offset, size);
                presentationTextBox.presentationParas = presentationParagraphs;
                presentation.slides[i].presentationTextBoxes
                    .add(presentationTextBox);
              }
            }
          }

          var checkSlideRel = archive.singleWhereOrNull((archiveFile) {
            return archiveFile.name
                .endsWith("${presentation.slides[i].fileName}.rels");
          });
          if (checkSlideRel != null) {
            List<Relationship> slideLevelRelations = [];
            final fileContent = utf8.decode(checkSlideRel.content);
            String drawingTarget = "";
            String layoutTarget = "";
            final document = xml.XmlDocument.parse(fileContent);
            final relationshipsElement =
                document.findAllElements("Relationship");
            for (var rel in relationshipsElement) {
              if (rel.getAttribute("Id") != null) {
                slideLevelRelations.add(Relationship(
                    rel.getAttribute("Id").toString(),
                    rel.getAttribute("Target").toString()));
              }
              if (rel.getAttribute("Type") != null &&
                  rel
                      .getAttribute("Type")!
                      .endsWith("relationships/diagramDrawing")) {
                drawingTarget =
                    rel.getAttribute("Target").toString().replaceAll("../", "");
              }
              if (rel.getAttribute("Type") != null &&
                  rel
                      .getAttribute("Type")!
                      .endsWith("relationships/slideLayout")) {
                layoutTarget =
                    rel.getAttribute("Target").toString().replaceAll("../", "");
              }
            }
            if (drawingTarget.isNotEmpty) {
              var diagramFile = archive.singleWhereOrNull((archiveFile) {
                return archiveFile.name.endsWith(drawingTarget);
              });
              if (diagramFile != null) {
                getAllShapes(diagramFile, presentation.slides[i]);
              }
            }
            if (layoutTarget.isNotEmpty) {
              var checkLayoutRel = archive.singleWhereOrNull((archiveFile) {
                return archiveFile.name
                    .endsWith("${layoutTarget.split("/").last}.rels");
              });
              List<Relationship> layoutRelations = [];
              if (checkLayoutRel != null) {
                final fileContent2 = utf8.decode(checkLayoutRel.content);
                final document2 = xml.XmlDocument.parse(fileContent2);
                final relationshipsElement2 =
                    document2.findAllElements("Relationship");

                for (var rel in relationshipsElement2) {
                  if (rel.getAttribute("Id") != null) {
                    layoutRelations.add(Relationship(
                        rel.getAttribute("Id").toString(),
                        rel.getAttribute("Target").toString()));
                  }
                }
              }
              var layoutFile = archive.singleWhereOrNull((archiveFile) {
                return archiveFile.name.endsWith(layoutTarget);
              });
              if (layoutFile != null) {
                final fileContent3 = utf8.decode(layoutFile.content);
                final document3 = xml.XmlDocument.parse(fileContent3);
                var chkBg = document3.findAllElements("p:bg");
                if (chkBg.isNotEmpty) {
                  var chkBlip = chkBg.first.findAllElements("a:blip");
                  if (chkBlip.isNotEmpty) {
                    var chkEmbed = chkBlip.first.getAttribute("r:embed");
                    if (chkEmbed != null) {
                      var layoutRelTarget =
                          layoutRelations.firstWhereOrNull((rel) {
                        return rel.id == chkEmbed;
                      });
                      if (layoutRelTarget != null) {
                        presentation.slides[i].backgroundImagePath =
                            "$presentationOutputDirectory/${layoutRelTarget.target.split("/").last}";
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  }

  void displayPresentation() {
    List<Widget> tempList = [];
    List<Widget> slideWidgets = [];
    for (int i = 0; i < presentation.slides.length; i++) {
      List<Widget> tempSlide = [];
      List<Widget> tempShapes = [];
      double minWidth = 1200;
      double minHeight = 500;
      int divisionFactor = 12700;
      for (int j = 0;
          j < presentation.slides[i].presentationTextBoxes.length;
          j++) {
        if (presentation.slides[i].presentationTextBoxes[j].offset.dx /
                    divisionFactor +
                presentation.slides[i].presentationTextBoxes[j].size.width /
                    divisionFactor >
            minWidth) {
          minWidth = presentation.slides[i].presentationTextBoxes[j].offset.dx /
                  divisionFactor +
              presentation.slides[i].presentationTextBoxes[j].size.width /
                  divisionFactor;
        }
        if (presentation.slides[i].presentationTextBoxes[j].offset.dy /
                    divisionFactor +
                presentation.slides[i].presentationTextBoxes[j].size.height /
                    divisionFactor >
            minHeight) {
          minHeight =
              presentation.slides[i].presentationTextBoxes[j].offset.dy /
                      divisionFactor +
                  presentation.slides[i].presentationTextBoxes[j].size.height /
                      divisionFactor;
        }
        List<Widget> textBoxTexts = [];
        for (int k = 0;
            k <
                presentation.slides[i].presentationTextBoxes[j]
                    .presentationParas.length;
            k++) {
          List<TextSpan> textSpans = [];
          for (int l = 0;
              l <
                  presentation.slides[i].presentationTextBoxes[j]
                      .presentationParas[k].textSpans.length;
              l++) {
            textSpans.add(TextSpan(
                text: presentation.slides[i].presentationTextBoxes[j]
                    .presentationParas[k].textSpans[l].text,
                style: TextStyle(
                    fontSize: presentation.slides[i].presentationTextBoxes[j]
                        .presentationParas[k].textSpans[l].fontSize,
                    color: Colors.black)));
          }
          textBoxTexts.add(RichText(text: TextSpan(children: textSpans)));
        }
        if (presentation.slides[i].presentationTextBoxes[j].size.height != 0 &&
            presentation.slides[i].presentationTextBoxes[j].size.width != 0) {
          tempShapes.add(Positioned(
              top: presentation.slides[i].presentationTextBoxes[j].offset.dy /
                  divisionFactor,
              left: presentation.slides[i].presentationTextBoxes[j].offset.dx /
                  divisionFactor,
              child: SizedBox(
                //decoration: BoxDecoration(border: Border.all(color: Colors.blue)),
                height: presentation
                        .slides[i].presentationTextBoxes[j].size.height /
                    divisionFactor,
                width:
                    presentation.slides[i].presentationTextBoxes[j].size.width /
                        divisionFactor,
                child: Column(
                  children: textBoxTexts,
                ),
              )));
        } else {
          tempShapes.add(Positioned(
              top: presentation.slides[i].presentationTextBoxes[j].offset.dy /
                  divisionFactor,
              left: presentation.slides[i].presentationTextBoxes[j].offset.dx /
                  divisionFactor,
              child: Column(
                children: textBoxTexts,
              )));
        }
      }
      for (int j = 0;
          j < presentation.slides[i].presentationShapes.length;
          j++) {
        if (presentation.slides[i].presentationShapes[j].offset.dx /
                    divisionFactor +
                presentation.slides[i].presentationShapes[j].size.width /
                    divisionFactor >
            minWidth) {
          minWidth = presentation.slides[i].presentationShapes[j].offset.dx /
                  divisionFactor +
              presentation.slides[i].presentationShapes[j].size.width /
                  divisionFactor;
        }
        if (presentation.slides[i].presentationShapes[j].offset.dy /
                    divisionFactor +
                presentation.slides[i].presentationShapes[j].size.height /
                    divisionFactor >
            minHeight) {
          minHeight = presentation.slides[i].presentationShapes[j].offset.dy /
                  divisionFactor +
              presentation.slides[i].presentationShapes[j].size.height /
                  divisionFactor;
        }
        tempShapes.add(Positioned(
            top: presentation.slides[i].presentationShapes[j].offset.dy /
                divisionFactor,
            left: presentation.slides[i].presentationShapes[j].offset.dx /
                divisionFactor,
            child: Container(
              decoration: BoxDecoration(border: Border.all(color: Colors.blue)),
              height: presentation.slides[i].presentationShapes[j].size.height /
                  divisionFactor,
              width: presentation.slides[i].presentationShapes[j].size.width /
                  divisionFactor,
              child: Center(
                  child: Text(
                presentation.slides[i].presentationShapes[j].text,
              )),
            )));
      }
      if (tempShapes.isNotEmpty) {
        tempSlide.add(SizedBox(
            height: minHeight,
            width: minWidth,
            child: Stack(
              children: tempShapes,
            )));
      }
      slideWidgets.add(SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ScrollConfiguration(
          behavior: const ScrollBehavior().copyWith(overscroll: false),
          child: Scrollbar(
            thickness: 10.0,
            child: Container(
              constraints: const BoxConstraints(minHeight: 450),
              decoration: presentation.slides[i].backgroundImagePath != ""
                  ? BoxDecoration(
                      color: Colors.white,
                      image: DecorationImage(
                        image: FileImage(
                            File(presentation.slides[i].backgroundImagePath)),
                        fit: BoxFit.fill,
                      ),
                    )
                  : const BoxDecoration(
                      color: Colors.white,
                    ),
              width: minWidth,
              margin: const EdgeInsets.fromLTRB(0, 0, 0, 8),
              child: Column(
                children: tempSlide,
              ),
            ),
          ),
        ),
      ));
    }
    tempList.add(Container(
      color: Colors.grey,
      margin: const EdgeInsets.all(8),
      child: Column(
        children: slideWidgets,
      ),
    ));
    setState(() {
      presentationWidgets = tempList;
    });
  }
}
