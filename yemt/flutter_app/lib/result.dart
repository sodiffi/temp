import 'package:flutter/material.dart';

// ignore: must_be_immutable
class Result extends StatelessWidget {
  double rate;
  Result(double rate){
    this.rate=rate;
  }
  Result.empty(){
    this.rate=0;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
          floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: Color.fromRGBO(255, 245, 227, 1),
        shape: RoundedRectangleBorder(),
        elevation: 0,
      )),
      home: Scaffold(
        backgroundColor: Color.fromRGBO(254, 246, 227, 1),
        body: Column(
            // mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  FloatingActionButton(
                    onPressed: () {},
                    child: Image.asset("images/home.png"),
                    heroTag: "home",
                  ),
                  FloatingActionButton(
                    onPressed: () {},
                    child: Image.asset("images/setting.png"),
                    heroTag: "setting",
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Stack(
                          alignment: const Alignment(0.0, -0.1),
                          children: [
                            Image.asset("images/rateBox.png"),
                            Text(
                              rate.toString()+"%",
                              style: new TextStyle(
                                  fontSize: 50, fontFamily: "NanumPenScript"),
                            )
                          ],
                        )
                      ]),
                  Stack(
                    alignment: const Alignment(0.0, 0.2),
                    children: [
                      Stack(
                        alignment: const Alignment(0.8, -0.8),
                        children: [
                          Image.asset("images/report.png"),
                          Image.asset("images/share.png"),
                        ],
                      ),
                      Text(
                        rate<35?"合格":rate<45?
                        "通知供應單位延期採收\n追蹤農民用藥"
                            :"銷毀或\n將樣品送衛生局複檢",
                        style: new TextStyle(fontSize: 45),
                      )
                    ],
                  ),
                ],
              ),
            ]),
      ),
    );
  }
}
