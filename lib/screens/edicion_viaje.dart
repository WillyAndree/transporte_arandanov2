// ignore_for_file: deprecated_member_use

import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:transporte_arandanov2/constants.dart';
import 'package:flutter_mobile_vision_2/flutter_mobile_vision_2.dart'
    as barcode;
import 'package:transporte_arandanov2/database/database.dart';
import 'package:transporte_arandanov2/model/consumidores_model.dart';
import 'package:transporte_arandanov2/model/jabas_model.dart';
import 'package:transporte_arandanov2/model/variedades_model.dart';
import 'package:transporte_arandanov2/screens/ruteo_sinterminar.dart';

class EdicionViaje extends StatefulWidget {
  final String?
      idviajes, jabascargadas, fecha;

  const EdicionViaje(
      {Key? key,
      this.idviajes,
      this.jabascargadas,
      this.fecha})
      : super(key: key);

  @override
  _EdicionViajeState createState() => _EdicionViajeState();
}

class _EdicionViajeState extends State<EdicionViaje> {
  String? _value = "Código de válvula";
  String? dropdownValue;
  String? dropdownValueBarra;
  String? dropdownValueV;
  String? dropdownValueS;
  String? dropdownValueM;
  String? dropdownValueT;
  String? dropdownValueCo;
  List? acopiosmapeados;
  List variedad = [];
  List databarras = [];
  String? title;
  String? resultacopio;
  String? _mensaje, validacion = "";
  final myControllerCONS = TextEditingController();
  final myControllerPD = TextEditingController();
  final myControllerPJ = TextEditingController();
  final myControllerOB = TextEditingController();
  final myControllerNA = TextEditingController();
  final myControllerDE = TextEditingController();
  final myControllerFC = TextEditingController();
  final myControllerIV = TextEditingController();
  bool isInitialized = false;
  final _formKey = GlobalKey<FormState>();
  final _formKeyc = GlobalKey<FormState>();
  final _formKey2 = GlobalKey<FormState>();
  final _formKey3 = GlobalKey<FormState>();
  final _formKey4 = GlobalKey<FormState>();
  final _formKeys = GlobalKey<FormState>();

  /*Future<void> atualizarAcopios(String pacopios, int tipo) async {
    // print("ALIAS ESTADO: " + pacopios);
    var response = await http.get(
        Uri.parse("${url_base}acp/index.php/transportearandano/setAcopios?accion=estado&alias=$pacopios&tipo=$tipo"),
        headers: {"Accept": "application/json"});
    if (mounted) {
      setState(() {
        var extraerData = json.decode(response.body);
        String result = extraerData["state"].toString();
        print("RESULTADO: $result");
      });
    }
  }*/

  Future<void> recibirAcopiosSubidos() async {

    var extraerDataAcopiosMapeados;
    /*showDialog(
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
                      Text("Cargando datos...")
                    ]),
                  )));
        });*/
    print("resultate: ${widget.fecha}");
    try{
      var response = await http.get(
          Uri.parse("${url_base}WSPowerBI/controller/transportearandano.php?accion=acopioscargados&idviajes=${widget.idviajes}&jabascargadas=${widget.jabascargadas}&fecha=${widget.fecha}"),
          headers: {"Accept": "application/json"}).timeout(const Duration(seconds: 15));
      if (mounted) {
        setState(() {
          extraerDataAcopiosMapeados = json.decode(response.body);
          acopiosmapeados = extraerDataAcopiosMapeados["datos"];
          print("resultate2: "+acopiosmapeados.toString());
          myControllerCONS.text = acopiosmapeados![0]["TRAZA"];
          String cadcons = acopiosmapeados![0]["TRAZA"];
          cargarVariedades(cadcons);
          myControllerPD.text = acopiosmapeados![0]["EXPORTABLE"];
          myControllerNA.text = acopiosmapeados![0]["NACIONAL"];
          myControllerDE.text = acopiosmapeados![0]["DESMEDRO"];
          myControllerFC.text = acopiosmapeados![0]["FRUTAC"];
          myControllerOB.text = acopiosmapeados![0]["OBSERVACIONES"] ?? '';
          myControllerIV.text = acopiosmapeados![0]["IDVIAJES"];
          dropdownValueCo = acopiosmapeados![0]["CONDICION"];
          dropdownValue = acopiosmapeados![0]["VARIEDAD"];
        });
      }

    } on TimeoutException catch (_) {
      throw ('Tiempo de espera alcanzado');
    } on SocketException {
      throw ('Sin internet o falla de servidor ');
    } on HttpException {
      throw ("No se encontró esa petición");
    } on FormatException {


      throw ("Formato erroneo ");

    }
    //Navigator.pop(context);
    // });
  }

