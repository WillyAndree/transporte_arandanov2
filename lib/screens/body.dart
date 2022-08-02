// ignore_for_file: deprecated_member_use

import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:transporte_arandanov2/database/database.dart';
import 'package:transporte_arandanov2/screens/principal_page.dart';
import 'package:transporte_arandanov2/screens/viajes_list.dart';
import '../../constants.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

var name = "";
//var idtransp = 0;

class Body extends StatefulWidget {
  const Body({Key? key}) : super(key: key);
  @override
  _BodyState createState() => _BodyState();
}

class _BodyState extends State<Body> {
  String? nombre;
  String? idtransp;
  String? buscarTransportista;
  String? placa;
  TextEditingController? mycontrollerbuscar;
  _estadoSesion() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      name = (prefs.get("name") ?? "Usuario") as String;
      idtransp = (prefs.get("id") ?? "0") as String?;
      placa = (prefs.get("name") ?? "Usuario") as String?;
      print('ID: $idtransp');
    });
  }

  @override
  void initState() {
    super.initState();
    _estadoSesion();
  }

  Future<void> enviarBackup(String backup) async {
    try {
      showDialog(
          context: context,
          builder: (BuildContext context) {
            Size size = MediaQuery.of(context).size;
            return Center(
                child: AlertDialog(
                    backgroundColor: Colors.transparent,
                    content: Container(
                      color: Colors.white,
                      height: size.height / 7,
                      padding: const EdgeInsets.all(20),
                      child: Column(children: const <Widget>[
                        CircularProgressIndicator(),
                        SizedBox(height: 5),
                        Text("Subiendo Backup")
                      ]),
                    )));
          });
      final resulte = await InternetAddress.lookup('google.com');
      String results;
      if (resulte.isNotEmpty && resulte[0].rawAddress.isNotEmpty) {
        var response = await http.post(
            Uri.parse("${url_base}acp/index.php/transportearandano/setBackup"),
            body: {"backup": backup});
        //if (mounted) {
        setState(() {
          Navigator.pop(context);
          var extraerData = json.decode(response.body);
          results = extraerData["state"].toString();
          print("STATE: $results");
          if (results.toString().contains("true")) {
            print("backup subido correctamente");
            Widget okButton = TextButton(
              child: const Text("OK"),
              onPressed: () {
                Navigator.pop(context);
              },
            );
            showDialog(
                context: context,
                builder: (BuildContext context) {
                  return Center(
                      child: AlertDialog(
                          content: const Text('Backup subido correctamente'),
                          actions: [okButton]));
                });
          }
        });
      }
    } on Exception catch (e) {
      print('Error causador por: $e');
    }
  }

  Future openFile({required String url, String? fileName})async{
    //final name = fileName ?? url.split('/').last;
    final file = await downloadFile(url, fileName!);
    if( file == null) return;
    print('Path: ${file.path}');
    OpenFile.open(file.path);
  }

  Future<File?> downloadFile(String url, String name)async{
    try{

    final appStorage = await getApplicationDocumentsDirectory();
    final file = File('${appStorage.path}/$name');

    final response = await Dio().get(url, options: Options(responseType: ResponseType.bytes, followRedirects: false, receiveTimeout: 0));

    final raf = file.openSync(mode: FileMode.write);
    await raf.close();
    return file;

    }catch (e){
      return null;
    }

  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return WillPopScope(
        onWillPop: () {
          print("No puedes ir atras");
          // ignore: null_check_always_fails
          return null!;
        },
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                color: kPrimaryColor,
                height: size.height / 8,
                width: size.width,
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      GestureDetector(
                          child: Container(
                            margin: const EdgeInsets.only(left: 15, top: 40),
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(50),
                                image: const DecorationImage(
                                    image:
                                        AssetImage('assets/images/avatar.png'),
                                    fit: BoxFit.cover),
                                border:
                                    Border.all(color: kPrimaryColor, width: 2)),
                          ),
                          onTap: () {
                            showDialog(
                                context: context,
                                builder: (context) => const CustomDialogsLogout(
                                      title: "Sesión",
                                      description: "¿Deseas Cerrar Sesión?",
                                      imagen: "assets/images/dni.png",
                                    ));
                          }),
                      const SizedBox(
                        width: 20,
                      ),
                      GestureDetector(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            const SizedBox(
                              height: 50,
                            ),
                            Container(
                                alignment: Alignment.center,
                                child: Text(
                                  (nombre == null) ? name : nombre!,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold),
                                )),
                            Container(
                                alignment: Alignment.center,
                                child: const Text(
                                  'Transportista',
                                  style: TextStyle(color: Colors.white),
                                )),
                            Container(
                                alignment: Alignment.center,
                                child: const Text(
                                  'V.2.0',
                                  style: TextStyle(color: Colors.white),
                                ))
                          ],
                        ),
                        onTap: () {
                          showDialog(
                              context: context,
                              builder: (context) => const CustomDialogsLogout(
                                    title: "Sesión",
                                    description: "¿Deseas Cerrar Sesión?",
                                    imagen: "assets/images/dni.png",
                                  ));
                        },
                      ),
                      const SizedBox(
                        width: 20,
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const SizedBox(
                            height: 50,
                          ),
                          Container(
                              alignment: Alignment.center,
                              child: IconButton(
                                  onPressed: () async {
                                    showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          Size size = MediaQuery.of(context).size;
                                          return Center(
                                              child: AlertDialog(
                                                  backgroundColor: Colors.transparent,
                                                  content: Container(
                                                    color: Colors.white,
                                                    height: size.height / 7,
                                                    padding: const EdgeInsets.all(20),
                                                    child: Column(children: const <Widget>[
                                                      CircularProgressIndicator(),
                                                      SizedBox(height: 5),
                                                      Text("Descargando archivo")
                                                    ]),
                                                  )));
                                        });
                                    await openFile(url:'https://web.acpagro.com/apk/tarandano/transporte.apk',fileName: 'transporte.apk');
                                    Navigator.pop(context);

                                  },
                                  icon: const Icon(
                                    Icons.cloud_download,
                                    color: Colors.white,
                                  ))),
                        ],
                      ),
                    ]),
              ),
              const SizedBox(
                height: 10,
              ),
              SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: ListView(
                      scrollDirection: Axis.vertical,
                      shrinkWrap: true,
                      children: <Widget>[
                        MyStatelessWidget(),
                      ])),
              const SizedBox(height: kDefaultPadding),
            ],
          ),
        ));
  }
}

