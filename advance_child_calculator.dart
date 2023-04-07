import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'medicine_provider.dart';
import 'dart:async' show Future;
import 'dart:convert' show utf8;
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
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  double? _idealBodyWeight;
  double? _childDose;
  Gender? _gender;
  Future<double> calculateIdealBodyWeight(
      double height, double weight, double age, _gender) async {
    if (age >= 1 || age <= 18) {
      double fat_bmi = await compareAgeWeight(age, weight, height, _gender);

      double height_in_m = height / 100;
      double bmi = weight / (height_in_m * height_in_m);
      if (fat_bmi > bmi) {
        double ibw = ((height * height) * 1.65) / 10000;
        return ibw;
      }
    } else if (age > 18 && _gender == Gender.male) {
      double height_in_feet = height * 0.03281;
      double ibw = 50 + (2.3 * height_in_feet);
      return ibw;
    } else if (age > 18 && _gender == Gender.female) {
      double height_in_feet = height * 0.03281;
      double ibw = 42.2 + (2.3 * height_in_feet);
      return ibw;
    } else {
      return weight;
    }
    return 0.0;
  }

  Future<double> calculateChildDose(double idealBodyWeight) async {
    MedicineProvider medicineProvider = MedicineProvider();
    double doseInMl = await medicineProvider.calculateDose(idealBodyWeight);
    print("####################");
    print("dose in ml $doseInMl");
    print("###############");
    return doseInMl;
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

    double _idealBodyWeight =
        await calculateIdealBodyWeight(height, weight, age, _gender);

    double _childDose = await calculateChildDose(_idealBodyWeight);

    return _childDose;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Advanced Child Calculation'),
      ),
      body: Padding(
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
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    double result = await calculate();
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('Calculated Dose'),
                        content: Text('The calculated dose is $result ml.'),
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
      ),
    );
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

  Future<double> compareAgeWeight(
      double age, double weight, double height, Gender _gender) async {
    final List<List<dynamic>> csvDataBoy = await loadCsvBoy();
    final List<List<dynamic>> csvDataGirl = await loadCsvGirl();
    double bmi = 0;
    if (_gender == Gender.male) {
      for (final List<dynamic> row in csvDataBoy) {
        if (row[0] == age) {
          bmi = row[1];
          return bmi;
        } else {
          bmi = weight / (height * height);
          return bmi;
        }
      }
      return bmi;
    } else {
      for (final List<dynamic> row in csvDataGirl) {
        if (row[0] == age) {
          bmi = row[1];
          return bmi;
        } else {
          bmi = weight / (height * height);
          return bmi;
        }
      }
      return bmi;
    }
  }
}
