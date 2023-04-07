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
    _loadMedicines();
  }

  void selectMedicine(int id) {
    selectedMedicineId = id;
    Map<String, dynamic> medicine = medicines.firstWhere((m) => m['id'] == id);
    dose = medicine['dose'];
    concentration = medicine['concentration'];
    frequency = medicine['frequency'];
    notifyListeners();
  }

  void _loadMedicines() async {
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
    _loadMedicines();
  }

  Future<void> deleteMedicine(int id) async {
    final dbHelper = DatabaseHelper.instance;
    await dbHelper.delete(id);
    _loadMedicines();
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
    _loadMedicines();
  }
}
