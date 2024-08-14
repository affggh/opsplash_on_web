import 'dart:convert';
import 'dart:typed_data';

import 'package:file_saver/file_saver.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:file_picker/file_picker.dart';
import 'package:opsplash_flutter/opsplash.dart';
import 'package:image/image.dart' as img;

class PageToolBody extends StatefulWidget {
  const PageToolBody({super.key});

  @override
  State<PageToolBody> createState() => _PageToolBodyState();
}

class _PageToolBodyState extends State<PageToolBody> {
  final fileController = TextEditingController();

  Uint8List? filebytes;
  SplashImage? splashImage;

  TreeViewItem? selectedItem;

  Future<void> uploadFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      filebytes = result.files.first.bytes;
      fileController.text = result.files.first.name;
    }
  }

  Future<void> loadSplashInfo(BuildContext context) async {
    if (filebytes != null) {
      try {
        splashImage = SplashImage(data: filebytes!);
        await displayInfoBar(context, builder: (context, close) {
          return InfoBar(
            title: const Text("Success:"),
            content: const Text("Success load splash image."),
            action: IconButton(
              icon: const Icon(FluentIcons.clear),
              onPressed: close,
            ),
            severity: InfoBarSeverity.success,
          );
        });
        setState(() {});
      } catch (except) {
        if (context.mounted) {
          await displayInfoBar(context, builder: (context, close) {
            return InfoBar(
              title: const Text('Error:'),
              content: Text(except.toString()),
              action: IconButton(
                icon: const Icon(FluentIcons.clear),
                onPressed: close,
              ),
              severity: InfoBarSeverity.error,
            );
          });
        }
      }
    }
  }

  Future<Uint8List?> getImageDataByItem() async {
    await Future.delayed(const Duration(seconds: 1));
    var imageData =
        await splashImage?.getImageDataByIndexAsync(selectedItem?.value as int);

    return imageData;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: ListView(
                children: [
                  Row(
                    children: [
                      Expanded(
                          child: TextBox(
                        placeholder: "File Upload",
                        controller: fileController,
                        suffix: FilledButton(
                          child: const Text("Upload Splash Image"),
                          onPressed: () async {
                            await uploadFile();
                            if (context.mounted) {
                              await loadSplashInfo(context);
                            }
                          },
                        ),
                      )),
                    ],
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Expander(
                      header: const Text("Splash Info"),
                      content: (splashImage == null)
                          ? Container()
                          : TreeView(items: [
                              TreeViewItem(
                                  content:
                                      Text("DDPH : ${splashImage!.ddphMagic}")),
                              TreeViewItem(
                                  content: Text(
                                      "DDPH flag : ${splashImage!.ddphFlag}")),
                              TreeViewItem(
                                  content: Text(
                                      "Splash Magic : ${splashImage!.splashMagic}")),
                              TreeViewItem(
                                  content:
                                      Text("Width  : ${splashImage!.width}")),
                              TreeViewItem(
                                  content:
                                      Text("Height : ${splashImage!.height}")),
                              TreeViewItem(
                                  content: Text(
                                      "Image count: ${splashImage!.imgNumber}")),
                              TreeViewItem(
                                  content: Text(
                                      "OPPO splash version : ${splashImage!.version}")),
                              TreeViewItem(
                                  content: Text(
                                      "Splash special flag : ${splashImage!.special}")),
                              TreeViewItem(
                                  content: const Text("Metadata : "),
                                  children: [
                                    TreeViewItem(
                                        content: Text(
                                            "metadata 0 : ${utf8.decode(splashImage!.metadata![0]).trimRight()}")),
                                    TreeViewItem(
                                        content: Text(
                                            "metadata 1 : ${utf8.decode(splashImage!.metadata![1]).trimRight()}")),
                                    TreeViewItem(
                                        content: Text(
                                            "metadata 2 : ${utf8.decode(splashImage!.metadata![2]).trimRight()}")),
                                    TreeViewItem(
                                        content: Text(
                                            "metadata 3 : ${utf8.decode(splashImage!.metadata![3]).trimRight()}")),
                                  ])
                            ])),
                  Expander(
                    header: const Text("Image Selection"),
                    content: TreeView(
                      onSelectionChanged: (select) async {
                        selectedItem = select.first;
                      },
                      selectionMode: TreeViewSelectionMode.single,
                      items: (splashImage != null)
                          ? List.generate(splashImage!.dataInfo!.length,
                              (index) {
                              return TreeViewItem(
                                  value: index,
                                  selected: false,
                                  content: Text(utf8
                                      .decode(
                                          splashImage!.dataInfo![index].name)
                                      .trimRight()));
                            })
                          : [],
                    ),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                ],
              ),
            ),
            Container(
                decoration: ShapeDecoration(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5.0)),
                    color: FluentTheme.of(context).cardColor),

                //color: FluentTheme.of(context).cardColor,
                padding: const EdgeInsets.all(10),
                child: Row(
                  children: [
                    Expanded(
                        child: Button(
                            child: const Text("Preview"),
                            onPressed: () {
                              showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    if (selectedItem != null) {
                                      return ContentDialog(
                                        title: const Text("Preview"),
                                        content: FutureBuilder<Uint8List?>(
                                            future: getImageDataByItem(),
                                            builder: (BuildContext context,
                                                AsyncSnapshot snapshot) {
                                              if (snapshot.connectionState !=
                                                  ConnectionState.done) {
                                                return const ProgressRing();
                                              } else if (snapshot.hasError) {
                                                return Text(
                                                    "Some thing went wrong: $snapshot}");
                                              } else {
                                                var imgimg = img.decodeImage(
                                                    snapshot.data!);
                                                int width = 0;
                                                int height = 0;
                                                if (imgimg != null) {
                                                  width = imgimg.width;
                                                  height = imgimg.height;
                                                }
                                                return Center(
                                                    child: InfoLabel(
                                                  label:
                                                      "width: $width\nheight:$height",
                                                  child: Image.memory(
                                                      snapshot.data),
                                                ));
                                              }
                                            }),
                                        actions: [
                                          Button(
                                              child: const Text("OK"),
                                              onPressed: () {
                                                Navigator.pop(context);
                                              })
                                        ],
                                      );
                                    }
                                    return ContentDialog(
                                      title: const Text("Error"),
                                      content:
                                          const Text("Please select image tag"),
                                      actions: [
                                        Button(
                                          child: const Text("OK"),
                                          onPressed: () {
                                            Navigator.pop(context);
                                          },
                                        )
                                      ],
                                    );
                                  });
                            })),
                    const SizedBox(
                      width: 10,
                    ),
                    Expanded(
                        child: Button(
                            child: const Text("Replace"),
                            onPressed: () async {
                              FilePickerResult? result =
                                  await FilePicker.platform.pickFiles();

                              if (result != null) {
                                var file = result.files.first;
                                try {
                                  if (splashImage != null) {
                                    if (selectedItem == null) {
                                      if (context.mounted) {
                                        displayInfoBar(context,
                                            builder: (context, close) {
                                          return InfoBar(
                                            title: const Text(
                                                "Error: Please select image tag!"),
                                            severity: InfoBarSeverity.error,
                                            action: IconButton(
                                              icon:
                                                  const Icon(FluentIcons.clear),
                                              onPressed: () => close,
                                            ),
                                          );
                                        });
                                      }
                                      return;
                                    }
                                    bool success = await splashImage
                                            ?.setImageCompressedDataByIndex(
                                                file.bytes,
                                                selectedItem!.value as int) ??
                                        false;
                                    if (context.mounted) {
                                      displayInfoBar(context,
                                          builder: (context, close) {
                                        return InfoBar(
                                          title: success
                                              ? const Text("Succeed replaced!")
                                              : const Text(
                                                  "Failed to replace!"),
                                          severity: success
                                              ? InfoBarSeverity.success
                                              : InfoBarSeverity.error,
                                          action: IconButton(
                                            icon: const Icon(FluentIcons.clear),
                                            onPressed: () => close,
                                          ),
                                        );
                                      });
                                    }
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    displayInfoBar(context,
                                        builder: (context, close) {
                                      return InfoBar(
                                        title: Text("Error: $e"),
                                        severity: InfoBarSeverity.error,
                                        action: IconButton(
                                          icon: const Icon(FluentIcons.clear),
                                          onPressed: () => close,
                                        ),
                                      );
                                    });
                                  }
                                }
                              }
                            })),
                    const SizedBox(
                      width: 10,
                    ),
                    Expanded(
                      child: FilledButton(
                        onPressed: (splashImage != null) ? () {
                          var splashData = splashImage!.generateNewSplashImage();

                          if (splashData != null) {
                            FileSaver.instance.saveFile(name: "new-splash.img", bytes: splashData);
                          } else {
                            displayInfoBar(context, builder: (context, close) => InfoBar(title: Text("Generated failed!"), severity: InfoBarSeverity.error,));
                          }

                        } : null,
                        child: const Text("Download"),
                      ),
                    ),
                  ],
                )),
          ]),
    );
  }
}
