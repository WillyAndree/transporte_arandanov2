// ignore_for_file: prefer_typing_uninitialized_variables, deprecated_member_use

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:transporte_arandanov2/screens/ruteo2.dart';
import 'package:transporte_arandanov2/screens/second_page.dart';
import '../constants.dart';

String? moduloselect;
class MyBottomNavBar extends StatelessWidget {
  const MyBottomNavBar({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(
        left: kDefaultPadding * 2,
        right: kDefaultPadding * 2,
        bottom: kDefaultPadding,
      ),
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, -10),
            blurRadius: 35,
            color: kPrimaryColor.withOpacity(0.38),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          IconButton(
            icon: const Icon(
              Icons.home,
              color: Colors.black,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SecondPage(),
                ),
              );
            },
          ),
          FloatingActionButton(
            onPressed: () {
              showDialog(
                  context: context,
                  builder: (context) => const CustomDialogsBuscar(
                      title: "GENERAR RUTA",
                      description:
                          'Selecciona el módulo en el que iniciarás el recojo de fruta',
                      imagen: "assets/images/distance.png"));
            },
            child: const Icon(
              Icons.search,
              color: Colors.white,
            ),
            backgroundColor: kPrimaryColor,
          ),
          IconButton(
            icon: const Icon(
              Icons.add_box_sharp,
              color: Colors.black,
            ),
            onPressed: () {
              /*Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => Login(),
                ),
              );*/
            },
          ),
        ],
      ),
    );
  }
}

class CustomDialogsBuscar extends StatefulWidget {
  final String? title, description, imagen;
  const CustomDialogsBuscar(
      {Key? key, this.title, this.description, this.imagen})
      : super(key: key);

  @override
  _CustomDialogsBuscarState createState() => _CustomDialogsBuscarState();
}

class _CustomDialogsBuscarState extends State<CustomDialogsBuscar> {
  int capacidadVehiculo = 900;
  // ignore: non_constant_identifier_names
  int cantidad_jabas = 0;
  List? data;
  var result;
  double? latitudes, longitudes;
  String? aliasinicial;
  List? dataestado;
  String? dropdownValue;
  var dataacopio;
  int total = 0;
  String? actividad;
  var ddData = [];
  String? idtransp;

