import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'medicine_provider.dart';
import 'dart:async' show Future;
import 'dart:convert' show utf8;
import 'dart:math';
import 'package:flutter/services.dart' show rootBundle;
import 'package:csv/csv.dart';

enum Gender { male, female }

class AdvancedChildCalculation extends StatefulWidget {
  @override
  _AdvancedChildCalculationState createState() =>
      _AdvancedChildCalculationState();
}

class _AdvancedChildCalculationState extends State<AdvancedChildCalculation> {
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  // เพิ่มกล่องข้อความกรอกปริมาตรขวดยา
  final TextEditingController _buttonVolume = TextEditingController();
  final TextEditingController _takeMedDay = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  double? _idealBodyWeight;
  double? _childDose;
  Gender? _gender;
  Gender? get gender => _gender;
  Future<double> compareAgeWeight(
      double age, double weight, double height, Gender _gender) async {
    final List<List<dynamic>> csvDataBoy = await loadCsvBoy();
    final List<List<dynamic>> csvDataGirl = await loadCsvGirl();
    final List<List<dynamic>> csvData = await loadCsv(_gender);
    print("age $age");
    print("weight $widget");
    print("height $height");
    print("Gender $_gender");
    double bmi = 0;
    bool found = false;
    if (_gender == Gender.male) {
      print("if gender = male $_gender");
      for (final List<dynamic> row in csvData) {
        if (row[0] == age) {
          print("row[0] ${row[0]}");
          bmi = row[1];
          found = true;

          print("### from compareAgeWeight ###");
          print("bmi got from compare =$bmi");
          break;
        }
      }
    } else {
      for (final List<dynamic> row in csvData) {
        if (row[0] == age) {
          bmi = row[1];
          found = true;

          break;
        }
      }
    }
    if (!found) {
      bmi = weight / (height * height);
    }
    return bmi;
  }

  Future<double> calculateIdealBodyWeight(
      double height, double weight, double age, _gender) async {
    if (age >= 2 || age <= 18) {
      double fat_bmi = await compareAgeWeight(age, weight, height, _gender);
      print(" ### ### ### ");
      print("fat bmi = $fat_bmi");
      print(" ### ### ### ");

      return fat_bmi;
    }
    return weight;
  }

  Future<double> calculateChildDose(double idealBodyWeight) async {
    MedicineProvider medicineProvider =
        Provider.of<MedicineProvider>(context, listen: false);
    double doseInMl = await medicineProvider.calculateDose(idealBodyWeight);
    print("####################");
    print("dose in ml $doseInMl");
    print("###############");
    return doseInMl;
  }

  Future<double> bottle(
      double chilDose, int takeday, double bottleVolume) async {
    MedicineProvider medicineProvider =
        await Provider.of<MedicineProvider>(context);
    int? frequency = medicineProvider.frequency;
    if (chilDose != null &&
        frequency != null &&
        takeday != null &&
        bottleVolume != null) {
      double totolTakeVolume = (chilDose * frequency * takeday);
      double bottleToPrescribe = totolTakeVolume / bottleVolume;
      if (bottleToPrescribe != null) {
        double roundedBottleValue = bottleToPrescribe.ceil().toDouble();
        return roundedBottleValue;
      }
    }
    return 0;
  }