  Future<void> cargarVariedades(String cadenaconsumidor) async {
    variedad.clear();
    var idac = cadenaconsumidor.split("|");
    var consumidor = idac[0];
    print("CONS: $consumidor");
    DatabaseProvider.db
        .getVariedadWithIdConsumidor(consumidor)
        .then((List<Variedades> variedades) {
      setState(() {
        for (var i = 0; i < variedades.length; i++) {
          var objeto = {
            // Le agregas la fecha
            "IDCONSUMIDOR": variedades[i].idconsumidor,
            "DESCRIPCION": variedades[i].descripcion
          };
          variedad.add(objeto);
          print("DESCRIPCION: " + variedades[i].descripcion!);
        }
      });
    });
  }

  Future<void> cargarVariedades2() async {
    variedad.clear();
    DatabaseProvider.db
        .getVariedadWithTotal()
        .then((List<Variedades> variedades) {
      setState(() {
        for (var i = 0; i < variedades.length; i++) {
          var objeto = {
            // Le agregas la fecha
            "IDCONSUMIDOR": variedades[i].idconsumidor,
            "DESCRIPCION": variedades[i].descripcion
          };
          variedad.add(objeto);
          print("DESCRIPCION: " + variedades[i].descripcion!);
        }
      });
    });
  }

