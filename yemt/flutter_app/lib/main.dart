import 'dart:async';
import 'dart:io';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/services.dart';
import 'package:flutter_better_camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/result.dart';

class CameraExampleHome extends StatefulWidget {
  @override
  _CameraExampleHomeState createState() {
    return _CameraExampleHomeState();
  }
}

void logError(String code, String message) =>
    print('Error: $code\nError Message: $message');

class _CameraExampleHomeState extends State<CameraExampleHome>
    with WidgetsBindingObserver {
  CameraController controller;
  bool enableAudio = true;
  var checkList = new List();
  bool getImg = false;
  bool check = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
    controller.setFlashMode(FlashMode.off);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // App state changed before we got the chance to initialize.
    if (controller == null || !controller.value.isInitialized) {
      return;
    }
    if (state == AppLifecycleState.inactive) {
      controller?.dispose();
      controller.setFlashMode(FlashMode.off);
    } else if (state == AppLifecycleState.resumed) {
      if (controller != null) {
        onNewCameraSelected(controller.description);
      }
      controller.setFlashMode(FlashMode.off);
    }
  }

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();



  void startTest() {
    onNewCameraSelected(cameras[0]);
    Fluttertoast.showToast(
        msg: "開始測驗",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.grey,
        textColor: Colors.white,
        fontSize: 16.0);
    Timer.periodic(Duration(seconds: 1), (timer) {
      if (checkList.length == 15) {
        double sumr = 0, sumg = 0, sumb = 0;
        for (int i = 0; i < checkList.length; i++) {
          sumr += checkList[i][0];
          sumg += checkList[i][1];
          sumb += checkList[i][2];
        }
        sumr /= checkList.length;
        sumg /= checkList.length;
        sumb /= checkList.length;
        double cvr = 0, cvg = 0, cvb = 0, sr = 0, sg = 0, sb = 0;
        for (int i = 0; i < checkList.length; i++) {
          sr += checkList[i][0] - sumr;
          sg += checkList[i][1] - sumg;
          sb += checkList[i][2] - sumb;
        }
        cvr = sr / sumr;
        cvg = sg / sumg;
        cvb = sb / sumb;
        // 2. If (0.7*B avg< R avg) OR (0.7*B avg <G avg) Then

        if (0.7 * sumb < sumr || 0.7 * sumb < sumg) {
          Fluttertoast.showToast(
              msg: "主光訊號偏低，請檢查量測盒是否對準鏡頭及閃光燈",
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.BOTTOM,
              timeInSecForIosWeb: 1,
              backgroundColor: Colors.grey,
              textColor: Colors.white,
              fontSize: 16.0);
        }
        //If if (R cv + G cv +B cv>chk Then
        if (cvr + cvg + cvb > 0.6) {
          Fluttertoast.showToast(
              msg: "光訊號不穩，請檢查量測盒黏貼情況",
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.BOTTOM,
              timeInSecForIosWeb: 1,
              backgroundColor: Colors.grey,
              textColor: Colors.white,
              fontSize: 16.0);

        }
      } else if (timer.tick > 7 * 60) {
        timer.cancel();
        controller.setFlashMode(FlashMode.off);
        double rate=0;
        Navigator.push(context, MaterialPageRoute(builder: (context) => Result(rate)));
      }
      getImg = true;

    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      body: Column(
        children: <Widget>[
          Expanded(
            child: Container(
              child: Padding(
                padding: const EdgeInsets.all(1.0),
                child: Center(
                    child: _cameraPreviewWidget()),
              ),
              decoration: BoxDecoration(
                border: Border.all(
                  color: controller != null && controller.value.isRecordingVideo
                      ? Colors.redAccent
                      : Colors.grey,
                  width: 3.0,
                ),
              ),
            ),
          ),
          FlatButton(
            onPressed: () {startTest();},
            child: Text("開始檢測"),
          )
        ],
      ),
    );
  }

  /// Display the preview from the camera (or a message if the preview is not available).
  Widget _cameraPreviewWidget() {
    if (controller == null || !controller.value.isInitialized) {
      return const Text(
        'Tap a camera',
        style: TextStyle(
          color: Colors.white,
          fontSize: 24.0,
          fontWeight: FontWeight.w900,
        ),
      );
    } else {
      return AspectRatio(
        aspectRatio: controller.value.aspectRatio,
        child: CameraPreview(controller),
      );
    }
  }

  // void showInSnackBar(String message) {
  //   _scaffoldKey.currentState.showSnackBar(SnackBar(content: Text(message)));
  // }

  void convertYUV420toImageColor(CameraImage image) async {
    if (getImg) {
      try {
        final int width = image.width;
        final int height = image.height;
        final int uvRowStride = image.planes[1].bytesPerRow;
        final int uvPixelStride = image.planes[1].bytesPerPixel;
        double r = 0;
        double g = 0;
        double b = 0;

        for (int x = 0;x<width; x++) {
          for (int y = 0;y<height; y++) {
            final int uvIndex =
                uvPixelStride * (x / 2).floor() + uvRowStride * (y / 2).floor();
            final int index = y *width + x;
            final yp = image.planes[0].bytes[index];
            final up = image.planes[1].bytes[uvIndex];
            final vp = image.planes[2].bytes[uvIndex];
            // Calculate pixel color
            r += (yp + vp * 1436 / 1024 - 179).round().clamp(0, 255);
            g += (yp - up * 46549 / 131072 + 44 - vp * 93604 / 131072 + 91)
                .round()
                .clamp(0, 255);
            b += (yp + up * 1814 / 1024 - 227).round().clamp(0, 255);
          }
        }
        int len = width*height ;


        r /= len;
        g /= len;
        b /= len;
        checkList.add([r, g, b]);
        print("\t${r}\t${g}\t${b}");
        getImg = false;
      } catch (e) {
        print(">>>>>>>>>>>> ERROR:" + e.toString());
      }
    }
  }

  void onNewCameraSelected(CameraDescription cameraDescription) async {
    if (controller != null) {
      await controller.dispose();
    }
    controller = CameraController(
      cameraDescription,
      ResolutionPreset.medium,
      enableAudio: enableAudio,
    );

    // If the controller is updated then update the UI.
    controller.addListener(() {
      if (mounted) setState(() {});
      if (controller.value.hasError) {
        // showInSnackBar('Camera error ${controller.value.errorDescription}');
      }
    });

    try {
      await controller.initialize();
    } on CameraException catch (e) {
      _showCameraException(e);
    }
    controller.startImageStream((image) => {convertYUV420toImageColor(image)});
    await controller.setFlashMode(FlashMode.torch);
  }

  void _showCameraException(CameraException e) {
    logError(e.code, e.description);
    // showInSnackBar('Error: ${e.code}\n${e.description}');
  }
}

class CameraApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        accentTextTheme: TextTheme(body2: TextStyle(color: Colors.white)),

      ),
      home: CameraExampleHome(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class _HomeState extends State<Home> with WidgetsBindingObserver {
  CameraController controller;
  bool enableAudio = true;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeRight,
    ]);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Center(
            child: Column(
      // mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Row(
          children: <Widget>[
            FloatingActionButton(onPressed: (){},
            child: Image.asset("images/home.png"),
            heroTag: "home",
            ),
            FloatingActionButton(onPressed: (){},
              child: Image.asset("images/setting.png"),
              heroTag: "setting",),

            FlatButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => Result(20)),
                  );
                },
                child: Text("點我跳報告畫面"))
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            FlatButton(
              onPressed: () {},
              padding: EdgeInsets.fromLTRB(25, 50, 0, 0),
              child: Image.asset('images/train.png', width: 200),
            ),
            FlatButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CameraApp()),
                );
              },
              padding: EdgeInsets.fromLTRB(0, 50, 25, 0),
              child: Image.asset('images/test.png', width: 200),
            ),
            Column(
              children: <Widget>[
                FlatButton(
                  onPressed: () {},
                  padding: EdgeInsets.fromLTRB(0, 50, 0, 0),
                  child: Image.asset('images/knowledge.png', width: 200),
                ),
                FlatButton(
                  onPressed: () {},
                  padding: EdgeInsets.fromLTRB(0, 0, 0, 0),
                  child: Image.asset('images/record.png', width: 200),
                ),
              ],
            )
          ],
        )
      ],
    )));
  }
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() {
    return _HomeState();
  }
}

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme:
          ThemeData(
              scaffoldBackgroundColor: Color.fromRGBO(254, 246, 227, 1)
          ,floatingActionButtonTheme: FloatingActionButtonThemeData(
            backgroundColor: Color.fromRGBO(255, 245, 227, 1),
            shape: RoundedRectangleBorder(),
            elevation: 0,
          )),
      home: Home(),
      debugShowCheckedModeBanner: false,
    );
  }
}

List<CameraDescription> cameras = [];

Future<void> main() async {
  // Fetch the available cameras before initializing the app.
  try {
    WidgetsFlutterBinding.ensureInitialized();
    cameras = await availableCameras();
  } on CameraException catch (e) {
    logError(e.code, e.description);
  }
  runApp(HomePage());
}
