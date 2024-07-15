import 'package:flutter/material.dart';
import 'package:gauge_indicator/gauge_indicator.dart';
import 'package:management/themes/Fitness.dart';

class CustomCard extends StatelessWidget {
  final double totalCaloriesConsumed;

  CustomCard({required this.totalCaloriesConsumed});

  @override
  Widget build(BuildContext context) {
    return Card(
                                          color: FitnessAppTheme.nearlyDarkBlue,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
      ),
      clipBehavior: Clip.antiAliasWithSaveLayer,
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            AnimatedRadialGauge(
              duration: const Duration(seconds: 1),
              curve: Curves.elasticOut,
              radius: 100,
              value: totalCaloriesConsumed,
              axis: const GaugeAxis(
                min: 0,
                max: 100,
                degrees: 180,
                style: GaugeAxisStyle(
                  thickness: 20,
                  background:                                           FitnessAppTheme.nearlyBlue,

                  segmentSpacing: 4,
                ),
                pointer: GaugePointer.needle(
                  height: 80,
                  color: Color.fromARGB(255, 255, 255, 255),
                  width: 19,
                  borderRadius: 16,
                ),
                progressBar: GaugeProgressBar.rounded(
                  color: Color.fromARGB(255, 255, 255, 255),
                ),
                segments: [
                  GaugeSegment(
                    from: 0,
                    to: 30,
                      color: FitnessAppTheme.nearlyDarkBlue,
                    cornerRadius: Radius.zero,
                  ),
                ],
              ),
            ),
            SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  SizedBox(height: 5),
                  Text(
                    'Calorie count',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    totalCaloriesConsumed.toString(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 10),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}