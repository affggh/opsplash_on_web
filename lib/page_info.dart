import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher_string.dart';


const aboutData = 
"""
# About
### About Circle Cash Team
Program written by [affggh](https://github.com/affggh)    
Program written with flutter

## There are some awsome libraries on flutter
[fluent_ui](https://bdlukaa.github.io/fluent_ui)    
[flutter_markdown](https://pub.dev/packages/flutter_markdown)    
[splash image](https://www.zcool.com.cn/work/ZNTU1Nzg3Mjg=.html?)    
[file_picker]()    
[fltter_native_splash]()    
[url_launcher]()

## limit
flutter seems not support isolate on web platform, so some method may stuck.
""";

class AboutPage extends StatelessWidget  {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Markdown(
        data: aboutData, 
        selectable: true,
        onTapLink: (text, href, title) {
          if (href != null) {
            launchUrlString(href);
          }
        },
        )
    );
  }
  
}