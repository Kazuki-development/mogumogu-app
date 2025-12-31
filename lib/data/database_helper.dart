
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/food_item.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('fridge_keeper.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 3,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE food_items ADD COLUMN notificationSettings TEXT');
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE food_items ADD COLUMN customIcon TEXT');
      await db.execute('ALTER TABLE food_items ADD COLUMN orderIndex INTEGER');
    }
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const intType = 'INTEGER NOT NULL';
    const textNullable = 'TEXT';
    const intNullable = 'INTEGER';

    await db.execute('''
CREATE TABLE food_items ( 
  id $idType, 
  name $textType,
  purchaseDate $textType,
  expiryDate $textType,
  category $intType,
  imagePath $textNullable,
  notificationSettings $textNullable,
  customIcon $textNullable,
  orderIndex $intNullable
  )
''');
  }

  Future<FoodItem> create(FoodItem item) async {
    final db = await instance.database;
    final id = await db.insert('food_items', item.toMap());
    return item.copyWith(id: id);
  }

  Future<FoodItem> readFoodItem(int id) async {
    final db = await instance.database;
    final maps = await db.query(
      'food_items',
      columns: ['id', 'name', 'purchaseDate', 'expiryDate', 'category', 'imagePath', 'notificationSettings', 'customIcon', 'orderIndex'],
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return FoodItem.fromMap(maps.first);
    } else {
      throw Exception('ID $id not found');
    }
  }

  Future<List<FoodItem>> readAllFoodItems() async {
    final db = await instance.database;
    // Default sorting logic will be handled by ViewModel/App, but DB can return raw list
    // If orderIndex exists, sort by it? Or just return all and let VM sort. 
    // Let's return by orderIndex ASC, then expiryDate ASC
    final result = await db.query('food_items');
    return result.map((json) => FoodItem.fromMap(json)).toList();
  }

  Future<int> update(FoodItem item) async {
    final db = await instance.database;
    return db.update(
      'food_items',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await instance.database;
    return await db.delete(
      'food_items',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