  Future<double> calculate() async {
    if (_heightController.text.isEmpty ||
        _weightController.text.isEmpty | _ageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Please enter Weight,Height,Age")));
    }
    double? height = double.parse(_heightController.text);
    double? weight = double.parse(_weightController.text);
    double? age = double.parse(_ageController.text);
    if (height == null || weight == null || age == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text("Invalid input please enter valid Weight,Height,Age.")));
    }

    MedicineProvider medicineProvider =
        Provider.of<MedicineProvider>(context, listen: false);
    medicineProvider.selectMedicine(medicineProvider.selectedMedicineId!);
    double _idealBodyWeight =
        await calculateIdealBodyWeight(height, weight, age, _gender);

    double _childDose = await calculateChildDose(_idealBodyWeight);
    double myBottleVolume = double.parse(_buttonVolume.text);
    int takeday = int.parse(_takeMedDay.text);
    double _bottleGiveTopatient =
        await bottle(_childDose, takeday, myBottleVolume);
    return _childDose;
  }

  @override
  Widget build(BuildContext context) {
    MedicineProvider medicineProvider = Provider.of<MedicineProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Advanced Child Calculation'),
      ),
      body: FutureBuilder<List<List<dynamic>>>(
        future: loadCsv(_gender),
        builder: (BuildContext context,
            AsyncSnapshot<List<List<dynamic>>> snapshot) {
          if (snapshot.hasData) {
            List<List<dynamic>> csvData = snapshot.data!;
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: <Widget>[
                        Row(
                          children: [
                            Expanded(
                                child: ListTile(
                              title: const Text("Boy"),
                              leading: Radio<Gender>(
                                value: Gender.male,
                                groupValue: _gender,
                                onChanged: ((Gender? value) {
                                  setState(() {
                                    _gender = value;
                                  });
                                  if (_gender == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text("Choose Boy Or Girl."),
                                      ),
                                    );
                                  }
                                }),
                              ),
                            )),
                            Expanded(
                                child: ListTile(
                              title: const Text('Girl'),
                              leading: Radio<Gender>(
                                value: Gender.female,
                                groupValue: _gender,
                                onChanged: (Gender? value) {
                                  setState(() {
                                    _gender = value;
                                  });
                                  if (_gender == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text("Choose Boy or Girl."),
                                      ),
                                    );
                                  }
                                },
                              ),
                            )),
                          ],
                        ),
                        TextField(
                          controller: _ageController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: "Age(Year)",
                          ),
                        ),
                        TextField(
                          controller: _weightController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Weight (kg)',
                          ),
                        ),
                        TextField(
                          controller: _heightController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Height (cm)',
                          ),
                        ),
                        SizedBox(height: 16),
                        Consumer<MedicineProvider>(
                          builder: (_, medicineProvider, __) {
                            return DropdownButtonFormField<int>(
                              hint: Text('Select Medicine'),
                              value: medicineProvider.selectedMedicineId,
                              onChanged: (int? newValue) {
                                print("medicine id = $newValue");
                                medicineProvider.selectMedicine(newValue!);
                              },
                              items: medicineProvider.medicines
                                  .map<DropdownMenuItem<int>>((medicine) {
                                return DropdownMenuItem<int>(
                                  value: medicine['id'],
                                  child: Text(medicine['name']),
                                );
                              }).toList(),
                              validator: (value) {
                                if (value == null) {
                                  return 'Please select a medicine';
                                }
                                return null;
                              },
                            );
                          },
                        ),
                        TextField(
                          controller: _buttonVolume,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                              labelText: 'Bีottle Volumne(milliliter)'),
                        ),
                        TextField(
                          controller: _takeMedDay,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText:
                                "จำนวนวันที่ต้องรับประทานยา \nเช่น 7วัน กรอกเลข 7",
                          ),
                        ),
                        SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () async {
                            if (_formKey.currentState!.validate()) {
                              // double doseInMl = await calculate();
                              CalculationResult _result = await calculateR();
                              double doseInMl = _result.childDose;
                              double _resultBottle =
                                  _result.bottleGiveToPatient;
                              print(
                                  "result Childdose ${doseInMl} \n bottle $_resultBottle");
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text('Calculated Dose'),
                                  content: Text(
                                      'The calculated dose is $doseInMl ml.\n จำนวนขวดยาที่ต้องให้ผู้ป่วย $_resultBottle'),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                      child: Text('OK'),
                                    ),
                                  ],
                                ),
                              );
                            }
                          },
                          child: Text('Calculate Dose'),
                        ),
                      ],
                    ),
                  ),
                )
              ],
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text("Error loading csv data: ${snapshot.error}"),
            );
          } else {
            return Center(
              child: CircularProgressIndicator(),
            );
          }
        },
      ),
    );
  }
}

Future<List<List<dynamic>>> loadCsvBoy() async {
  final String file =
      await rootBundle.loadString('assets/CSV/bmi_boy_utf8.csv');
  return CsvToListConverter().convert(file);
}

Future<List<List<dynamic>>> loadCsvGirl() async {
  final String file =
      await rootBundle.loadString('assets/CSV/bmi_girl_utf8.csv');
  return CsvToListConverter().convert(file);
}

Future<List<List<dynamic>>> loadCsv(gender) async {
  if (gender == Gender.male) {
    final String file =
        await rootBundle.loadString('assets/CSV/bmi_boy_utf8.csv');
    return CsvToListConverter().convert(file);
  } else {
    final String file =
        await rootBundle.loadString('assets/CSV/bmi_girl_utf8.csv');
    return CsvToListConverter().convert(file);
  }
}

class CalculationResult {
  final double childDose;
  final double bottleGiveToPatient;

  CalculationResult(
      {required this.childDose, required this.bottleGiveToPatient});
}

Future<CalculationResult> calculateR() async {
  _AdvancedChildCalculationState state = _AdvancedChildCalculationState();
  TextEditingController _heightController =
      _AdvancedChildCalculationState()._heightController;
  TextEditingController _weightController =
      _AdvancedChildCalculationState()._weightController;
  TextEditingController _ageController =
      _AdvancedChildCalculationState()._ageController;
  Gender? _gender = _AdvancedChildCalculationState()._gender;
  BuildContext context = _AdvancedChildCalculationState().context;

  if (_heightController.text.isEmpty ||
      _weightController.text.isEmpty | _ageController.text.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please enter Weight,Height,Age")));
  }
  double? height = double.parse(_heightController.text);
  double? weight = double.parse(_weightController.text);
  double? age = double.parse(_ageController.text);
  if (height == null || weight == null || age == null) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Invalid input please enter valid Weight,Height,Age.")));
  }

  MedicineProvider medicineProvider =
      Provider.of<MedicineProvider>(context, listen: false);
  medicineProvider.selectMedicine(medicineProvider.selectedMedicineId!);
  double _idealBodyWeight = await _AdvancedChildCalculationState()
      .calculateIdealBodyWeight(height, weight, age, _gender);

  double _childDose = await _AdvancedChildCalculationState()
      .calculateChildDose(_idealBodyWeight);
  double myBottleVolume =
      double.parse(_AdvancedChildCalculationState()._buttonVolume.text);
  int takeday = int.parse(_AdvancedChildCalculationState()._takeMedDay.text);
  double _bottleGiveTopatient =
      await state.bottle(_childDose, takeday, myBottleVolume);
  return CalculationResult(
      childDose: _childDose, bottleGiveToPatient: _bottleGiveTopatient);
}
