import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:file_picker/file_picker.dart';

// internal page
import 'medicine_provider.dart';
import 'medicine_list_page.dart';
import 'package:kiddose_for_pharmacists/upload_csv.dart';
import 'database.dart';
import 'advance_child_calculator.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper.instance.database;

  // Check if the database file exists
  String databasePath =
      await DatabaseHelper.instance.getDatabasePath("ChildDoseCalculator.db");
  File databaseFile = File(databasePath);
  print("Database file exists: ${await databaseFile.exists()}");
  runApp(
    ChangeNotifierProvider(
      create: (context) => MedicineProvider(),
      child: MaterialApp(
        home: HomePage(),
        debugShowCheckedModeBanner: false,
      ),
    ),
  );
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  final TextEditingController _weightController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _csvUploaded = false;
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getCSVUploaded(this.context);
    });
  }

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Child Dose Calculator'),
        actions: [
          IconButton(
            icon: Icon(Icons.list),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => MedicineListPage()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _weightController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Child weight (kg)'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the child\'s weight';
                  }
                  return null;
                },
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
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    double weight = double.parse(_weightController.text);
                    MedicineProvider medicineProvider =
                        context.read<MedicineProvider>();
                    double result = medicineProvider.calculateDose(weight);
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
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text(
                'Menu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.calculate_outlined),
              title: Text("คำนวณขนาดยาจาก ideal body weight"),
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: ((context) => AdvancedChildCalculation())));
              },
            ),
            ListTile(
              leading: Icon(Icons.list),
              title: Text('Medicine List'),
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => MedicineListPage()));
              },
            ),
            ListTile(
              leading: Icon(Icons.add),
              title: Text('Add Medicine'),
              onTap: () async {
                Navigator.pop(context);
                await _addMedicineDialog();
              },
            ),
            ListTile(
              leading: Icon(Icons.backup_sharp),
              title: Text('Create Backup database'),
              onTap: () async {
                Navigator.pop(context); //close drawer
                await _backupDatabase();
              },
            ),
            ListTile(
                leading: Icon(Icons.file_upload),
                title: Text("Import Backup File"),
                onTap: () {
                  Navigator.pop(context); //close the drawer
                  _importBackup(); //Call the import backup fx
                }),
          ],
        ),
      ),
    );
  }

  Future<void> _addMedicineDialog() async {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController doseController = TextEditingController();
    final TextEditingController concentrationController =
        TextEditingController();
    final TextEditingController frequencyController = TextEditingController();
    final GlobalKey<FormState> _addMedicineFormKey = GlobalKey<FormState>();

    showDialog(
      context: this.context,
      builder: (context) => AlertDialog(
        title: Text('Add Medicine'),
        content: SingleChildScrollView(
          child: Form(
            key: _addMedicineFormKey,
            child: Column(
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: 'Medicine Name'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a medicine name';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: doseController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: 'Medicine Dose'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a medicine dose';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: concentrationController,
                  keyboardType: TextInputType.number,
                  decoration:
                      InputDecoration(labelText: 'Medicine Concentration'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a medicine concentration';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: frequencyController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: 'Medicine Frequency'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a medicine frequency';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (_addMedicineFormKey.currentState!.validate()) {
                String name = nameController.text.trim();
                double dose = double.parse(doseController.text.trim());
                double concentration =
                    double.parse(concentrationController.text.trim());
                int frequency = int.parse(frequencyController.text.trim());
                context
                    .read<MedicineProvider>()
                    .addMedicine(name, dose, concentration, frequency);

                Navigator.of(context).pop();
              }
            },
            child: Text('Add'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _getCSVUploaded(BuildContext context) async {
    bool uploaded = await Provider.of<MedicineProvider>(context, listen: false)
        .getCSVUploaded();
    setState(() {
      _csvUploaded = uploaded;
    });
  }

  Future<void> _backupDatabase() async {
    PermissionStatus status = await Permission.storage.request();
    if (status.isGranted) {
      Directory? downloadsDir;

      if (Platform.isAndroid) {
        downloadsDir = await getExternalStorageDirectory();
        String downloadsPath =
            join(downloadsDir!.parent.parent.parent.parent.path, 'Download');
        downloadsDir = Directory(downloadsPath);
      } else if (Platform.isIOS) {
        downloadsDir = await getApplicationDocumentsDirectory();
      }

      if (downloadsDir != null) {
        final dbHelper = DatabaseHelper.instance;
        String databasePath =
            await dbHelper.getDatabasePath("ChildDoseCalculator.db");
        print("Data base path: $databasePath");

        String backupFolderPath = '${downloadsDir.path}/backup';
        Directory backupFolder = Directory(backupFolderPath);

        // Check if the backup folder exists, if not, create it
        if (!await backupFolder.exists()) {
          await backupFolder.create();
        }
        File databaseFile = File(databasePath);
        // Check if the source
        if (!await databaseFile.exists()) {
          print("Source file does not exit: $databasePath");
          return;
        }
        // Print directory for debug
        print("Source file:  $databasePath");
        print("Destination directory: $backupFolderPath");

        String backupFileName = 'child_dose_calculator_backup.db';

        String backupFilePath = '${backupFolder.path}/$backupFileName';

        File backupFile = File(backupFilePath);

        await databaseFile.copy(backupFile.path);

        ScaffoldMessenger.of(this.context).showSnackBar(
          SnackBar(
            content: Text('Database backup saved to: $backupFilePath'),
          ),
        );
      } else {
        ScaffoldMessenger.of(this.context).showSnackBar(
          SnackBar(
            content: Text('Unable to access the Download folder.'),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(this.context).showSnackBar(
        SnackBar(
          content: Text('Storage permission denied. Backup not saved.'),
        ),
      );
    }
  }

  Future<bool> _requestReadPermission() async {
    PermissionStatus status = await Permission.storage.request();
    if (!status.isGranted) {
      ScaffoldMessenger.of(this.context).showSnackBar(
        SnackBar(
          content: Text('Storage permission denied. Cannot import backup.'),
        ),
      );
    }
    return status.isGranted;
  }

  Future<File?> _pickBackupFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.any,
    );

    if (result != null) {
      String? filePath = result.files.single.path;
      String fileExtension = extension(filePath!).toLowerCase();
      if (fileExtension == '.db') {
        return File(filePath);
      } else {
        ScaffoldMessenger.of(this.context).showSnackBar(SnackBar(
          content: Text('Invalid file type. Please select a .db file.'),
        ));
        return null;
      }
    } else {
      return null;
    }
  }

  Future<void> _importBackup() async {
    bool readPermissionGranted = await _requestReadPermission();

    if (readPermissionGranted) {
      File? backupFile = await _pickBackupFile();

      if (backupFile != null) {
        await DatabaseHelper.instance.importBackupFile(backupFile);
        Provider.of<MedicineProvider>(this.context, listen: false).reloadData();
        ScaffoldMessenger.of(this.context).showSnackBar(
          SnackBar(
            content: Text('Backup imported successfully.'),
          ),
        );
      }
    }
  }
}