  _guardarModulo(String modulo) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString("modulo", modulo);
  }

  Future<void> recibirDatos(
    String modulo,
  ) async {
    var extraerData;
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
                      Text("Buscando acopios")
                    ]),
                  )));
        });
    print("MODULO ENVIADO: "+modulo);
    var response = await http.get(
        Uri.parse(url_base +
            "WSPowerBI/controller/transportearandano.php?accion=puntoiniciomanual&modulo=" +
            modulo),
        headers: {"Accept": "application/json"});
    setState(() {
      extraerData = json.decode(response.body);
      data = extraerData["datos"];
      dataacopio = json.encode(extraerData["datos"]);
      print("ddata" + dataacopio.toString());
      aliasinicial = data![0]["ALIAS"];
      for (var i = 0; i < data!.length; i++) {
        cantidad_jabas = int.parse(data![i]["CANTIDAD_JABAS"]);
        latitudes = double.parse(data![i]["LATITUD"]);
        longitudes = double.parse(data![i]["LONGITUD"]);

        if (total <= capacidadVehiculo && cantidad_jabas > 0) {
          print("CANT JABAS" + cantidad_jabas.toString());
          var objeto = {"ALIAS": data![i]["ALIAS"]};
          total += cantidad_jabas;
          ddData.add(objeto);
        }
      }
    });
    Navigator.pop(context);
  }

  Future<void> atualizarAcopios(String pacopios, int tipo) async {
    var response = await http.get(
        Uri.parse(url_base +
            "acp/index.php/transportearandano/setAcopios?accion=estado&alias=" +
            pacopios +
            "&tipo=" +
            tipo.toString()),
        headers: {"Accept": "application/json"});
    if (mounted) {
      setState(() {
        var extraerData = json.decode(response.body);
        result = extraerData["state"];
        //  print("RESULTADO: " + result.toString());
      });
    }
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
          padding: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
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
                widget.imagen!,
                width: 64,
                height: 64,
              ),
              const SizedBox(height: 20.0),
              Text(
                widget.title!,
                style: const TextStyle(
                  fontSize: 24.0,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Divider(),
              const SizedBox(height: 10.0),
              Text(
                widget.description!,
                style: const TextStyle(fontSize: 15.0),
                //textAlign: TextAlign.justify,
              ),
              const SizedBox(
                height: 10,
              ),
              DropdownButton<String>(
                value: dropdownValue,
                icon: const Icon(Icons.arrow_downward),
                iconSize: 24,
                elevation: 16,
                hint: const Text('Selecciona el módulo'),
                style: const TextStyle(color: Colors.deepPurple),
                underline: Container(
                  height: 2,
                  color: Colors.deepPurpleAccent,
                ),
                onChanged: (String? newValue) {
                  setState(() {
                    dropdownValue = newValue;
                  });
                },
                items: <String>[
                  "MODULO 01",
                  "MODULO 02",
                  "MODULO 03",
                  "MODULO 04",
                  "MODULO 05",
                  "MODULO 06",
                  "MODULO 07",
                  "MODULO 08",
                  "MODULO 09",
                  "MODULO 10",
                  "MODULO 11",
                ].map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                      value: value, child: Text(value));
                }).toList(),
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
                      child: FlatButton(
                          onPressed: () async {
                            String? actividad;
                            print(
                                "VALOR DROPDOWN: " + dropdownValue.toString());
                            // ignore: unnecessary_null_comparison
                            if (dropdownValue == null) {
                              showDialog(
                                  context: context,
                                  builder: (context) =>
                                      const CustomDialogsActividad(
                                          title: "MENSAJE",
                                          description:
                                              'Debes Seleccionar un módulo de destino',
                                          imagen: "assets/images/warning.png"));
                            } else {
                              SharedPreferences prefs =
                                  await SharedPreferences.getInstance();
                              setState(() {
                                idtransp = (prefs.get("id") ?? "0") as String?;
                                capacidad = (prefs.get("capacidad_vehiculo") ??
                                    "0") as int?;
                                placa = (prefs.get("placa") ?? "0") as String?;
                                print('placa: ' + placa.toString());
                                print('idtransp: ' + idtransp.toString());
                              });
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
                                              child: Column(
                                                  children: const <Widget>[
                                                    CircularProgressIndicator(),
                                                    SizedBox(height: 5),
                                                    Text(
                                                        "Buscando viajes sin terminar")
                                                  ]),
                                            )));
                                  });
                              var responsess = await http.get(
                                  Uri.parse(url_base +
                                      "WSPowerBI/controller/transportearandano.php?accion=estadoviaje&idtransp=" +
                                      idtransp!),
                                  headers: {"Accept": "application/json"});
                              if (mounted) {
                                setState(() {
                                  var extraerData =
                                      json.decode(responsess.body);
                                  dataestado = extraerData["datos"];
                                  actividad = dataestado![0]["actividad"];
                                });
                              }
                              print("ESTADO RUTEO: " +
                                  actividad.toString() +
                                  " TRANSP. " +
                                  idtransp!);
                              Navigator.pop(context);
                              if (actividad == "LIBRE") {
                                moduloselect = dropdownValue.toString().substring(7);
                                _guardarModulo(moduloselect!);
                                await recibirDatos(moduloselect!
                                    );
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => GMap(
                                        data: data!,
                                        dataacopio: dataacopio,
                                        latinicial: latitudes!,
                                        longinicial: longitudes!,
                                        aliasinicial: aliasinicial!,
                                    moduloselect: moduloselect!),
                                  ),
                                );
                              } else {
                                showDialog(
                                    context: context,
                                    builder: (context) =>
                                        const CustomDialogsActividad(
                                            title: "MENSAJE",
                                            description:
                                                'No puede generar otro viaje.\n Aun tiene un viaje en curso',
                                            imagen:
                                                "assets/images/warning.png"));
                              }
                            }
                          },
                          child: const Text(
                            "Confirmar",
                            style: TextStyle(color: Colors.white),
                          )),
                    ),
                  ),
                  const SizedBox(
                    width: 20,
                  ),
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
                      child: FlatButton(
                          //color: kArandano,
                          onPressed: () {
                            for (var i = 0; i < ddData.length; i++) {
                              atualizarAcopios(ddData[i]["ALIAS"], 1);
                            }
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
        )
      ],
    );
  }
}

class CustomDialogsActividad extends StatelessWidget {
  final String? title, description, buttontext, imagen;
  final Image? image;

  const CustomDialogsActividad(
      {Key? key,
      this.title,
      this.description,
      this.buttontext,
      this.image,
      this.imagen})
      : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: dialogContents(context),
    );
  }

  dialogContents(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Stack(
      children: <Widget>[
        Container(
          padding:
              const EdgeInsets.only(top: 50, bottom: 16, left: 16, right: 16),
          margin: const EdgeInsets.only(top: 16),
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
              const SizedBox(height: 40.0),
              Text(
                title!,
                style: const TextStyle(
                  fontSize: 24.0,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Divider(),
              const SizedBox(height: 10.0),
              Text(
                description!,
                style: const TextStyle(fontSize: 15.0),
                textAlign: TextAlign.justify,
              ),
              const SizedBox(height: 12.0),
              Align(
                alignment: Alignment.centerRight,
                child: FlatButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text(
                    "OK",
                    style: TextStyle(
                        fontWeight: FontWeight.w700, color: Colors.grey),
                  ),
                ),
              )
            ],
          ),
        ),
        Positioned(
          top: 0,
          left: size.width / 3.5,
          //right: 16,
          child: CircleAvatar(
            backgroundColor: Colors.white,
            radius: 50,
            backgroundImage: AssetImage(imagen!),
          ),
        )
      ],
    );
  }
}