  Future<void> GuardarNota() async{

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
                                Text("Actualizando...")
                              ]),
                            )));
                  });
              var response = await http.post(
                  Uri.parse("${url_base}acp/index.php/transportearandano/setUpdateAcopio"),
                  body: {"IDVIAJES": widget.idviajes!,"FECHA": widget.fecha, "JABASCARGADAS": widget.jabascargadas, "NACIONAL": myControllerNA?.text == null ? '0' :
                      myControllerNA.text, "EXPORTABLE": myControllerPD?.text == null ? '0' :
                      myControllerPD.text, "DESMEDRO": myControllerDE?.text == null ? '0' :
                      myControllerDE.text, "FRUTAC": myControllerFC?.text == null ? '0' :
                      myControllerFC.text, "VARIEDAD" : dropdownValue?.toString() == null ? '' : dropdownValue.toString(),
                      "CONDICION": dropdownValueCo?.toString() == null ? '' : dropdownValueCo.toString(),
                      "OBSERVACIONES": myControllerOB?.text == null ? '' : myControllerOB.text,
                      "DESCRIPCION" : myControllerCONS.text}) .timeout(
                  const Duration(seconds: 15));
              if (mounted) {
                setState(() {
                  var extraerData = json.decode(response.body);
                  String result = extraerData["state"].toString();
                  print("RESULTADO DE INSERCIÓN DE RUTAS: $result");
                  Navigator.of(context).pop();
                });
              }


          } on TimeoutException catch (_) {
            throw ('Tiempo de espera alcanzado');
          } on SocketException {
            throw ('Sin internet o falla de servidor ');
          } on HttpException {
            throw ("No se encontró esa petición");
          } on FormatException {


            throw ("Formato erroneo ");

          }

  }



  @override
  void initState() {
    super.initState();
    recibirAcopiosSubidos();
  }

  Future _mensajesValidaciones(String sms) async {
    setState(() {
      validacion = sms;
    });
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: dialogContents(context),
    );
  }

  dialogContents(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Stack(
          children: <Widget>[
            Container(
              margin: const EdgeInsets.only(top: 30, left: 15, right: 15),
              child: Container(
                padding: const EdgeInsets.only(top: 12, left: 12, right: 12),
                margin: const EdgeInsets.only(top: 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Text(
                      "Editar Viaje",
                      style:  TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Divider(),
                    Opacity(opacity: 0.0, child: Padding(
                      padding: const EdgeInsets.only(
                        left: 16.0,
                      ),
                      child: TextFormField(
                        keyboardType: TextInputType.number,
                        cursorColor: kPrimaryColor,
                        controller: myControllerIV,
                        decoration: InputDecoration(
                          border: const OutlineInputBorder(),
                          labelText: 'IDVIAJE',
                          labelStyle: const TextStyle(color: Colors.grey),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20.0),
                            borderSide: const BorderSide(
                              color: kPrimaryColor,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20.0),
                            borderSide: const BorderSide(
                              color: Colors.grey,
                              width: 2.0,
                            ),
                          ),
                        ),
                      ),
                    )),
                    Row(children: <Widget>[
                            const Text("CONSUMIDOR: ",
                                style: TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 10),
                            Flexible(
                              // ignore: avoid_unnecessary_containers
                              child: Container(
                                  child: TextFormField(
                                    cursorColor: kPrimaryColor,
                                    controller: myControllerCONS,
                                    decoration: InputDecoration(
                                      border: const OutlineInputBorder(),
                                      labelText: 'Consumidor',
                                      labelStyle: const TextStyle(color: Colors.grey),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(20.0),
                                        borderSide: const BorderSide(
                                          color: kPrimaryColor,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(20.0),
                                        borderSide: const BorderSide(
                                          color: Colors.grey,
                                          width: 2.0,
                                        ),
                                      ),
                                    ),
                                  ),
                              ),
                            ),
                          ]),
                    const SizedBox(height: 10.0),
                    const Divider(),
                    const SizedBox(height: 15.0),
                    Row(children: <Widget>[
                      const Text("EXPORTABLE: ",
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 10),
                      Flexible(
                        // ignore: avoid_unnecessary_containers
                        child: Container(
                          child: Form(
                            key: _formKey,
                            child: TextFormField(
                              validator: (value) {
                                if (value!.isEmpty) {
                                  return 'Debe ingresar la cantidad de jabas';
                                }
                              },
                              keyboardType: TextInputType.number,
                              cursorColor: kPrimaryColor,
                              controller: myControllerPD,
                              decoration: InputDecoration(
                                border: const OutlineInputBorder(),
                                labelText: 'Cant. de jabas',
                                labelStyle: const TextStyle(color: Colors.grey),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20.0),
                                  borderSide: const BorderSide(
                                    color: kPrimaryColor,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20.0),
                                  borderSide: const BorderSide(
                                    color: Colors.grey,
                                    width: 2.0,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 15),
                    Row(children: <Widget>[
                      const Text("NACIONAL:     ",
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 10),
                      Flexible(
                        // ignore: avoid_unnecessary_containers
                        child: Container(
                          child: Form(
                            key: _formKey2,
                            child: TextFormField(
                              validator: (value) {
                                if (value!.isEmpty) {
                                  return 'Debe ingresar la cantidad de jabas';
                                }
                              },
                              keyboardType: TextInputType.number,
                              cursorColor: kPrimaryColor,
                              controller: myControllerNA,
                              decoration: InputDecoration(
                                border: const OutlineInputBorder(),
                                labelText: 'Cant. de jabas',
                                labelStyle: const TextStyle(color: Colors.grey),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20.0),
                                  borderSide: const BorderSide(
                                    color: kPrimaryColor,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20.0),
                                  borderSide: const BorderSide(
                                    color: Colors.grey,
                                    width: 2.0,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 15),
                    Row(children: <Widget>[
                      const Text("DESMEDRO:    ",
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 10),
                      Flexible(
                        // ignore: avoid_unnecessary_containers
                        child: Container(
                          child: Form(
                            key: _formKey3,
                            child: TextFormField(
                              validator: (value) {
                                if (value!.isEmpty) {
                                  return 'Debe ingresar la cantidad de jabas';
                                }
                              },
                              keyboardType: TextInputType.number,
                              cursorColor: kPrimaryColor,
                              controller: myControllerDE,
                              decoration: InputDecoration(
                                border: const OutlineInputBorder(),
                                labelText: 'Cant. de jabas',
                                labelStyle: const TextStyle(color: Colors.grey),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20.0),
                                  borderSide: const BorderSide(
                                    color: kPrimaryColor,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20.0),
                                  borderSide: const BorderSide(
                                    color: Colors.grey,
                                    width: 2.0,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 15),
                    Row(children: <Widget>[
                      const Text("FRUTA CAIDA:",
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 10),
                      Flexible(
                        // ignore: avoid_unnecessary_containers
                        child: Container(
                          child: Form(
                            key: _formKey4,
                            child: TextFormField(
                              validator: (value) {
                                if (value!.isEmpty) {
                                  return 'Debe ingresar la cantidad de jabas';
                                }
                              },
                              keyboardType: TextInputType.number,
                              cursorColor: kPrimaryColor,
                              controller: myControllerFC,
                              decoration: InputDecoration(
                                border: const OutlineInputBorder(),
                                labelText: 'Cant. de jabas',
                                labelStyle: const TextStyle(color: Colors.grey),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20.0),
                                  borderSide: const BorderSide(
                                    color: kPrimaryColor,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20.0),
                                  borderSide: const BorderSide(
                                    color: Colors.grey,
                                    width: 2.0,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 15),
                    variedad != null
                        ? DropdownButton<String>(
                            value: dropdownValue,
                            icon: const Icon(Icons.arrow_downward),
                            iconSize: 24,
                            elevation: 16,
                            hint: const Text('Selecciona la variedad'),
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
                            items: variedad.map((list) {
                              return DropdownMenuItem(
                                value: list['DESCRIPCION'].toString(),
                                child: Text(list['DESCRIPCION']),
                              );
                            }).toList(),
                          )
                        : const Center(
                            child: CircularProgressIndicator(),
                          ),
                    const SizedBox(
                      height: 15,
                    ),
                    DropdownButton<String>(
                      value: dropdownValueCo,
                      icon: const Icon(Icons.arrow_downward),
                      iconSize: 24,
                      elevation: 16,
                      hint: const Text('Selecciona la condición'),
                      style: const TextStyle(color: Colors.deepPurple),
                      underline: Container(
                        height: 2,
                        color: Colors.deepPurpleAccent,
                      ),
                      onChanged: (String? newValue) {
                        setState(() {
                          dropdownValueCo = newValue;
                        });
                      },
                      items: <String>[
                        "ORGANICO",
                        "CONVENCIONAL",
                      ].map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                            value: value, child: Text(value));
                      }).toList(),
                    ),
                    const SizedBox(height: 15.0),
                    const Divider(),
                    const SizedBox(
                      height: 10,
                    ),
                    Row(children: <Widget>[
                      Flexible(
                        // ignore: avoid_unnecessary_containers
                        child: Container(
                          child: Form(
                            key: _formKeys,
                            child: TextFormField(
                              validator: (value) {
                                if (value!.isEmpty) {
                                  return 'Debe ingresar la cantidad de jabas';
                                }
                              },
                              keyboardType: TextInputType.multiline,
                              minLines: 1,
                              maxLines: 5,
                              cursorColor: kPrimaryColor,
                              controller: myControllerOB,
                              decoration: InputDecoration(
                                border: const OutlineInputBorder(),
                                labelText: 'OBSERVACIONES',
                                labelStyle: const TextStyle(color: Colors.grey),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20.0),
                                  borderSide: const BorderSide(
                                    color: kPrimaryColor,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20.0),
                                  borderSide: const BorderSide(
                                    color: Colors.grey,
                                    width: 2.0,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 10.0),
                    Text(validacion!,
                        style:
                            const TextStyle(color: Colors.red, fontSize: 14, fontWeight: FontWeight.bold )),
                    const SizedBox(height: 20),
                    Row(
                      children: <Widget>[
                        Align(
                          alignment: Alignment.bottomRight,
                          child: Container(
                            decoration: BoxDecoration(
                                color: kArandano,
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
                                onPressed: () async {
                                  String jabasNacional = myControllerNA.text.isEmpty ? '-' : myControllerNA.text;
                                  String jabasExportable = myControllerPD.text.isEmpty  ? '-' : myControllerPD.text;
                                  String jabasDesmedro = myControllerDE.text.isEmpty  ? '-' : myControllerDE.text;
                                  String jabasFrutacaida = myControllerFC.text.isEmpty ? '-' : myControllerFC.text;
                                  String condicionjabas = dropdownValueCo?.toString() == null ? '-' : dropdownValueCo.toString();
                                  String descripcion = myControllerCONS.text.isEmpty ? '-' : myControllerCONS.text;



                                if(!descripcion.contains("|") && !descripcion.contains("ARA")) {
                                  _mensajesValidaciones(
                                      "Barra leida incorrectamente, revisa el código de barras");
                                }else if(jabasNacional.contains("-")){
                                  _mensajesValidaciones(
                                      "Ingresa la cantidad de jabas nacionales");
                                }else if(jabasExportable.contains("-")){
                                  _mensajesValidaciones(
                                      "Ingresa la cantidad de jabas exportables");
                                }else if(jabasDesmedro.contains("-")){
                                  _mensajesValidaciones(
                                      "Ingresa la cantidad de jabas de desmedro");
                                }else if(jabasFrutacaida.contains("-")){
                                  _mensajesValidaciones(
                                      "Ingresa la cantidad de jabas de fruta caida");
                                }else if(condicionjabas.contains("-")){
                                  _mensajesValidaciones(
                                      "Selecciona la condición");

                                }else{
                                  await GuardarNota();
                                  if (!mounted) return;
                                  Navigator.of(context).pop();
                                }


                                },
                                child: const Text(
                                  "Actualizar",
                                  style: TextStyle(color: Colors.white),
                                )),
                          ),
                        ),
                        const SizedBox(
                          width: 15,
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
                    ),
                    const SizedBox(
                      height: 15,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ));
  }
}

class CustomDialogsBuscar extends StatefulWidget {
  final String? title, description, imagen, idviajes, idlugar;
  const CustomDialogsBuscar(
      {Key? key,
      this.title,
      this.description,
      this.imagen,
      this.idviajes,
      this.idlugar})
      : super(key: key);

  @override
  _CustomDialogsBuscarState createState() => _CustomDialogsBuscarState();
}

class _CustomDialogsBuscarState extends State<CustomDialogsBuscar> {
  String? dropdownValue;
  // ignore: prefer_typing_uninitialized_variables
  var dataacopio;
  List? data;
  Future<void> recibirDatos() async {
    // ignore: prefer_typing_uninitialized_variables
    String codigoviajes = widget.idviajes ?? '0';
    String codigolugar = widget.idlugar ?? '0';
    var extraerData;
    var response = await http.get(
        Uri.parse("${url_base}WSPowerBI/controller/transportearandano.php?accion=detallebarras&idviajes=$codigoviajes&idlugar=$codigolugar"),
        headers: {"Accept": "application/json"});
    setState(() {
      extraerData = json.decode(response.body);
      data = extraerData["datos"];
      dataacopio = json.encode(extraerData["datos"]);
      print("DATAACOPIO: " + dataacopio.toString());
    });
  }

  @override
  void initState() {
    super.initState();
    recibirDatos();
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
              data != null
                  ? DropdownButton<String>(
                      value: dropdownValue,
                      icon: const Icon(Icons.arrow_downward),
                      iconSize: 24,
                      elevation: 16,
                      hint: const Text('Selecciona el codigo de barras'),
                      style: const TextStyle(color: Colors.deepPurple),
                      /*underline: Container(
                        height: 2,
                        color: Colors.deepPurpleAccent,
                      ),*/
                      onChanged: (String? newValue) {
                        setState(() {
                          dropdownValue = newValue;
                        });
                      },
                      items: data!.map((list) {
                        return DropdownMenuItem(
                          value: list['CONS'].toString(),
                          child: Text(list['CONS']),
                        );
                      }).toList(),
                    )
                  : const Center(
                      child: CircularProgressIndicator(),
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
                          onPressed: () async {
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
                                              'Debes Seleccionar la válvula a cargar',
                                          imagen: "assets/images/warning.png"));
                            } else {}
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
                child: TextButton(
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
