import 'package:html/parser.dart' as html_parser;

class HtmlHelper {
  HtmlHelper._();

  static String parseHtmlString(String htmlString) {
    final document = html_parser.parse(htmlString);

    return document.body?.text.trim() ?? '';
  }
}