class FeaturePlantCard extends StatelessWidget {
  const FeaturePlantCard({
    Key? key,
    // this.image,
    this.press,
  }) : super(key: key);
  // final String image;
  final VoidCallback? press;

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return GestureDetector(
        onTap: press,
        child: Column(
          children: <Widget>[
            Container(
              margin: const EdgeInsets.only(
                top: kDefaultPadding / 2,
                bottom: kDefaultPadding / 2,
              ),
              width: size.width * 0.9,
              height: size.height / 2.5,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                // border: Border.all(color: Color(0xFFBC7C7C7), width: 1),
              ),
              child: Column(
                children: <Widget>[
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Container(
                        alignment: Alignment.topCenter,
                        margin: const EdgeInsets.only(left: 100),
                        child: const Text(
                          "Iniciar Sesión",
                          style: TextStyle(fontSize: 20),
                        ),
                      ),
                      Container(
                        alignment: Alignment.topRight,
                        margin: const EdgeInsets.only(left: 50),
                      )
                    ],
                  ),
                  const Center(
                    child: Text(
                      "ARANDANO - ACP",
                      style: TextStyle(fontSize: 10),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    alignment: Alignment.topLeft,
                    margin: const EdgeInsets.only(left: 20),
                    child: const Text("DNI", style: TextStyle(fontSize: 12)),
                  ),
                  const SizedBox(height: 15),
                  Row(children: <Widget>[
                    Container(
                        // alignment: Alignment.topRight,
                        // margin: EdgeInsets.only(right: 20),
                        decoration: BoxDecoration(
                            color: Colors.teal[700],
                            borderRadius: BorderRadius.circular(25)),
                        child: const IconButton(
                          icon: Icon(Icons.camera_alt),
                          onPressed: null,
                        ))
                  ]),
                  const SizedBox(height: 15),
                ],
              ),
            ),
          ],
        ));
  }
}

class CustomDialogsLogout extends StatelessWidget {
  final String? title, description, buttontext, imagen, nombre;
  final Image? image;

  const CustomDialogsLogout(
      {Key? key,
      this.title,
      this.description,
      this.buttontext,
      this.image,
      this.imagen,
      this.nombre})
      : super(key: key);
  _cerrarSesion() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString("sesion", "NO");
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
      elevation: 0,
      backgroundColor: Colors.white,
      child: dialogContents(context),
    );
  }

  dialogContents(BuildContext context) {
    return Stack(
      children: <Widget>[
        Container(
          padding: const EdgeInsets.only(bottom: 20, left: 20),
          margin: const EdgeInsets.only(top: 20),
          decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.circular(50),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10.0,
                  offset: Offset(0.0, 10.0),
                )
              ]),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Image.asset(
                imagen!,
                width: 64,
                height: 64,
              ),
              const SizedBox(height: 20.0),
              Text(
                title!,
                style: const TextStyle(
                  fontSize: 20.0,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Divider(),
              const SizedBox(height: 10.0),
              Text(
                description!,
                style: const TextStyle(fontSize: 16.0),
                textAlign: TextAlign.justify,
              ),
              const SizedBox(height: 24.0),
              Row(
                children: <Widget>[
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Container(
                      decoration: BoxDecoration(
                          color: kPrimaryColor,
                          shape: BoxShape.rectangle,
                          borderRadius: BorderRadius.circular(50),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 10.0,
                              offset: Offset(0.0, 10.0),
                            )
                          ]),
                      child: TextButton(
                          //color: kArandano,
                          onPressed: () {
                            //Navigator.pop(context);
                            _cerrarSesion();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const MyHomePage(),
                              ),
                            );
                          },
                          child: const Text(
                            "Cerrar Sesión",
                            style: TextStyle(color: Colors.white),
                          )),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Align(
                    alignment: Alignment.bottomLeft,
                    child: Container(
                      decoration: BoxDecoration(
                          color: kDarkSecondaryColor,
                          shape: BoxShape.rectangle,
                          borderRadius: BorderRadius.circular(50),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 10.0,
                              offset: Offset(0.0, 10.0),
                            )
                          ]),
                      child: TextButton(
                          //color: kArandano,
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text(
                            "Cancelar",
                            style: TextStyle(color: Colors.white),
                          )),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ],
    );
  }
}
