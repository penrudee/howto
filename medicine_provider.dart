import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'database.dart';

class MedicineProvider with ChangeNotifier {
  List<Map<String, dynamic>> medicines = [];
  int? selectedMedicineId;
  double? dose;
  double? concentration;
  int? frequency;
  MedicineProvider() {
    loadMedicines();
  }

  void selectMedicine(int id) {
    selectedMedicineId = id;
    print("medicine id from Medicine provider =$selectedMedicineId");
    Map<String, dynamic> medicine = medicines.firstWhere((m) => m['id'] == id);
    dose = medicine['dose'];
    print("dose from selectMedicine $dose");
    concentration = medicine['concentration'];
    frequency = medicine['frequency'];
    notifyListeners();
  }

  void loadMedicines() async {
    final dbHelper = DatabaseHelper.instance;
    List<Map<String, dynamic>> medicineList = await dbHelper.queryAllRows();
    medicines = List<Map<String, dynamic>>.from(medicineList);
    notifyListeners();
  }

  Future<void> addMedicine(
      String name, double dose, double concentration, int frequency) async {
    final dbHelper = DatabaseHelper.instance;
    int id = await dbHelper.insert({
      'name': name,
      'dose': dose,
      'concentration': concentration,
      'frequency': frequency
    });
    Map<String, dynamic> newMedicine = {
      'id': id,
      'name': name,
      'dose': dose,
      'concentration': concentration,
      'frequency': frequency
    };
    medicines.add(newMedicine);
    notifyListeners();
  }

  double calculateDose(double weight) {
    print("From calculateDose in med provider file");
    print("Weight $weight");
    print("dose $dose");
    print("concentration: $concentration");
    print("frequency $frequency");
    if (dose != null && concentration != null && frequency != null) {
      return (weight * (dose ?? 0.0) / (concentration ?? 1.0)) /
          (frequency ?? 1);
    }
    return 0.00;
  }

  Future<void> editMedicine(int id, String name, double dose,
      double concentration, int frequency) async {
    final dbHelper = DatabaseHelper.instance;
    await dbHelper.update({
      'id': id,
      'name': name,
      'dose': dose,
      'concentration': concentration,
      'frequency': frequency,
    });
    loadMedicines();
  }

  Future<void> deleteMedicine(int id) async {
    final dbHelper = DatabaseHelper.instance;
    await dbHelper.delete(id);
    loadMedicines();
  }

  Future<void> setCSVUploaded(bool uploaded) async {
    final dbHelper = DatabaseHelper.instance;
    return await dbHelper.setCSVUploaded(uploaded);
  }

  Future<bool> getCSVUploaded() async {
    final dbHelper = DatabaseHelper.instance;
    return await dbHelper.getCSVUploaded();
  }

  void reloadData() {
    loadMedicines();
  }
}
