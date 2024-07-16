import 'package:flutter/material.dart';
import 'package:management/models/Userdate.dart';
import 'package:management/widgets/Hero_section.dart';
import 'package:provider/provider.dart';
import 'package:management/themes/Fitness.dart';
import '../models/water.dart';

class WaterView extends StatelessWidget {
  WaterView({Key? key}) : super(key: key);
  GlobalData data = GlobalData();
  late DateTime nows;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => WaterViewModel(),
      child: Consumer<WaterViewModel>(
        builder: (context, model, child) {
          return Container(
            decoration: BoxDecoration(
              color: FitnessAppTheme.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8.0),
                bottomLeft: Radius.circular(8.0),
                bottomRight: Radius.circular(8.0),
                topRight: Radius.circular(68.0),
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: FitnessAppTheme.grey.withOpacity(0.2),
                  offset: const Offset(1.1, 1.1),
                  blurRadius: 10.0,
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      children: <Widget>[
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: <Widget>[
                                Padding(
                                  padding: EdgeInsets.only(left: 4, bottom: 3),
                                  child: Text(
                                    model.totalWaterConsumed.toStringAsFixed(0),
                                    textAlign: TextAlign.center,
                                    style:const TextStyle(
                                      fontFamily: FitnessAppTheme.fontName,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 32,
                                      color: FitnessAppTheme.nearlyDarkBlue,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.only(left: 8, bottom: 8),
                                  child: Text(
                                    model.totalWaterConsumed.toString(),
                                    textAlign: TextAlign.center,
                                    style:const TextStyle(
                                      fontFamily: FitnessAppTheme.fontName,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 18,
                                      letterSpacing: -0.2,
                                      color: FitnessAppTheme.nearlyDarkBlue,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Padding(
                              padding: EdgeInsets.only(left: 4, top: 2, bottom: 14),
                              child: Text(
                                'of daily goal ${data.waterGoal}',
                                textAlign: TextAlign.center,
                                style:const  TextStyle(
                                  fontFamily: FitnessAppTheme.fontName,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                  letterSpacing: 0.0,
                                  color: FitnessAppTheme.darkText,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Padding(
                          padding: EdgeInsets.only(left: 4, right: 4, top: 8, bottom: 16),
                          child: Container(
                            height: 2,
                            decoration:const BoxDecoration(
                              color: FitnessAppTheme.background,
                              borderRadius: BorderRadius.all(Radius.circular(4.0)),
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(top: 16),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: <Widget>[
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: <Widget>[
                                  Padding(
                                    padding: EdgeInsets.only(left: 4),
                                    child: Icon(
                                      Icons.access_time,
                                      color: FitnessAppTheme.grey.withOpacity(0.5),
                                      size: 16,
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.only(left: 4.0),
                                    child: Text(
                                      'Last drink ${model.lastDrinkTime}',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontFamily: FitnessAppTheme.fontName,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 14,
                                        letterSpacing: 0.0,
                                        color: FitnessAppTheme.grey.withOpacity(0.5),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Padding(
                                padding: EdgeInsets.only(top: 4),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: <Widget>[
                                    SizedBox(
                                      width: 24,
                                      height: 24,
                                      // child: Image.asset('assets/fitness_app/bell.png'),
                                    ),
                                    Flexible(
                                      child: Text(
                                        model.bottleStatus,
                                        textAlign: TextAlign.start,
                                        style: TextStyle(
                                          fontFamily: FitnessAppTheme.fontName,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 12,
                                          letterSpacing: 0.0,
                                          color: HexColor('#F65283'),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 34,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        Container(
                          decoration: BoxDecoration(
                            color: FitnessAppTheme.nearlyWhite,
                            shape: BoxShape.circle,
                            boxShadow: <BoxShadow>[
                              BoxShadow(
                                color: FitnessAppTheme.nearlyDarkBlue.withOpacity(0.4),
                                offset: Offset(4.0, 4.0),
                                blurRadius: 8.0,
                              ),
                            ],
                          ),
                          child: Container(
                            // padding: EdgeInsets.all(6.0),
                            child: IconButton(
                              icon: const Icon(
                                Icons.add,
                                color: FitnessAppTheme.nearlyDarkBlue,
                                size: 24,
                              ),
                              onPressed: () {
                                model.updateWater(100);
                                model.updateLastDrinkTime('${(DateTime.now().hour.toInt())%12}:${DateTime.now().minute}   ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}');
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        Container(
                          decoration: BoxDecoration(
                            color: FitnessAppTheme.nearlyWhite,
                            shape: BoxShape.circle,
                            boxShadow: <BoxShadow>[
                              BoxShadow(
                                color: FitnessAppTheme.nearlyDarkBlue.withOpacity(0.4),
                                offset: Offset(4.0, 4.0),
                                blurRadius: 8.0,
                              ),
                            ],
                          ),
                          child: Container(
                            child: IconButton(
                              icon: Icon(
                                Icons.remove,
                                color: FitnessAppTheme.nearlyDarkBlue,
                                size: 24,
                              ),
                              onPressed: () {
                                model.updateWater(-100);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 16, right: 8, top: 16),
                    child: Container(
                      width: 60,
                      height: 160,
                      decoration: BoxDecoration(
                        color: HexColor('#E8EDFE'),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(80.0),
                          bottomLeft: Radius.circular(80.0),
                          bottomRight: Radius.circular(80.0),
                          topRight: Radius.circular(80.0),
                        ),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: FitnessAppTheme.grey.withOpacity(0.4),
                            offset: const Offset(2, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          color: FitnessAppTheme.nearlyDarkBlue,

                        ),
                        height: 0,  
                                                    
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
