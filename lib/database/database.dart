// ignore_for_file: prefer_adjacent_string_concatenation

import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:transporte_arandanov2/model/acopios_model.dart';
import 'package:transporte_arandanov2/model/acopios_restantes_model.dart';
import 'package:transporte_arandanov2/model/consumidores_model.dart';
import 'package:transporte_arandanov2/model/intro_model.dart';
import 'package:transporte_arandanov2/model/jabas_model.dart';
import 'package:transporte_arandanov2/model/user_model.dart';
import 'package:sqflite/sql.dart';
import 'dart:convert' as convert;
import 'package:sqflite/sqlite_api.dart';
import 'package:transporte_arandanov2/model/variedades_model.dart';

class DatabaseProvider {
  DatabaseProvider._();

  static final DatabaseProvider db = DatabaseProvider._();
  Database? _database;
  String? tempPath;
  List<String> tables = ['jabas'];
  //para evitar que abra varias conexciones una y otra vez podemos usar algo como esto..
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await getDatabaseInstanace();
    return _database!;
  }

  Future<Database> getDatabaseInstanace() async {
    Directory directory = await getApplicationDocumentsDirectory();
    String path = join(directory.path, "transportes.db");
    return await openDatabase(path, version: 3,
        onCreate: (Database db, int version) async {
      await db.execute("CREATE TABLE user("
          "id integer primary key,"
          "name varchar(200),"
          "placa varchar(50),"
          "capacidad integer,"
          "dni varchar(8)"
          ")");
      await db.execute("CREATE TABLE jabas("
          "idviaje integer,"
          "lat varchar(200),"
          "long varchar(200),"
          "alias varchar(200),"
          "estado integer,"
          "jabascargadas integer,"
          "descripcion varchar(200),"
          "fllegada varchar(100),"
          "nacional integer,"
          "exportable integer,"
          "desmedro integer,"
          "frutac integer,"
          "variedad varchar(100),"
          "condicion varchar(100),"
          "consumidor varchar(50),"
          "valvula varchar(20),"
          "observaciones varchar(200)"
          ")");
      await db.execute("CREATE TABLE consumidores("
          "idlugar integer,"
          "consumidor varchar(100)"
          ")");
      await db.execute("CREATE TABLE variedades("
          "idconsumidor varchar(100),"
          "descripcion varchar(100)"
          ")");
      await db.execute("CREATE TABLE acopios("
          "idviaje integer,"
          "alias varchar(100),"
          "latitud varchar(200),"
          "longitud varchar(200),"
          "cantidadjabas integer,"
          "descripcion varchar(100),"
          "idlugar integer"
          ")");

      await db.execute("CREATE TABLE acopiosrestantes("
          "modulo varchar(10),"
          "name varchar(100),"
          "alias varchar(100),"
          "latitud varchar(200),"
          "longitud varchar(200),"
          "cantidadjabas integer,"
          "descripcion varchar(100),"
          "idlugar integer"
          ")");
    });
  }

  Future<void> getDatabaseInstanaceDelete() async {
    Directory directory = await getApplicationDocumentsDirectory();
    String path = join(directory.path, "transportes.db");
    await deleteDatabase(path);
  }

  //Query
  //muestra todos los clientes de la base de datos
  Future<List<User>> getAllUsers() async {
    final db = await database;
    var response = await db.query("user");
    List<User> list = response.map((c) => User.fromMap(c)).toList();
    return list;
  }

  Future<List<Intro>> getAllIntro() async {
    final db = await database;
    var response = await db.query("intro");
    List<Intro> list = response.map((c) => Intro.fromMap(c)).toList();
    return list;
  }

  addIntroToDatabase(Intro intro) async {
    final db = await database;
    /*var table = await db.rawQuery("SELECT MAX(id)+1 as id FROM user");
    int id = table.first["id"];
    user.id = id;*/
    var raw = await db.insert(
      "intro",
      intro.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return raw;
  }

/*
  Future<User> getUserWithLoginAndPass(String dni) async {
    final db = await database;
    var response = await db.query("user", where: "dni = ?", whereArgs: [dni]);
    return response.isNotEmpty ? User.fromMap(response.first) : null;
  }*/

  //Delete all clients
  Future<void> deleteDatabase(String path) =>
      databaseFactory.deleteDatabase(path);

  //Query
  //muestra un solo cliente por el id la base de datos
  Future<User?> getUserWithId(int id) async {
    final db = await database;
    var response = await db.query("user", where: "id = ?", whereArgs: [id]);
    return response.isNotEmpty ? User.fromMap(response.first) : null;
  }

  Future<List<User>> getUserWithLoginAndPass(String dni) async {
    var db = await database;
    List<User> usersList = [];
    List<Map> queryList =
        await db.query("user", where: "dni = ?", whereArgs: [dni]);
    print('[DBUser] getUser: ${queryList.length} users');
    if (queryList.isNotEmpty) {
      for (int i = 0; i < queryList.length; i++) {
        usersList.add(User(
          id: queryList[i]['id'],
          name: queryList[i]['name'],
          capacidad: queryList[i]['capacidad'],
          dni: queryList[i]['dni'],
          placa: queryList[i]['placa'],
        ));
      }
      print('[DBUser] getUser: ${usersList[0].placa}');
      return usersList;
    } else {
      print('[DBUser] getUser: User is null');
      return [];
    }
  }

/*
  Future<User> getUserWithLoginAndPass(String dni) async {
    final db = await database;
    var response = await db.query("user", where: "dni = ?", whereArgs: [dni]);
    return response.isNotEmpty ? User.fromMap(response.first) : null;
  }*/

  //Insert
  addUserToDatabase(User user) async {
    final db = await database;
    /*var table = await db.rawQuery("SELECT MAX(id)+1 as id FROM user");
    int id = table.first["id"];
    user.id = id;*/
    var raw = await db.insert(
      "user",
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return raw;
  }

  addConsumidoresToDatabase(Consumidores consumidores) async {
    final db = await database;

    var raw = await db.insert(
      "consumidores",
      consumidores.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return raw;
  }

  addVariedadesToDatabase(Variedades variedades) async {
    final db = await database;

    var raw = await db.insert(
      "variedades",
      variedades.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return raw;
  }

  addAcopiosToDatabase(Acopios acopios) async {
    final db = await database;

    var raw = await db.insert(
      "acopios",
      acopios.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return raw;
  }

  Future<List<Consumidores>> getConsumidorWithIdLugar(int idlugar) async {
    var db = await database;
    List<Consumidores> consumidoresList = [];
    List<Map> queryList = await db
        .query("consumidores", where: "idlugar = ?", whereArgs: [idlugar]);
    print('[DBConsumidores] getConsumidores: ${queryList.length} consumidores');
    if (queryList.isNotEmpty) {
      for (int i = 0; i < queryList.length; i++) {
        consumidoresList.add(Consumidores(
          idlugar: queryList[i]['idlugar'],
          consumidor: queryList[i]['consumidor'],
        ));
      }
      print(
          '[DBConsumidores] getConsumidores: ${consumidoresList[0].consumidor}');
      return consumidoresList;
    } else {
      print('[DBConsumidores] getConsumidores: Consumidores is null');
      return [];
    }
  }

  Future<List<Variedades>> getVariedadWithIdConsumidor(
      String consumidor) async {
    var db = await database;
    List<Variedades> variedadesList = [];
    List<Map> queryList = await db.query("variedades",
        where: "trim(idconsumidor) = ?", whereArgs: [consumidor]);
    print('[DBVariedades] getVariedades: ${queryList.length} descripcion');
    if (queryList.isNotEmpty) {
      for (int i = 0; i < queryList.length; i++) {
        variedadesList.add(Variedades(
          idconsumidor: queryList[i]['idconsumidor'],
          descripcion: queryList[i]['descripcion'],
        ));
      }
      print('[DBVariedades] getVariedades: ${variedadesList[0].descripcion}');
      return variedadesList;
    } else {
      print('[DBVariedades] getVariedades: Variedades is null');
      return [];
    }
  }

  Future<List<Variedades>> getVariedadWithTotal() async {
    var db = await database;
    List<Variedades> variedadesList = [];
    List<Map> queryList = await db.query("variedades");
    print('[DBVariedades] getVariedades: ${queryList.length} descripcion');
    if (queryList.isNotEmpty) {
      for (int i = 0; i < queryList.length; i++) {
        variedadesList.add(Variedades(
          idconsumidor: queryList[i]['idconsumidor'],
          descripcion: queryList[i]['descripcion'],
        ));
      }
      print('[DBVariedades] getVariedades: ${variedadesList[0].descripcion}');
      return variedadesList;
    } else {
      print('[DBVariedades] getVariedades: Variedades is null');
      return [];
    }
  }


  Future<String> generateBackup({bool isEncrypted = false}) async {
    print('GENERATE BACKUP');

    var dbs = await database;

    List data = [];

    List<Map<String, dynamic>> listMaps = [];

    for (var i = 0; i < tables.length; i++) {
      listMaps = await dbs.query(tables[i]);

      data.add(listMaps);
    }

    List backups = [tables, data];

    String json = convert.jsonEncode(backups);
    print("BACKUP:" + json);
    return json;
  }

  //Delete
  //Delete client with id
  deleteUserWithId(int id) async {
    final db = await database;
    return db.delete("user", where: "id = ?", whereArgs: [id]);
  }

  //Delete all clients
  deleteAllUser() async {
    final db = await database;
    db.delete("user");
  }

  deleteAllAcopios() async {
    final db = await database;
    db.delete("acopios");
  }

  deleteAllConsumidores() async {
    final db = await database;
    db.delete("consumidores");
  }

  deleteAllVariedades() async {
    final db = await database;
    db.delete("variedades");
  }

  //Update
  updateUser(User user) async {
    final db = await database;
    var response = await db
        .update("user", user.toMap(), where: "id = ?", whereArgs: [user.id]);
    return response;
  }

  Future<int> updateJabasViaje(int idviaje, String alias) async {
    var db = await database;
    int count = await db.rawUpdate(
        'UPDATE jabas SET estado= ? WHERE idviaje = ? and alias = ?',
        [1, idviaje, alias]);
    print('updated: $count');
    return count;
  }

  Future<int> updateJabasViaje2(int idviaje) async {
    var db = await database;
    int count = await db.rawUpdate(
        'UPDATE jabas SET estado= ? WHERE idviaje = ? ',
        [1, idviaje]);
    print('updated: $count');
    return count;
  }

  Future<int> insertAcopios(int idviajes, int cantidadjabas,String alias, String latitud, String longitud, String descripcion, int idlugar) async {
    var db = await database;
    int count = 0;
    List<Map> queryList =
    await db.rawQuery("select * from acopios where idviaje = ? and alias = ?", [idviajes,alias]);
    print('[ACOPIOS] getAcopio: ${queryList.length} acopios');
    if (queryList.isNotEmpty) {
       count = await db.rawUpdate(
          'UPDATE acopios SET alias = ?, latitud = ?, longitud = ?, cantidadjabas = ?, descripcion = ?, idlugar = ? where idviaje = ?',
          [alias,latitud, longitud, cantidadjabas, descripcion, idlugar, idviajes]);
      print('updated: $count');
    }else{
      count = await db.rawInsert(
          'INSERT INTO acopios(idviaje,alias, latitud, longitud, cantidadjabas, descripcion, idlugar) values(?,?,?,?,?,?,?)',
          [idviajes,alias, latitud, longitud, cantidadjabas, descripcion, idlugar]);
      print('insert: $count');
    }
    return count;
  }

  Future<int> insertAcopiosRestantes(String modulo, int cantidadjabas,String alias, String latitud, String longitud, String descripcion, int idlugar, String name) async {
    var db = await database;
    int count = 0;
    List<Map> queryList =
    await db.rawQuery("select * from acopiosrestantes where modulo = ? and alias = ?", [modulo, alias]);
    print('[ACOPIOS] getAcopioRestantes: ${queryList.length} acopiosrestantes');
    if (queryList.isNotEmpty) {
      count = await db.rawUpdate(
          'UPDATE acopiosrestantes SET alias = ?, name = ?, latitud = ?, longitud = ?, cantidadjabas = ?, descripcion = ?, idlugar = ? where modulo = ?',
          [alias, name, latitud, longitud, cantidadjabas, descripcion, idlugar, modulo]);
      print('updated: $count');
    }else{
      count = await db.rawInsert(
          'INSERT INTO acopiosrestantes(modulo,alias, name, latitud, longitud, cantidadjabas, descripcion, idlugar) values(?,?,?,?,?,?,?,?)',
          [modulo,alias,name, latitud, longitud, cantidadjabas, descripcion, idlugar]);
      print('insertrestantes: $count');
    }
    return count;
  }

  Future<List<Jabas>> getAllJabas() async {
    final db = await database;
    var response = await db.query("jabas");
    List<Jabas> list = response.map((c) => Jabas.fromMap(c)).toList();
    return list;
  }

  Future<List<Variedades>> getAllCons() async {
    final db = await database;
    var response = await db.query("variedades");
    List<Variedades> list = response.map((c) => Variedades.fromMap(c)).toList();
    return list;
  }

  Future<List<Jabas>> getJabasWithId(int idviaje, String alias) async {
    var db = await database;
    List<Jabas> jabasList = [];
    List<Map> queryList = await db.rawQuery(
        "select sum(jabascargadas) as jabascargadas, idviaje,  case when lat is null then '00.00000' else lat end as lat, case when long is null then '00.00000' else long end as long, alias, estado, case when descripcion is null then '-' else descripcion end as descripcion, fllegada from jabas where idviaje = ? and alias = ? and estado  = 0",
        [idviaje, alias]);
    //print('[DBJabas] getJabas: ${queryList.length} jabas');
    if (queryList.isNotEmpty) {
      for (int i = 0; i < queryList.length; i++) {
        jabasList.add(Jabas(
            idviaje: queryList[i]['idviaje'],
            lat: queryList[i]['lat'],
            long: queryList[i]['long'],
            alias: queryList[i]['alias'],
            estado: queryList[i]['estado'],
            jabascargadas: queryList[i]['jabascargadas'],
            descripcion: queryList[i]['descripcion'],
            fllegada: queryList[i]['fllegada']));
      }
      print('[DBJabas] getJabas: ${jabasList[0].jabascargadas}');
      return jabasList;
    } else {
      print('[DBJabas] getJabas: Jabas is null');

      return [];
    }
  }

  Future<List<Acopios>> getCantidadAcopios(int idviaje) async {
    var db = await database;
    List<Acopios> acopiosList = [];
    List<Map> queryList = await db.rawQuery(
        "select idviaje, alias, cantidadjabas, latitud, longitud, descripcion, idlugar from acopios where idviaje = ?",
        [idviaje]);
    //print('[DBAcopios] getAcopios: ${queryList.length} acopios');
    if (queryList.isNotEmpty) {
      for (int i = 0; i < queryList.length; i++) {
        acopiosList.add(Acopios(
            idviaje: queryList[i]['idviaje'],
            alias: queryList[i]['alias'],
            cantidadjabas: queryList[i]['cantidadjabas'],
            latitud: queryList[i]['latitud'],
            longitud: queryList[i]['longitud'],
            descripcion: queryList[i]['descripcion'],
            idlugar: queryList[i]['idlugar']));
      }
      //print('[DBAcopios] getAcopios: ${acopiosList[0].cantidadjabas}');
      return acopiosList;
    } else {
     // print('[DBAcopios] getAcopios: Acopios is null');

      return [];
    }
  }

  Future<List<AcopiosRestantes>> getCantidadAcopiosRestantes(String modulo) async {
    var db = await database;
    List<AcopiosRestantes> acopiosRestantesList = [];
    List<Map> queryList = await db.rawQuery(
        "select modulo,name,alias, cantidadjabas, latitud, longitud, descripcion, idlugar from acopiosrestantes where modulo = ?",
        [modulo]);
    //print('[DBAcopios] getAcopios: ${queryList.length} acopios');
    if (queryList.isNotEmpty) {
      for (int i = 0; i < queryList.length; i++) {
        acopiosRestantesList.add(AcopiosRestantes(
            modulo: queryList[i]['modulo'],
            name: queryList[i]['name'],
            alias: queryList[i]['alias'],
            cantidadjabas: queryList[i]['cantidadjabas'],
            latitud: queryList[i]['latitud'],
            longitud: queryList[i]['longitud'],
            descripcion: queryList[i]['descripcion'],
            idlugar: queryList[i]['idlugar']));
      }
      //print('[DBAcopios] getAcopios: ${acopiosList[0].cantidadjabas}');
      return acopiosRestantesList;
    } else {
      // print('[DBAcopios] getAcopios: Acopios is null');

      return [];
    }
  }

  Future<List<Jabas>> getJabasWithoutAlias2(int idviaje) async {
    var db = await database;
    List<Jabas> jabasList = [];
    List<Map> queryList =
    await db.query("jabas", where: "idviaje = ? and estado = ?", whereArgs: [idviaje, 0]);
    print('[DBUser] getJabas: ${queryList.length} jabas');
    if (queryList.isNotEmpty) {
      for (int i = 0; i < queryList.length; i++) {
        jabasList.add(Jabas(
          idviaje: queryList[i]['idviaje'],
          lat: queryList[i]['lat'],
          long: queryList[i]['long'],
          alias: queryList[i]['alias'],
          jabascargadas: queryList[i]['jabascargadas'],
          descripcion: queryList[i]['descripcion'],
          fllegada: queryList[i]['fllegada'],
          exportable: queryList[i]['exportable'],
          nacional: queryList[i]['nacional'],
          desmedro: queryList[i]['desmedro'],
          frutac: queryList[i]['frutac'],
          variedad: queryList[i]['variedad'],
          condicion: queryList[i]['condicion'],
          consumidor: queryList[i]['consumidor'],
          valvula: queryList[i]['valvula'],
          observaciones: queryList[i]['observaciones'],
        ));
        print('[DBJabasXML] getJabas: ${jabasList[i].alias}');
      }
      print('[DBJabas] getJabas: Jabas is null');
      return jabasList;
    } else {
      print('[DBUser] getUser: User is null');
      return [];
    }
  }

  Future<List<Jabas>> getJabasTotalViajes() async {
    var db = await database;
    List<Jabas> jabasList = [];
    List<Map> queryList =
    await db.query("jabas", where: "estado = ?", whereArgs: [0]);
    print('[DBUser] getJabas: ${queryList.length} jabas');
    if (queryList.isNotEmpty) {
      for (int i = 0; i < queryList.length; i++) {
        jabasList.add(Jabas(
          idviaje: queryList[i]['idviaje'],
          lat: queryList[i]['lat'],
          long: queryList[i]['long'],
          alias: queryList[i]['alias'],
          jabascargadas: queryList[i]['jabascargadas'],
          descripcion: queryList[i]['descripcion'],
          fllegada: queryList[i]['fllegada'],
          exportable: queryList[i]['exportable'],
          nacional: queryList[i]['nacional'],
          desmedro: queryList[i]['desmedro'],
          frutac: queryList[i]['frutac'],
          variedad: queryList[i]['variedad'],
          condicion: queryList[i]['condicion'],
          consumidor: queryList[i]['consumidor'],
          valvula: queryList[i]['valvula'],
          observaciones: queryList[i]['observaciones'],
        ));
        print('[DBJabasXML] getJabas: ${jabasList[i].alias}');
      }
      print('[DBJabas] getJabas: Jabas is null');
      return jabasList;
    } else {
      print('[DBUser] getUser: User is null');
      return [];
    }
  }

  Future<List<Jabas>> getJabasWithoutAlias(int idviaje) async {
    var db = await database;
    List<Jabas> jabasList = [];
    List<Map> queryList = await db.rawQuery(
        "select jabascargadas, idviaje, case when lat is null then '00.00000' else lat end as lat, case when long is null then '00.00000' else long end as long, alias, descripcion, fllegada, case when exportable is null then 0 else exportable end as exportable,case when nacional is null then 0 else nacional end as nacional, case when desmedro is null then 0 else desmedro end as desmedro,case when frutac is null then 0 else frutac end as frutac, case when variedad is null then '-' else variedad end as variedad, case when condicion is null then '-' else condicion end as condicion,case when consumidor is null then '-' else consumidor end as consumidor, case when valvula is null then '-' else valvula end as valvula, case when observaciones is null then '-' else observaciones end as observaciones from jabas where estado = 0 and idviaje = ?",
        [idviaje]);
    print('[DBJabas] getJabas: ${queryList.length} jabas');
    if (queryList.isNotEmpty) {
      for (int i = 0; i < queryList.length; i++) {
        jabasList.add(Jabas(
            idviaje: queryList[i]['idviaje'],
            lat: queryList[i]['lat'],
            long: queryList[i]['long'],
            alias: queryList[i]['alias'],
            jabascargadas: queryList[i]['jabascargadas'],
            descripcion: queryList[i]['descripcion'],
            fllegada: queryList[i]['fllegada'],
            exportable: queryList[i]['exportable'],
            nacional: queryList[i]['nacional'],
            desmedro: queryList[i]['desmedro'],
            frutac: queryList[i]['frutac'],
            variedad: queryList[i]['variedad'],
            condicion: queryList[i]['condicion'],
            consumidor: queryList[i]['consumidor'],
            valvula: queryList[i]['valvula'],
            observaciones: queryList[i]['observaciones']));
        print('[DBJabasXML] getJabas: ${jabasList[i].lat}');
      }

      return jabasList;
    } else {
      print('[DBJabas] getJabas: Jabas is null');
      return [];
    }
  }

  Future<List<Jabas>> getJabasSubidas(int idviaje) async {
    var db = await database;
    List<Jabas> jabasList = [];
    List<Map> queryList = await db.rawQuery(
        "select jabascargadas, idviaje, case when lat is null then '00.00000' else lat end as lat, case when long is null then '00.00000' else long end as long, alias, descripcion, fllegada, case when exportable is null then 0 else exportable end as exportable,case when nacional is null then 0 else nacional end as nacional, case when desmedro is null then 0 else desmedro end as desmedro,case when frutac is null then 0 else frutac end as frutac, case when variedad is null then '-' else variedad end as variedad, case when condicion is null then '-' else condicion end as condicion,case when consumidor is null then '-' else consumidor end as consumidor, case when valvula is null then '-' else valvula end as valvula, case when observaciones is null then '-' else observaciones end as observaciones from jabas where estado = 1 and idviaje = ?",
        [idviaje]);
    print('[DBJabas] getJabas: ${queryList.length} jabas');
    if (queryList.isNotEmpty) {
      for (int i = 0; i < queryList.length; i++) {
        jabasList.add(Jabas(
            idviaje: queryList[i]['idviaje'],
            lat: queryList[i]['lat'],
            long: queryList[i]['long'],
            alias: queryList[i]['alias'],
            jabascargadas: queryList[i]['jabascargadas'],
            descripcion: queryList[i]['descripcion'],
            fllegada: queryList[i]['fllegada'],
            exportable: queryList[i]['exportable'],
            nacional: queryList[i]['nacional'],
            desmedro: queryList[i]['desmedro'],
            frutac: queryList[i]['frutac'],
            variedad: queryList[i]['variedad'],
            condicion: queryList[i]['condicion'],
            consumidor: queryList[i]['consumidor'],
            valvula: queryList[i]['valvula'],
            observaciones: queryList[i]['observaciones']));
      }
      print('[DBJabas] getJabas: ${jabasList[0].lat}');
      return jabasList;
    } else {
      print('[DBJabas] getJabas: Jabas is null');
      return [];
    }
  }

  Future<List<Jabas>> getJabasAll() async {
    var db = await database;
    List<Jabas> jabasList = [];
    List<Map> queryList = await db
        .rawQuery("select sum(jabascargadas) as jabascargadas from jabas");
    print('[DBJabas] getJabas: ${queryList.length} jabas');
    if (queryList.isNotEmpty) {
      for (int i = 0; i < queryList.length; i++) {
        jabasList.add(Jabas(jabascargadas: queryList[i]['jabascargadas']));
      }
      print('[DBJabas] getJabas: ${jabasList[0].jabascargadas}');
      return jabasList;
    } else {
      print('[DBJabas] getJabas: Jabas is null');
      return [];
    }
  }

  Future<List<Jabas>> getJabasSumViajes(int idviaje) async {
    var db = await database;
    List<Jabas> jabasList = [];
    List<Map> queryList = await db.rawQuery(
        "select sum(jabascargadas) as jabascargadas from jabas where idviaje = ? ",
        [idviaje]);
    print('[DBJabas] getJabas: ${queryList.length} jabas');
    if (queryList.isNotEmpty) {
      for (int i = 0; i < queryList.length; i++) {
        jabasList.add(Jabas(jabascargadas: queryList[i]['jabascargadas']));
      }
      print('[DBJabas] getJabas: ${jabasList[0].lat}');
      return jabasList;
    } else {
      print('[DBJabas] getJabas: Jabas is null');
      return [];
    }
  }

  addJabasToDatabase(Jabas jabas) async {
    final db = await database;
    var raw = 0;
    raw = await db.insert(
      "jabas",
      jabas.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return raw;
  }

  //Delete
  //Delete client with id
  deleteJabasWithId(int idviaje) async {
    final db = await database;
    return db.delete("jabas", where: "idviaje = ?", whereArgs: [idviaje]);
  }

  /*deleteJabasWithAlias(String alias) async {
    final db = await database;
    return db.delete("jabas", where: "alias = ?", whereArgs: [alias]);
  }*/

  //Delete all clients
  deleteAllJabas() async {
    final db = await database;
    db.delete("transportes");
  }
}
