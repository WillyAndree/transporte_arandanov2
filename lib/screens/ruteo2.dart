// ignore_for_file: deprecated_member_use, prefer_adjacent_string_concatenation, non_constant_identifier_names, prefer_typing_uninitialized_variables

import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:isolate';
import 'dart:typed_data';
import 'dart:ui';
import 'package:connection_status_bar/connection_status_bar.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:transporte_arandanov2/components/my_bottom_nav_bar.dart';
import 'package:transporte_arandanov2/database/database.dart';
import 'package:transporte_arandanov2/model/acopios_model.dart';
import 'package:transporte_arandanov2/model/acopios_restantes_model.dart';
import 'package:transporte_arandanov2/model/jabas_model.dart';
import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:flutter_isolate/flutter_isolate.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:transporte_arandanov2/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' show cos, sqrt, asin;
import 'package:http/http.dart' as http;
import 'package:transporte_arandanov2/screens/pin_pill_info.dart';
import 'Dart:io';
import 'package:transporte_arandanov2/screens/registro_viaje.dart';
import 'package:transporte_arandanov2/screens/ruteo_sinterminar.dart';
import 'dart:math' as math;

import 'package:transporte_arandanov2/screens/second_page.dart';

const double pinVisiblePosition = 20;
const double pinInvisiblePosition = -220;
const LatLng sourceLocation = LatLng(-7.066769, -79.558876);
const double cameraZoom = 17;
const double cameraTilt = 30;
const double cameraBearing = 80;
Set<Marker> _markers = HashSet<Marker>();
var codigo_internet = 0;
int? cantidad_jabas;
int? capacidad;
int? jabas_moment = 0;
var extraerData1;
List? datapunto;
int? cantidad_jabas_actual;
String? codigoviaje;
String? name;
int? jabasporlimpiare = 0;
int jabasporlimpiar = 0;
int? jabasporlimpiarn = 0;
int? jabasporlimpiard = 0;
int? jabasporlimpiarfc = 0;
int? jabasporlimpiares = 0;
int jabasporlimpiars = 0;
int? jabasporlimpiarfcs = 0;
int? jabasporlimpiarns = 0;
int? jabasporlimpiards = 0;
List? acopiosmapeados;
var extraerDataAcopiosMapeados;
double totalDistance = 0;
String? mensaje;
String? placa;
int saldo = 0;
var lat1;
var long1;

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

Future<void> recibirDatosReloadHilo(List params) async {
  try {
    final resulte = await InternetAddress.lookup('google.com');
    if (resulte.isNotEmpty && resulte[0].rawAddress.isNotEmpty) {
      String xml = params[0];
      List dData = params[1];
      String idviajesrestult = params[2];
      String results;
      HttpOverrides.global = MyHttpOverrides();
      var response = await http.post(
          Uri.parse("${url_base}acp/index.php/transportearandano/setAcopiosDetailNota"),
          body: {"xml": xml});
      var extraerData = json.decode(response.body);
      results = extraerData["state"].toString();

      if (results.toString().contains("TRUE")) {
        if (dData.isNotEmpty) {
          for (var i = 0; i < dData.length; i++) {
              DatabaseProvider.db
                .updateJabasViaje(int.parse(idviajesrestult), dData[i]["ALIAS"]);
          }
        }
      }
     // mensaje = results.toString();
    }
  } on Exception catch (e) {
    print('Error causador por: $e');
  }
}


Future<void> recibirDatosAcopiosMapeados(List params) async {
  try {
    final resulte = await InternetAddress.lookup('google.com');
    if (resulte.isNotEmpty && resulte[0].rawAddress.isNotEmpty) {
      String acopio = params[0];
      String modulo = params[1];
      String acopioinicial = acopio;
      int activaracopiosrest = params[2];
      print("activado: $activaracopiosrest");
      HttpOverrides.global = MyHttpOverrides();
      //String results;
      var response = await http.get(
          Uri.parse("${url_base}WSPowerBI/controller/transportearandano.php?accion=acopiosmapeados&idviajes=$acopioinicial"),
          headers: {"Accept": "application/json"});
      extraerDataAcopiosMapeados = json.decode(response.body);
      acopiosmapeados = extraerDataAcopiosMapeados["datos"];
      print("ACOPIO MAPEADO: " + acopiosmapeados![0]["CANTIDAD_JABAS"]);
      if (acopiosmapeados!.isNotEmpty) {
        for (var i = 0; i < acopiosmapeados!.length; i++) {
          DatabaseProvider.db
              .insertAcopios(
              int.parse(acopioinicial),
              int.parse(acopiosmapeados![i]["CANTIDAD_JABAS"]),
              acopiosmapeados![i]["ALIAS"],
              acopiosmapeados![i]["LATITUD"],
              acopiosmapeados![i]["LONGITUD"],
              '-',
              int.parse(acopiosmapeados![i]["IDLUGAR"]));
        }
      }
//----------------------------------------------------------
      if(activaracopiosrest == 1){
      var response1 = await http.get(
          Uri.parse("${url_base}WSPowerBI/controller/transportearandano.php?accion=puntoiniciomanual&modulo=$modulo"),
          headers: {"Accept": "application/json"});
      extraerData1 = json.decode(response1.body);
      datapunto = extraerData1["datos"];
      if (datapunto!.isNotEmpty) {
        for (var i = 0; i < datapunto!.length; i++) {
          DatabaseProvider.db
              .insertAcopiosRestantes(
              modulo,
              int.parse(datapunto![i]["CANTIDAD_JABAS"]),
              datapunto![i]["ALIAS"],
              datapunto![i]["LATITUD"],
              datapunto![i]["LONGITUD"],
              '-',
              int.parse(datapunto![i]["IDACOPIO"]),
              datapunto![i]["NAME"]);
        }
      }
    }
    }
  } on Exception catch (e) {
    print('Error causador por: $e');
  }
}

// ignore: must_be_immutable
class GMap extends StatefulWidget {
  var dataacopio;
  List? data;
  double? latinicial;
  String? aliasinicial;
  double? longinicial;
  String? moduloselect;
  GMap(
      {Key? key,
      this.dataacopio,
      this.data,
      this.latinicial,
      this.longinicial,
      this.aliasinicial,
      this.moduloselect})
      : super(key: key);

  @override
  _GMapState createState() => _GMapState();
}

class _GMapState extends State<GMap> {
  final Set<Polygon> _polygons = HashSet<Polygon>();
  final Set<Polyline> _polylines = HashSet<Polyline>();
  final Set<Circle> _circles = HashSet<Circle>();
  double pinPillPosition = pinVisiblePosition;
  LatLng? currentLocation;
  LatLng? destinationLocation;
  LatLng? mediaLocation;
  BitmapDescriptor? sourceIcon;
  BitmapDescriptor? initIcon;
  BitmapDescriptor? destinationIcon;
  BitmapDescriptor? mediaIcon;
  bool userBadgeSelected = false;
  bool resetToggle = false;
  List? dataestado;
  List? acopiosrestantes;
  String? buscarDireccion;
  int? activaracopiosrestantes = 0;
  GoogleMapController? _mapController;
  BitmapDescriptor? _markerIcon;
  BitmapDescriptor? _markerIcon2;
  List? data1;
  List? areas;
  var result;
  String? distancia;
  String estadoinsert = "sin terminar";
  int estado = 0;

  final Completer<GoogleMapController> _controller = Completer();
  List<LatLng> polylineCoordinates = [];
  PolylinePoints? polylinePoints;
  String googleAPIKey = 'AIzaSyAnvIlkNe_V7YW_8bcc-av9bniI-HQneCg';
  BitmapDescriptor? sourceIcones;
  BitmapDescriptor? destinationIcones;
  LocationData? currentLocationes;
  LocationData? destinationLocationes;
  String? idtransp;
  Location? location;
  double pinPillPositiones = -100;
  TextEditingController? mycontrolleracopio;
  PinInformation currentlySelectedPin = PinInformation(
      pinPath: '',
      avatarPath: '',
      location: const LatLng(0, 0),
      locationName: '',
      labelColor: Colors.grey);
  PinInformation? sourcePinInfo;
  PinInformation? destinationPinInfo;

  _estadoVehiculo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      idtransp = (prefs.get("id") ?? "0") as String?;
      capacidad = (prefs.get("capacidad_vehiculo") ?? "0") as int?;
      name = (prefs.get("name") ?? "Usuario") as String;
      placa = (prefs.get("placa") ?? "0") as String?;
      print('placa: $placa');
      print('idtransp: $idtransp');
    });
  }

  _obtenerCodigoVehiculo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      codigoviaje = (prefs.get("idviaje") ?? "0") as String?;
      print('idviaje: $codigoviaje');
    });
  }

  FlutterIsolate? isolate;
  FlutterIsolate? isolate2;
  @override
  void initState() {
    super.initState();
    WidgetsFlutterBinding.ensureInitialized();
    _estadoVehiculo();
    _setMarkerIcon();
    _setMarkerIcon2();
    setSourceAndDestinationIcons();
    recibirDatos();
    location = Location();
    polylinePoints = PolylinePoints();
    location!.onLocationChanged.listen((LocationData cLoc) {
      currentLocationes = cLoc;

      updatePinOnMap();
    });

    setInitialLocation();
    subirJabas();
  }

  void saveBox(String xml, List dData, String idviaje) async {
    try{
    isolate?.kill();
    isolate = await FlutterIsolate.spawn(recibirDatosReloadHilo, [xml, dData, idviaje]);
    } on IsolateSpawnException catch(e){
        print(e);
    }
  }


  void saveBoxAcopios(String acopios, String modulo,int activaracopiosrestantes) async {
    try{
      isolate2?.kill();
      isolate2 = await FlutterIsolate.spawn(recibirDatosAcopiosMapeados, [acopios, modulo, activaracopiosrestantes]);
    } on IsolateSpawnException catch(e){
      print(e);
    }
   // return ReceivePort();
  }




  Future<void> subirJabas() async {
    Timer.periodic(const Duration(minutes: 1), (Timer timer) async {
       saveBoxAcopios(result, widget.moduloselect!,activaracopiosrestantes!);

     // -------------------------- acopios mapeados------------------

      var cantidadrestada = 0;
      DatabaseProvider.db
          .getCantidadAcopios(int.parse(result))
          .then((List<Acopios> acopios) async {

        for (var i = 0; i < acopios.length; i++) {
          int cantidadJabasRestantes = acopios[i].cantidadjabas! ;
          print("JABAS ACTUALES: ${acopios[i].alias!} jabas: ${acopios[i].cantidadjabas}");

         DatabaseProvider.db
              .getJabasWithId(int.parse(result), acopios[i].alias!)
              .then((List<Jabas> jabas) async {

            if (jabas[0].jabascargadas != null) {
              cantidadrestada =
              jabas[0].jabascargadas == null ? 0 : jabas[0].jabascargadas!;
              _markers.removeWhere(
                      (m) => m.markerId.value == acopios[i].alias!);

              var bitmapData = await _createAvatar(
                  80,
                  90,
                  (cantidadJabasRestantes -
                      // ignore: prefer_if_null_operators, unnecessary_null_comparison
                      (cantidadrestada == null ? 0 : cantidadrestada))
                      .toString());
              var bitmapDescriptor = BitmapDescriptor.fromBytes(bitmapData);
              _markers.add(
                Marker(
                    markerId: MarkerId(acopios[i].alias!),
                    position: LatLng(
                        double.parse(acopios[i].latitud!),
                        double.parse(acopios[i].longitud!)),
                    icon: bitmapDescriptor,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              RegistroViaje(
                                title: "NOTA DE TRASLADO",
                                description: acopios[i].descripcion!,
                                imagen: "assets/images/arandano_icon.png",
                                cantidad: cantidadJabasRestantes.toString(),
                                alias: acopios[i].alias!,
                                latitud: acopios[i].latitud!,
                                longitud: acopios[i].longitud!,
                                idacopio: acopios[i].idlugar.toString(),
                                // area: data[i]["AREA"],
                                idviajes: result.toString(),
                                tipoacopio: '-',
                              ),
                        ),
                      );
                    }),
              );
            } else {
              print("JABAS ACTUALES2: ${acopios[i].cantidadjabas}");
              var bitmapData = await _createAvatar(
                  80, 90, acopios[i].cantidadjabas.toString());
              var bitmapDescriptor = BitmapDescriptor.fromBytes(bitmapData);
              _markers.removeWhere(
                      (m) => m.markerId.value == acopios[i].alias!);
              _markers.add(
                Marker(
                    markerId: MarkerId(acopios[i].alias!),
                    position: LatLng(
                        double.parse(acopios[i].latitud!),
                        double.parse(acopios[i].longitud!)),
                    icon: bitmapDescriptor,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              RegistroViaje(
                                title: "NOTA DE TRASLADO",
                                description: acopios[i].descripcion!,
                                imagen: "assets/images/arandano_icon.png",
                                cantidad: acopios[i].cantidadjabas.toString(),
                                alias: acopios[i].alias!,
                                latitud: acopios[i].latitud!,
                                longitud: acopios[i].longitud!,
                                idacopio: acopios[i].idlugar.toString(),
                                // area: data[i]["AREA"],
                                idviajes: result.toString(),
                                tipoacopio: '-',
                              ),
                        ),
                      );
                    }),
              );
            }
          });
        }
      });

      // -------------------------- acopios restantes------------------
      var cantidadrestada2 = 0;
      DatabaseProvider.db
          .getCantidadAcopiosRestantes(widget.moduloselect!)
          .then((List<AcopiosRestantes> acopiosrestantes) async {

        for (var i = 0; i < acopiosrestantes.length; i++) {
          int cantidadJabasRestantes = acopiosrestantes[i].cantidadjabas! ;
          print("JABAS ACTUALES: ${acopiosrestantes[i].alias!} jabas: ${acopiosrestantes[i].cantidadjabas}");

          DatabaseProvider.db
              .getJabasWithId(int.parse(result), acopiosrestantes[i].alias!)
              .then((List<Jabas> jabas) async {

            if (jabas[0].jabascargadas != null) {
              cantidadrestada2 =
              jabas[0].jabascargadas == null ? 0 : jabas[0].jabascargadas!;
              _markers.removeWhere(
                      (m) => m.markerId.value == acopiosrestantes[i].alias!);
              var bitmapData;
              if(acopiosrestantes[i].name! == '-') {
                bitmapData = await _createAvatarBusqueda(
                    80,
                    90,
                    (cantidadJabasRestantes -
                        // ignore: prefer_if_null_operators, unnecessary_null_comparison
                        (cantidadrestada2 == null ? 0 : cantidadrestada2))
                        .toString());
              }else{
                bitmapData = await _createAvatarRestantes(
                    80,
                    90,
                    (cantidadJabasRestantes -
                        // ignore: prefer_if_null_operators, unnecessary_null_comparison
                        (cantidadrestada2 == null ? 0 : cantidadrestada2))
                        .toString());
              }
              var bitmapDescriptor = BitmapDescriptor.fromBytes(bitmapData);
              if((cantidadJabasRestantes - (cantidadrestada2 == null ? 0 : cantidadrestada2)) > 0) {
                _markers.add(
                  Marker(
                      markerId: MarkerId(acopiosrestantes[i].alias!),
                      position: LatLng(
                          double.parse(acopiosrestantes[i].latitud!),
                          double.parse(acopiosrestantes[i].longitud!)),
                      icon: bitmapDescriptor,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                RegistroViaje(
                                  title: "ACOPIO DE: " + datapunto![i]["NAME"],
                                  description: acopiosrestantes[i].descripcion!,
                                  imagen: "assets/images/arandano_icon.png",
                                  cantidad: cantidadJabasRestantes.toString(),
                                  alias: acopiosrestantes[i].alias!,
                                  latitud: acopiosrestantes[i].latitud!,
                                  longitud: acopiosrestantes[i].longitud!,
                                  idacopio: acopiosrestantes[i].idlugar
                                      .toString(),
                                  // area: data[i]["AREA"],
                                  idviajes: result.toString(),
                                  tipoacopio: '-',
                                ),
                          ),
                        );
                      }),
                );
              }
            } else {
              print("JABAS ACTUALES2: ${acopiosrestantes[i].cantidadjabas}");
              var bitmapData;
              if(acopiosrestantes[i].name! == '-') {
                bitmapData = await _createAvatarBusqueda(
                    80, 90, acopiosrestantes[i].cantidadjabas.toString());
              }else{
                bitmapData = await _createAvatarRestantes(
                    80, 90, acopiosrestantes[i].cantidadjabas.toString());
              }
              var bitmapDescriptor = BitmapDescriptor.fromBytes(bitmapData);
              _markers.removeWhere(
                      (m) => m.markerId.value == acopiosrestantes[i].alias!);
              if(int.parse(acopiosrestantes[i].cantidadjabas.toString()) > 0) {
                _markers.add(
                  Marker(
                      markerId: MarkerId(acopiosrestantes[i].alias!),
                      position: LatLng(
                          double.parse(acopiosrestantes[i].latitud!),
                          double.parse(acopiosrestantes[i].longitud!)),
                      icon: bitmapDescriptor,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                RegistroViaje(
                                  title: "ACOPIO DE: " + datapunto![i]["NAME"],
                                  description: acopiosrestantes[i].descripcion!,
                                  imagen: "assets/images/arandano_icon.png",
                                  cantidad: acopiosrestantes[i].cantidadjabas
                                      .toString(),
                                  alias: acopiosrestantes[i].alias!,
                                  latitud: acopiosrestantes[i].latitud!,
                                  longitud: acopiosrestantes[i].longitud!,
                                  idacopio: acopiosrestantes[i].idlugar
                                      .toString(),
                                  // area: data[i]["AREA"],
                                  idviajes: result.toString(),
                                  tipoacopio: '-',
                                ),
                          ),
                        );
                      }),
                );
              }
            }
          });
        }
      });
// ------------------------------------------
      try {

        StringBuffer xmlViajesAcopio = StringBuffer();
        var ddData = [];
        var objeto;
        String cabeceraXml =
            "<?xml version=\"1.0\" encoding=\"ISO-8859-1\"?><SOLICITUD_DESTINO>";
        String itemXml = "";
        DatabaseProvider.db
            .getJabasWithoutAlias2(int.parse(result))
            .then((List<Jabas> jabas) {
        //  if (jabas.isNotEmpty) {
            for (var i = 0; i < jabas.length; i++) {
              if(jabas[i].jabascargadas != null) {
                itemXml += "<Item IDVIAJES=\"${jabas[i].idviaje}\" LATITUD=\"${jabas[i].lat!}\" LONGITUD=\"${jabas[i].long!}\" ALIAS=\"${jabas[i].alias!}\" CANTJABAS=\"${jabas[i].jabascargadas}\" ESTADO=\"1\" DESCRIPCION=\"${jabas[i].descripcion!}\" JABASCARGADAS=\"${jabas[i].jabascargadas}\" FLLEGADA=\"${jabas[i].fllegada!}\" EXPORTABLE=\"${jabas[i].exportable}\" NACIONAL=\"${jabas[i].nacional}\" DESMEDRO=\"${jabas[i].desmedro}\" FRUTAC=\"${jabas[i].frutac}\" VARIEDAD=\"${jabas[i].variedad}\" CONDICION=\"${jabas[i].condicion}\" CONSUMIDOR=\"${jabas[i].consumidor}\" VALVULA=\"${jabas[i].valvula}\" OBSERVACIONES=\"${jabas[i].observaciones}\" />";
                 objeto = {
                  // Le agregas la fecha
                  "ALIAS": jabas[i].alias
                };
                ddData.add(objeto);
                reiniciarAcopioIndividual(jabas[i].alias!);
                jabasporlimpiare = jabasporlimpiare == null ? 0 : jabasporlimpiare! + int.parse(jabas[i].exportable.toString());
                jabasporlimpiarn =  jabasporlimpiarn == null ? 0 : jabasporlimpiarn! + int.parse(jabas[i].nacional.toString());
                jabasporlimpiard =  jabasporlimpiard == null ? 0 : jabasporlimpiard! + int.parse(jabas[i].desmedro.toString());
                jabasporlimpiarfc =  jabasporlimpiarfc == null ? 0 : jabasporlimpiarfc! + int.parse(jabas[i].frutac.toString());
              }
            }
        //  }
            setState(() {
              jabasporlimpiar = 0;
              print("JABAS POR SUBIR: $jabasporlimpiare : $jabasporlimpiarn : $jabasporlimpiard : $jabasporlimpiarfc" );
              jabasporlimpiar = int.parse(jabasporlimpiare.toString()) +
                  int.parse(jabasporlimpiarn.toString()) +
                  int.parse(jabasporlimpiard.toString()) +
                  int.parse(jabasporlimpiarfc.toString());
              jabasporlimpiare = 0;
              jabasporlimpiarn =  0;
              jabasporlimpiard =  0;
              jabasporlimpiarfc = 0;
            });
          String pieXml = "</SOLICITUD_DESTINO>";
            String xml2 = cabeceraXml + itemXml + pieXml;
            print("XML CARGADO$xml2");
          xmlViajesAcopio.write(xml2);
          print('idviaje: ' + result);
          print("ALIAS: $ddData");
          if(itemXml != ""){

            saveBox(xmlViajesAcopio.toString(), ddData, result);
          }

        });

        DatabaseProvider.db
            .getJabasSubidas(int.parse(result))
            .then((List<Jabas> jabasenviadas) {
          for (var i = 0; i < jabasenviadas.length; i++) {
            if(jabasenviadas[i].jabascargadas != null) {
              jabasporlimpiares =
              jabasporlimpiares == null ? 0 : jabasporlimpiares! +
                  int.parse(jabasenviadas[i].exportable.toString());
              jabasporlimpiarns =
              jabasporlimpiarns == null ? 0 : jabasporlimpiarns! +
                  int.parse(jabasenviadas[i].nacional.toString());
              jabasporlimpiards =
              jabasporlimpiards == null ? 0 : jabasporlimpiards! +
                  int.parse(jabasenviadas[i].desmedro.toString());
              jabasporlimpiarfcs =
              jabasporlimpiarfcs == null ? 0 : jabasporlimpiarfcs! +
                  int.parse(jabasenviadas[i].frutac.toString());
            }
          }
          setState(() {
            jabasporlimpiars = 0;
            print("JABAS subidas: $jabasporlimpiares : $jabasporlimpiarns : $jabasporlimpiards : $jabasporlimpiarfcs" );
            jabasporlimpiars = int.parse(jabasporlimpiares.toString()) +
                int.parse(jabasporlimpiarns.toString()) +
                int.parse(jabasporlimpiards.toString()) +
                int.parse(jabasporlimpiarfcs.toString());
            jabasporlimpiares = 0;
            jabasporlimpiarns =  0;
            jabasporlimpiards =  0;
            jabasporlimpiarfcs =  0;
          });
        });
      } on Exception catch (e) {
        print('Error causador por: $e');
      }
    });
  }

  Future<void> subirJabasManual() async {
     try {

        StringBuffer xmlViajesAcopio = StringBuffer();
        var ddData = [];
        var objeto;
        String cabeceraXml =
            "<?xml version=\"1.0\" encoding=\"ISO-8859-1\"?><SOLICITUD_DESTINO>";
        String itemXml = "";
        DatabaseProvider.db
            .getJabasWithoutAlias2(int.parse(result))
            .then((List<Jabas> jabas) async{
          for (var i = 0; i < jabas.length; i++) {
            if(jabas[i].jabascargadas != null) {
              itemXml += "<Item IDVIAJES=\"${jabas[i].idviaje}\" LATITUD=\"${jabas[i].lat!}\" LONGITUD=\"${jabas[i].long!}\" ALIAS=\"${jabas[i].alias!}\" CANTJABAS=\"${jabas[i].jabascargadas}\" ESTADO=\"1\" DESCRIPCION=\"${jabas[i].descripcion!}\" JABASCARGADAS=\"${jabas[i].jabascargadas}\" FLLEGADA=\"${jabas[i].fllegada!}\" EXPORTABLE=\"${jabas[i].exportable}\" NACIONAL=\"${jabas[i].nacional}\" DESMEDRO=\"${jabas[i].desmedro}\" VARIEDAD=\"${jabas[i].variedad}\" CONDICION=\"${jabas[i].condicion}\" CONSUMIDOR=\"${jabas[i].consumidor}\" VALVULA=\"${jabas[i].valvula}\" OBSERVACIONES=\"${jabas[i].observaciones}\" />";
              objeto = {
                "ALIAS": jabas[i].alias
              };
              ddData.add(objeto);
              reiniciarAcopioIndividual(jabas[i].alias!);
              jabasporlimpiare = jabasporlimpiare == null ? 0 : jabasporlimpiare! + int.parse(jabas[i].exportable.toString());
              jabasporlimpiarn =  jabasporlimpiarn == null ? 0 : jabasporlimpiarn! + int.parse(jabas[i].nacional.toString());
              jabasporlimpiard =  jabasporlimpiard == null ? 0 : jabasporlimpiard! + int.parse(jabas[i].desmedro.toString());
              jabasporlimpiarfc =  jabasporlimpiarfc == null ? 0 : jabasporlimpiarfc! + int.parse(jabas[i].frutac.toString());
            }
          }
          //  }
          setState(() {
            jabasporlimpiar = 0;
            jabasporlimpiar = int.parse(jabasporlimpiare.toString()) +
                int.parse(jabasporlimpiarn.toString()) +
                int.parse(jabasporlimpiard.toString()) +
            int.parse(jabasporlimpiarfc.toString());
            jabasporlimpiare = 0;
            jabasporlimpiarn =  0;
            jabasporlimpiard =  0;
            jabasporlimpiarfc = 0;
          });
          String pieXml = "</SOLICITUD_DESTINO>";
          String xml2 = cabeceraXml + itemXml + pieXml;
          print("XML CARGADO$xml2");
          xmlViajesAcopio.write(xml2);
            try {
              final resulte = await InternetAddress.lookup('google.com');
              if (resulte.isNotEmpty && resulte[0].rawAddress.isNotEmpty) {
                String xml = xmlViajesAcopio.toString();
                List dData = ddData;
                String idviajesrestult = result.toString();
                String results;
                HttpOverrides.global = MyHttpOverrides();
                var response = await http.post(
                    Uri.parse("${url_base}acp/index.php/transportearandano/setAcopiosDetailNota"),
                    body: {"xml": xml});
                var extraerData = json.decode(response.body);
                results = extraerData["state"].toString();

                if (results.toString().contains("TRUE")) {
                  if (dData.isNotEmpty) {
                    for (var i = 0; i < dData.length; i++) {
                      DatabaseProvider.db
                          .updateJabasViaje(int.parse(idviajesrestult), dData[i]["ALIAS"]);

                    }
                    recibirAcopiosMapeados();
                   // recibirAcopiosRestantes();
                  }
                }
              }else{
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
                              content: const Text(
                                  'Revisa tu conexión a internet'),
                              actions: [okButton]));
                    });
              }
            } on Exception catch (e) {
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
                            content: const Text(
                                'Revisa tu conexión a internet'),
                            actions: [okButton]));
                  });
            }

        });

       /* DatabaseProvider.db
            .getJabasSubidas(int.parse(result))
            .then((List<Jabas> jabasenviadas) {
          for (var i = 0; i < jabasenviadas.length; i++) {
            if(jabasenviadas[i].jabascargadas != null) {
              jabasporlimpiares =
              jabasporlimpiares == null ? 0 : jabasporlimpiares! +
                  int.parse(jabasenviadas[i].exportable.toString());
              jabasporlimpiarns =
              jabasporlimpiarns == null ? 0 : jabasporlimpiarns! +
                  int.parse(jabasenviadas[i].nacional.toString());
              jabasporlimpiards =
              jabasporlimpiards == null ? 0 : jabasporlimpiards! +
                  int.parse(jabasenviadas[i].desmedro.toString());
              jabasporlimpiarfcs =
              jabasporlimpiarfcs == null ? 0 : jabasporlimpiarfcs! +
                  int.parse(jabasenviadas[i].frutac.toString());
            }
          }
          setState(() {
            jabasporlimpiars = 0;
            print("JABAS subidas: $jabasporlimpiares : $jabasporlimpiarns : $jabasporlimpiards : $jabasporlimpiarfcs" );
            jabasporlimpiars = int.parse(jabasporlimpiares.toString()) +
                int.parse(jabasporlimpiarns.toString()) +
                int.parse(jabasporlimpiards.toString()) +
                int.parse(jabasporlimpiarns.toString()) +
                int.parse(jabasporlimpiarfcs.toString());
            jabasporlimpiares = 0;
            jabasporlimpiarns =  0;
            jabasporlimpiards =  0;
            jabasporlimpiarfcs =  0;
          });
        });*/
      } on Exception catch (e) {
        print('Error causador por: $e');
      }
  }

  void showPinsOnMap() {
    estado = 0;
    var pinPosition = LatLng(widget.latinicial!, widget.longinicial!);
    print("--------------------------$pinPosition");

    _markers.add(Marker(
        markerId: const MarkerId('sourcePin'),
        position: pinPosition,
        onTap: () {
          setState(() {
           /* currentlySelectedPin = sourcePinInfo!;
            pinPillPosition = 0;*/
          });
        },
        icon: sourceIcones!));
  }

  _guardarIdviaje(String idviaje) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString("idviaje", idviaje);
    print("GUARDADO EN SHARED: $idviaje");
  }

  void updatePinOnMap() async {
    CameraPosition cPosition = CameraPosition(
      zoom: estado == 0 ? cameraZoom : 22,
      tilt: estado == 0 ? cameraTilt : 90,
      bearing: estado == 0 ? cameraBearing : 58,
      target:
          LatLng(currentLocationes!.latitude!, currentLocationes!.longitude!),
    );
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(cPosition));
    setState(() {
      var pinPosition =
          LatLng(currentLocationes!.latitude!, currentLocationes!.longitude!);
      _markers.removeWhere((m) => m.markerId.value == 'sourcePin');
      _markers.add(Marker(
          markerId: const MarkerId('sourcePin'),
          onTap: () {
            setState(() {
              /*currentlySelectedPin = sourcePinInfo!;
              pinPillPosition = 0;*/
            });
          },
          position: pinPosition, // updated position
          icon: sourceIcones!));
    });
  }

  void setSourceAndDestinationIcons() async {
    BitmapDescriptor.fromAssetImage(
            const ImageConfiguration(devicePixelRatio: 2.0),
            'assets/images/marker_truck.png')
        .then((onValue) {
      sourceIcones = onValue;
    });
  }

  void _setMarkerIcon() async {
    _markerIcon = await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(), 'assets/images/marker_truck.png');
  }

  void _setMarkerIcon2() async {
    _markerIcon2 = await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(), 'assets/images/navigation2.png');
  }

  void setInitialLocation() async {
    currentLocationes = await location!.getLocation();
  }

  Future<void> recibirAcopiosRestantes() async {

    activaracopiosrestantes = 1;
    var extraerDataAcopiosRestantes;
    var cantidadrestada = 0;
    var ddData = [];
    String? aliasnewpoint, consumidornewpoint;
    double? latnewpoint, longnewpoint;
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
                      Text("Verificando acopios extra")
                    ]),
                  )));
        });
    var response1 = await http.get(
        Uri.parse("${url_base}WSPowerBI/controller/transportearandano.php?accion=puntoiniciomanual&modulo=${widget.moduloselect!}"),
        headers: {"Accept": "application/json"});
    if (mounted) {
      setState(() {
        extraerData1 = json.decode(response1.body);
        datapunto = extraerData1["datos"];

      });
    }
        for (var i = 0; i < datapunto!.length; i++) {
          int cantidadJabasRestantes = int.parse(
              datapunto![i]["CANTIDAD_JABAS"]);
          DatabaseProvider.db
              .getJabasWithId(int.parse(result), datapunto![i]["ALIAS"])
              .then((List<Jabas> jabas) async {
            cantidadrestada =
            jabas[0].jabascargadas == null ? 0 : jabas[0].jabascargadas!;
            if (jabas.isNotEmpty) {
              _markers.removeWhere(
                      (m) => m.markerId.value == datapunto![i]["ALIAS"]);
              var bitmapData;
              if(datapunto![i]["NAME"] == "-"){
                print("HOLA NAME");
                bitmapData = await _createAvatarBusqueda(
                    80, 90,
                    (cantidadJabasRestantes - cantidadrestada).toString());
              }else {
                print("HOLA NAME2");
                bitmapData = await _createAvatarRestantes(
                    80, 90,
                    (cantidadJabasRestantes - cantidadrestada).toString());
              }
              var bitmapDescriptor = BitmapDescriptor.fromBytes(bitmapData);
              if((cantidadJabasRestantes - cantidadrestada) > 0){
                _markers.add(
                  Marker(
                      markerId: MarkerId(datapunto![i]["ALIAS"]),
                      position: LatLng(
                          double.parse(datapunto![i]["LATITUD"]),
                          double.parse(datapunto![i]["LONGITUD"])),
                      icon: bitmapDescriptor,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                RegistroViaje(
                                  title: "ACOPIO DE: "+datapunto![i]["NAME"],
                                  description: datapunto![i]["DESCRIPCION"],
                                  imagen: "assets/images/ar andano_icon.png",
                                  cantidad: cantidadJabasRestantes.toString(),
                                  alias: datapunto![i]["ALIAS"],
                                  latitud: datapunto![i]["LATITUD"],
                                  longitud: datapunto![i]["LONGITUD"],
                                  idacopio: datapunto![i]["IDACOPIO"],
                                  // area: data[i]["AREA"],
                                  idviajes: result.toString(),
                                  tipoacopio: '-',
                                ),
                          ),
                        );
                      }),
                );
              }

            } else {
              var bitmapData;
              if(datapunto![i]["NAME"] == "-") {
                bitmapData =
                await _createAvatarBusqueda(
                    80, 90, datapunto![i]["CANTIDAD_JABAS"]);
              }else{
                bitmapData = await _createAvatarRestantes(
                    80, 90, datapunto![i]["CANTIDAD_JABAS"]);
              }
              var bitmapDescriptor = BitmapDescriptor.fromBytes(bitmapData);
              if(int.parse(datapunto![i]["CANTIDAD_JABAS"]) > 0) {
                _markers.add(
                  Marker(
                      markerId: MarkerId(datapunto![i]["ALIAS"]),
                      position: LatLng(double.parse(datapunto![i]["LATITUD"]),
                          double.parse(datapunto![i]["LONGITUD"])),
                      icon: bitmapDescriptor,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                RegistroViaje(
                                  title: "ACOPIO DE: " + datapunto![i]["NAME"],
                                  description: datapunto![i]["DESCRIPCION"],
                                  imagen: "assets/images/ar andano_icon.png",
                                  cantidad: datapunto![i]["CANTIDAD_JABAS"],
                                  alias: datapunto![i]["ALIAS"],
                                  latitud: datapunto![i]["LATITUD"],
                                  longitud: datapunto![i]["LONGITUD"],
                                  idacopio: datapunto![i]["IDACOPIO"],
                                  // area: data[i]["AREA"],
                                  idviajes: result.toString(),
                                  tipoacopio: '-',
                                ),
                          ),
                        );
                      }),
                );
              }
            }
            var objeto = {
              // Le agregas la fecha
              "ALIAS": datapunto![i]["ALIAS"]
            };
            ddData.add(objeto);
          });
        }
        Navigator.pop(context);

  }

  Future<void> recibirAcopiosMapeados() async {

    var cantidadrestada = 0;
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
                      Text("Actualizando acopios")
                    ]),
                  )));
        });
    var response = await http.get(
        Uri.parse("${url_base}WSPowerBI/controller/transportearandano.php?accion=acopiosmapeados&idviajes=" +
            result),
        headers: {"Accept": "application/json"});
    if (mounted) {
      setState(() {
        extraerDataAcopiosMapeados = json.decode(response.body);
        acopiosmapeados = extraerDataAcopiosMapeados["datos"];
        for (var i = 0; i < acopiosmapeados!.length; i++) {
          int cantidadJabasRestantes =
              int.parse(acopiosmapeados![i]["CANTIDAD_JABAS"]);
          DatabaseProvider.db
              .getJabasWithId(int.parse(result), acopiosmapeados![i]["ALIAS"])
              .then((List<Jabas> jabas) async {

            if (jabas[0].jabascargadas != null) {
              cantidadrestada = jabas[0].jabascargadas == null ? 0 : jabas[0].jabascargadas!;
              _markers.removeWhere(
                  (m) => m.markerId.value == acopiosmapeados![i]["ALIAS"]);
              var bitmapData = await _createAvatar(
                  80,
                  90,
                  (cantidadJabasRestantes -
                          // ignore: prefer_if_null_operators, unnecessary_null_comparison
                          (cantidadrestada == null ? 0 : cantidadrestada))
                      .toString());
              var bitmapDescriptor = BitmapDescriptor.fromBytes(bitmapData);
              _markers.add(
                Marker(
                    markerId: MarkerId(acopiosmapeados![i]["ALIAS"]),
                    position: LatLng(
                        double.parse(acopiosmapeados![i]["LATITUD"]),
                        double.parse(acopiosmapeados![i]["LONGITUD"])),
                    icon: bitmapDescriptor,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RegistroViaje(
                            title: "NOTA DE TRASLADO",
                            description: acopiosmapeados![i]["DESCRIPCION"],
                            imagen: "assets/images/ar andano_icon.png",
                            cantidad: cantidadJabasRestantes.toString(),
                            alias: acopiosmapeados![i]["ALIAS"],
                            latitud: acopiosmapeados![i]["LATITUD"],
                            longitud: acopiosmapeados![i]["LONGITUD"],
                            idacopio: acopiosmapeados![i]["IDLUGAR"],
                            // area: data[i]["AREA"],
                            idviajes: result.toString(),
                            tipoacopio: '-',
                          ),
                        ),
                      );
                    }),
              );
            } else {
              var bitmapData = await _createAvatar(
                  80, 90, acopiosmapeados![i]["CANTIDAD_JABAS"]);
              var bitmapDescriptor = BitmapDescriptor.fromBytes(bitmapData);
              _markers.removeWhere(
                  (m) => m.markerId.value == acopiosmapeados![i]["ALIAS"]);
              _markers.add(
                Marker(
                    markerId: MarkerId(acopiosmapeados![i]["ALIAS"]),
                    position: LatLng(
                        double.parse(acopiosmapeados![i]["LATITUD"]),
                        double.parse(acopiosmapeados![i]["LONGITUD"])),
                    icon: bitmapDescriptor,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RegistroViaje(
                            title: "NOTA DE TRASLADO",
                            description: acopiosmapeados![i]["DESCRIPCION"],
                            imagen: "assets/images/ar andano_icon.png",
                            cantidad: acopiosmapeados![i]["CANTIDAD_JABAS"],
                            alias: acopiosmapeados![i]["ALIAS"],
                            latitud: acopiosmapeados![i]["LATITUD"],
                            longitud: acopiosmapeados![i]["LONGITUD"],
                            idacopio: acopiosmapeados![i]["IDLUGAR"],
                            // area: data[i]["AREA"],
                            idviajes: result.toString(),
                            tipoacopio: '-',
                          ),
                        ),
                      );
                    }),
              );
            }
          });
        }
        Navigator.pop(context);
      });
    }
  }

  Future<void> recibirDatos() async {
    int total = 0;
    var resultdetail;
    var ddData = [];
    String actividad = "";
    var ddacopios = [];

    mediaIcon = await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(devicePixelRatio: 2),
        'assets/images/flages.png');
    sourceIcon = await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(devicePixelRatio: 2),
        'assets/images/arandano_marker.png');

    //if (total > 0) {
    var responsess = await http.get(
        Uri.parse("${url_base}WSPowerBI/controller/transportearandano.php?accion=estadoviaje&idtransp=${idtransp!}"),
        headers: {"Accept": "application/json"});
    if (mounted) {
      setState(() {
        var extraerData = json.decode(responsess.body);
        dataestado = extraerData["datos"];
        actividad = dataestado![0]["actividad"];
      });
    }
    print("ESTADO RUTEO: $actividad TRANSP. ${idtransp!}");

    if (actividad == "LIBRE") {
      var response = await http.post(
          Uri.parse("${url_base}acp/index.php/transportearandano/setViaje"),
          body: {
            // "accion": "viaje",
            "idtransp": idtransp,
            "tbox": "0",
            "tdistance": "0.00",
            "estado": "0",
            "ruta": "-",
            "vehiculo": placa.toString(),
          });
      if (mounted) {
        setState(() {
          print("RESPONSE BODY: ${response.body}");

          var extraerData = json.decode(response.body);
          result = extraerData["state"];
          print("RESULTADO DE INSERCIÓN: ${extraerData["state"]}");
          _guardarIdviaje(extraerData["state"].toString());
        });
      }
      for (var i = 0; i < widget.data!.length; i++) {
        var bitmapData =
            await _createAvatar(80, 90, widget.data![i]["CANTIDAD_JABAS"]);
        var bitmapDescriptor = BitmapDescriptor.fromBytes(bitmapData);
        cantidad_jabas = int.parse(widget.data![i]["CANTIDAD_JABAS"]);
        if (total <= capacidad! && cantidad_jabas! > 0) {
          cantidad_jabas_actual = int.parse(widget.data![i]["CANTIDAD_JABAS"]);
          _markers.add(
            Marker(
                markerId: MarkerId(widget.data![i]["ALIAS"]),
                position: LatLng(double.parse(widget.data![i]["LATITUD"]),
                    double.parse(widget.data![i]["LONGITUD"])),
                icon: bitmapDescriptor,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RegistroViaje(
                        title: "NOTA DE TRASLADO",
                        description: widget.data![i]["DESCRIPCION"],
                        imagen: "assets/images/ar andano_icon.png",
                        cantidad: widget.data![i]["CANTIDAD_JABAS"],
                        alias: widget.data![i]["ALIAS"],
                        latitud: widget.data![i]["LATITUD"],
                        longitud: widget.data![i]["LONGITUD"],
                        idacopio: widget.data![i]["IDACOPIO"],
                        // area: data[i]["AREA"],
                        idviajes: result,
                        tipoacopio: '-',
                      ),
                    ),
                  );
                }),
          );
          total += cantidad_jabas!;
          print("CAPACIDAD$capacidad ,CANT JABAS$cantidad_jabas");
          if (total > 0) {
            var objeto = {"ALIAS": widget.data![i]["ALIAS"]};
            ddData.add(objeto);

            var acopiosViaje = {
              // Le agregas la fecha
              "ALIAS": widget.data![i]["ALIAS"],
              "CANTIDAD_JABAS": widget.data![i]["CANTIDAD_JABAS"],
              "LATITUD": widget.data![i]["LATITUD"],
              "LONGITUD": widget.data![i]["LONGITUD"],
              "SALDO":
                  capacidad! >= cantidad_jabas! ? cantidad_jabas : capacidad
            };
            ddacopios.add(acopiosViaje);
            print("DATAACOPIO$ddacopios");
          }
        }
      }
      for (var i = 0; i < ddacopios.length; i++) {
        var responsedetail = await http.get(
            Uri.parse("${"${url_base +
                "acp/index.php/transportearandano/setViajeDetail?accion=viajedetail&idviajes=" +
                result +
                "&alias=" +
                ddacopios[i]["ALIAS"] +
                "&latitud=" +
                ddacopios[i]["LATITUD"] +
                "&longitud=" +
                ddacopios[i]["LONGITUD"]}&cantjabas=" +
                ddacopios[i]["CANTIDAD_JABAS"]}&jabascargadas=0"),
            headers: {"Accept": "application/json"});
        if (mounted) {
          setState(() {
            var extraerData = json.decode(responsedetail.body);
            resultdetail = extraerData["state"];
            print("RESULTADO DE DETALLE: $resultdetail");
          });
        }
        atualizarAcopios(ddacopios[i]["ALIAS"], 0);
      }

      var inicio = widget.aliasinicial;
      var fin = json.encode(ddData);
      print("ALIAS INICIO$inicio");
      print("ALIAS FINAL$fin");
      var responses = await http.post(
          Uri.parse(
              "${url_base}acp/index.php/optimizacionrutapp/returnShortestPath"),
          body: {"puntoInicio": inicio, "destinosAgregados": fin});
      if (mounted) {
        setState(() {
          print("RESPUESTA1: ${responses.body}");
          // ignore: unnecessary_null_comparison
          if (responses.body.toString() != null ||
              responses.body.toString() != "") {
            final extraerData =
            Map<String, dynamic>.from(json.decode(responses.body));
            data1 = extraerData["datos"]["coordenadas"];
            List<LatLng> polylineLatLongs = [];
            print("distancia: ................${extraerData["datos"]["costo"]}");
            distancia = extraerData["datos"]["costo"].toString();
            for (var i = 0; i < data1!.length; i++) {
              polylineLatLongs.add(LatLng(double.parse(data1![i]["latitud"]),
                  double.parse(data1![i]["longitud"])));
              _polylines.add(
                Polyline(
                  polylineId: const PolylineId("0"),
                  points: polylineLatLongs,
                  color: kArandano,
                  width: 8,
                ),
              );
            }
          } else {
            print("error en ruta");
            distancia = '0.000';
          }
        });
      }
    }

  }

  Future<void> atualizarAcopios(String pacopios, int tipo) async {
    // print("ALIAS ESTADO: " + pacopios);

    var response = await http.get(
        Uri.parse("${url_base}acp/index.php/transportearandano/setAcopios?accion=estado&alias=$pacopios&tipo=$tipo"),
        headers: {"Accept": "application/json"});
    if (mounted) {
      setState(() {
        var extraerData = json.decode(response.body);
        var resulto = extraerData["state"];
        print("RESULTADO: $resulto");
      });
    }
  }

  void setSourceAndDestinationMarkerIcons(BuildContext context) async {
    sourceIcon = await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(devicePixelRatio: 2),
        'assets/images/arandano_marker.png');

    initIcon = await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(devicePixelRatio: 2),
        'assets/images/car-placeholder.png');

    mediaIcon = await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(devicePixelRatio: 2),
        'assets/images/flages.png');

    destinationIcon = await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(devicePixelRatio: 1),
        'assets/images/arandano_marker.png');
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _controller.complete(controller);
    setState(() {
      _markers.add(
        Marker(
            markerId: const MarkerId("sourcePin"),
            position: LatLng(widget.latinicial!, widget.longinicial!),
            icon: _markerIcon!),
      );
      showPinsOnMap();
    });
  }

  Future<void> reiniciarAcopios() async {
    // print("ALIAS ESTADO: " + pacopios);
    var response = await http.get(
        Uri.parse("${url_base}acp/index.php/transportearandano/setReinicioAcopios?accion=reinicio&idviajes=" +
            result),
        headers: {"Accept": "application/json"});
    if (mounted) {
      setState(() {
        var extraerData = json.decode(response.body);
        String result = extraerData["state"].toString();
        print("RESULTADO: $result");
      });
    }
  }

  Future<void> reiniciarAcopiosSinUso() async {
    // print("ALIAS ESTADO: " + pacopios);
    var response = await http.get(
        Uri.parse("${url_base}acp/index.php/transportearandano/setReinicioAcopiosSinUso?accion=reiniciosinuso&idviajes=" +
            result),
        headers: {"Accept": "application/json"});
    if (mounted) {
      setState(() {
        var extraerData = json.decode(response.body);
        String result = extraerData["state"].toString();
        print("RESULTADO: $result");
      });
    }
  }

  Future<void> reiniciarAcopioIndividual(String alias) async {
    print("ALIAS ESTADO: $alias");
    var response = await http.get(
        Uri.parse("${"${url_base}acp/index.php/transportearandano/setReinicioAcopiosIndividual?accion=reinicioindividual&idviajes=" +
            result}&alias=$alias"),
        headers: {"Accept": "application/json"});
    if (mounted) {
      setState(() {
        var extraerData = json.decode(response.body);
        String result = extraerData["state"].toString();
        print("RESULTADO ACOPIO: $result");
      });
    }
  }

  Future<void> guardarAcopios(String xml) async {
    var response = await http.post(
        Uri.parse(
            "${url_base}acp/index.php/transportearandano/setAcopiosDetailNota"),
        body: {"xml": xml});
    if (mounted) {
      setState(() {
        var extraerData = json.decode(response.body);
        String result = extraerData["state"].toString();
        print("RESULTADO DE INSERCIÓN DE acopios: $result");
      });
    }
  }

  Future<void> guardarRuta(double latitud, double longitud) async {
    var response = await http.get(
        Uri.parse("${"${url_base}acp/index.php/transportearandano/setGuardarRutas?accion=saverutas&idviajes=" +
            result}&latitud=$latitud&longitud=$longitud"),
        headers: {"Accept": "application/json"});
    if (mounted) {
      setState(() {
        var extraerData = json.decode(response.body);
        String result = extraerData["state"].toString();
        print("RESULTADO DE INSERCIÓN DE RUTAS: $result");
      });
    }
  }

  Future<void> guardarRuta2(String xml) async {
    var response = await http.post(
        Uri.parse("${url_base}acp/index.php/transportearandano/setRutasDetail"),
        body: {"xml": xml});
    if (mounted) {
      setState(() {
        var extraerData = json.decode(response.body);
        String result = extraerData["state"].toString();
        print("RESULTADO DE INSERCIÓN DE RUTAS: $result");
      });
    }
  }

  Future<Uint8List> _createAvatar(int width, int height, String name,
      {Color color = kArandano}) async {
    final PictureRecorder pictureRecorder = PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final Paint paint = Paint()..color = color;

    canvas.drawOval(
      Rect.fromCircle(
        center: Offset(width * 0.5, height * 0.5),
        radius: math.min(width * 0.5, height * 0.5),
      ),
      paint,
    );

    TextPainter painter = TextPainter(textDirection: TextDirection.ltr);
    painter.text = TextSpan(
      text: name,
      style: const TextStyle(
          fontSize: 25.0, color: Colors.white, fontWeight: FontWeight.w700),
    );
    painter.layout();
    painter.paint(
        canvas,
        Offset((width * 0.5) - painter.width * 0.5,
            (height * 0.5) - painter.height * 0.5));

    final img = await pictureRecorder.endRecording().toImage(width, height);
    final data = await img.toByteData(format: ImageByteFormat.png);
    return data!.buffer.asUint8List();
  }


  Future<Uint8List> _createAvatarRestantes(int width, int height, String name,
      {Color color = Colors.red}) async {
    final PictureRecorder pictureRecorder = PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final Paint paint = Paint()..color = color;

    canvas.drawOval(
      Rect.fromCircle(
        center: Offset(width * 0.5, height * 0.5),
        radius: math.min(width * 0.5, height * 0.5),
      ),
      paint,
    );

    TextPainter painter = TextPainter(textDirection: TextDirection.ltr);
    painter.text = TextSpan(
      text: name,
      style: const TextStyle(
          fontSize: 25.0, color: Colors.white, fontWeight: FontWeight.w700),
    );
    painter.layout();
    painter.paint(
        canvas,
        Offset((width * 0.5) - painter.width * 0.5,
            (height * 0.5) - painter.height * 0.5));

    final img = await pictureRecorder.endRecording().toImage(width, height);
    final data = await img.toByteData(format: ImageByteFormat.png);
    return data!.buffer.asUint8List();
  }

  Future<Uint8List> _createAvatarBusqueda(int width, int height, String name,
      {Color color = kPrimaryColor}) async {
    final PictureRecorder pictureRecorder = PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final Paint paint = Paint()..color = color;

    canvas.drawOval(
      Rect.fromCircle(
        center: Offset(width * 0.5, height * 0.5),
        radius: math.min(width * 0.5, height * 0.5),
      ),
      paint,
    );

    TextPainter painter = TextPainter(textDirection: TextDirection.ltr);
    painter.text = TextSpan(
      text: name,
      style: const TextStyle(
          fontSize: 25.0, color: Colors.white, fontWeight: FontWeight.w700),
    );
    painter.layout();
    painter.paint(
        canvas,
        Offset((width * 0.5) - painter.width * 0.5,
            (height * 0.5) - painter.height * 0.5));

    final img = await pictureRecorder.endRecording().toImage(width, height);
    final data = await img.toByteData(format: ImageByteFormat.png);
    return data!.buffer.asUint8List();
  }
  void _onMapCreated2(GoogleMapController controller) {
    _mapController = controller;
    _controller.complete(controller);
    setState(() {
      _markers.add(
        Marker(
            markerId: const MarkerId("sourcePin"),
            position: LatLng(
                currentLocationes!.latitude!, currentLocationes!.longitude!),
            icon: _markerIcon2!),
      );
    });
  }

  double _coordinateDistance(lat1, lon1, lat2, lon2) {
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 -
        c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }

  zoomInMarker() {
    estado = 1;
    _mapController!
        .animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
      target:
          LatLng(currentLocationes!.latitude!, currentLocationes!.longitude!),
      zoom: 25,
      tilt: 90,
      bearing: -30,
    )))
        .then((val) {
      setState(() {
        resetToggle = true;
        _onMapCreated2(_mapController!);
      });
    });
  }

  Future<Uint8List> _createAvatarOcupado(int width, int height, String name,
      {Color color = Colors.red}) async {
    final PictureRecorder pictureRecorder = PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final Paint paint = Paint()..color = color;

    canvas.drawOval(
      Rect.fromCircle(
        center: Offset(width * 0.5, height * 0.5),
        radius: math.min(width * 0.5, height * 0.5),
      ),
      paint,
    );

    TextPainter painter = TextPainter(textDirection: TextDirection.ltr);
    painter.text = TextSpan(
      text: name,
      style: const TextStyle(
          fontSize: 25.0, color: Colors.white, fontWeight: FontWeight.w700),
    );
    painter.layout();
    painter.paint(
        canvas,
        Offset((width * 0.5) - painter.width * 0.5,
            (height * 0.5) - painter.height * 0.5));

    final img = await pictureRecorder.endRecording().toImage(width, height);
    final data = await img.toByteData(format: ImageByteFormat.png);
    return data!.buffer.asUint8List();
  }

  Future<void> barraBusqueda() async {
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
                      Text("Redirigiendo a acopio")
                    ]),
                  )));
        });
    //if (mycontrolleracopio.text != null) {
    var bitmapData;
    List? jabaindividual;
    var response = await http.get(
        Uri.parse("${url_base}WSPowerBI/controller/transportearandano.php?accion=acopioindividual&idlugar=${buscarDireccion!}"),
        headers: {"Accept": "application/json"});
    if (mounted) {
      setState(() {
        var extraerDatajabai = json.decode(response.body);
        jabaindividual = extraerDatajabai["datos"];
      });
    }
    if (jabaindividual!.isNotEmpty) {
      for (var i = 0; i < jabaindividual!.length; i++) {
        // FocusScope.of(context).unfocus();

        _mapController!.animateCamera(CameraUpdate.newCameraPosition(
          CameraPosition(
              target: LatLng(double.parse(jabaindividual![i]["LATITUD"]),
                  double.parse(jabaindividual![i]["LONGITUD"])),
              zoom: 18.0),
        ));

        if (jabaindividual![i]["ESTADO"] == '1') {
          bitmapData =
              await _createAvatar(80, 90, jabaindividual![i]["CANTIDAD_JABAS"]);
        } else {
          bitmapData = await _createAvatarOcupado(
              80, 90, jabaindividual![i]["CANTIDAD_JABAS"]);
        }
        var bitmapDescriptor = BitmapDescriptor.fromBytes(bitmapData);
        _markers.add(
          Marker(
              markerId: MarkerId(jabaindividual![i]["ALIAS"]),
              position: LatLng(double.parse(jabaindividual![i]["LATITUD"]),
                  double.parse(jabaindividual![i]["LONGITUD"])),
              icon: bitmapDescriptor,
              onTap: () {
                if (jabaindividual![i]["ESTADO"] == '1') {
                  print("ACOPIO LIBRE");
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RegistroViaje(
                        title: "NOTA DE TRASLADO",
                        imagen: "assets/images/ar andano_icon.png",
                        description: jabaindividual![i]["IDCONSUMIDOR"],
                        cantidad: jabaindividual![i]["CANTJABAS"],
                        alias: jabaindividual![i]["ALIAS"],
                        idacopio: jabaindividual![i]["IDLUGAR"],
                        latitud: jabaindividual![i]["LATITUD"],
                        longitud: jabaindividual![i]["LONGITUD"],
                        idviajes: result.toString(),
                        tipoacopio: '-',
                      ),
                    ),
                  );
                } else {
                  print("ACOPIO OCUPADO");
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RegistroViaje(
                        title: "NOTA DE TRASLADO",
                        imagen: "assets/images/ar andano_icon.png",
                        description: jabaindividual![i]["IDCONSUMIDOR"],
                        cantidad: jabaindividual![i]["CANTJABAS"],
                        alias: jabaindividual![i]["ALIAS"],
                        idacopio: jabaindividual![i]["IDLUGAR"],
                        latitud: jabaindividual![i]["LATITUD"],
                        longitud: jabaindividual![i]["LONGITUD"],
                        // area: data[i]["AREA"],
                        idviajes: result.toString(),
                        tipoacopio: '-',
                      ),
                    ),
                  );
                }
              }),
        );
        // setState(() {});
      }
    }
    FocusScope.of(context).requestFocus(FocusNode());
    Navigator.pop(context);

    // }
  }

  @override
  Widget build(BuildContext context) {
    setSourceAndDestinationMarkerIcons(context);
    CameraPosition initialCameraPosition = CameraPosition(
        zoom: cameraZoom,
        tilt: cameraTilt,
        bearing: cameraBearing,
        target: LatLng(widget.latinicial!, widget.longinicial!));
    if (currentLocationes != null) {
      initialCameraPosition = CameraPosition(
          target: LatLng(
              currentLocationes!.latitude!, currentLocationes!.longitude!),
          zoom: cameraZoom,
          tilt: cameraTilt,
          bearing: cameraBearing);
    }

    return WillPopScope(
        onWillPop: () {
          estadoinsert = "terminado";
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const SecondPage(),
            ),
          );
          // ignore: null_check_always_fails
          return null!;
        },
        child: Scaffold(
            body: Stack(
          children: <Widget>[
            GoogleMap(
              myLocationEnabled: true,
              compassEnabled: true,
              tiltGesturesEnabled: false,
              onMapCreated: _onMapCreated,
              initialCameraPosition: initialCameraPosition,
              onTap: (LatLng loc) {
                //pinPillPosition = -200;
              },
              mapType: MapType.satellite,
              markers: _markers,
              polygons: _polygons,
              polylines: _polylines,
              circles: _circles,
              myLocationButtonEnabled: false,
            ),
            Container(
              alignment: Alignment.bottomCenter,
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 80),
            ),
            Align(
              alignment: Alignment.topCenter,
              child: ConnectionStatusBar(
                height : 25, // double: default height
                width : double.maxFinite, // double: default width
                color : Colors.redAccent, // Color: default background color
                lookUpAddress : 'google.com', // String: default site to look up for checking internet connection
                endOffset : const Offset(0.0, 0.0), // Offset: default animation finish point offset
                beginOffset : const Offset(0.0, -1.0), // Offset: default animation start point offset
                animationDuration : const Duration(milliseconds: 200), // Duration: default animation duration
                // Text: default text
                title : const Text(
                  'Sin conexión, verifica tu conexión a internet',
                  style: TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
            ),
            Align(
                alignment: Alignment.topLeft,
                child: GestureDetector(
                  child: Container(
                      margin: const EdgeInsets.only(top: 45, left: 20),
                      child: ClipOval(
                          child: Container(
                              color: kArandano,
                              //margin: EdgeInsets.only(top: 45),
                              padding: const EdgeInsets.all(5),
                              child: const Icon(
                                Icons.arrow_back,
                                color: Colors.white,
                                size: 32,
                              )))),
                  onTap: () {
                    estadoinsert = "terminado";
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SecondPage(),
                      ),
                    );
                  },
                )),
            Positioned(
              top: 110.0,
              right: 15.0,
              left: 15.0,
              child: Container(
                height: 50.0,
                width: double.infinity,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10.0),
                    color: Colors.white),
                child: TextFormField(
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Debe ingresar el codigo de acopio';
                      }
                    },
                    controller: mycontrolleracopio,
                    onEditingComplete: barraBusqueda,
                    decoration: InputDecoration(
                      hintText: 'Buscar',
                      border: InputBorder.none,
                      contentPadding:
                          const EdgeInsets.only(left: 15.0, top: 15.0),
                      suffixIcon: IconButton(
                        onPressed: () {
                          barraBusqueda();
                        },
                        icon: const Icon(Icons.search),
                        iconSize: 35.0,
                      ),
                    ),
                    onChanged: (val) {
                      setState(() {
                        buscarDireccion = val;
                      });
                    }),
              ),
            ),
            AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                left: 0,
                right: 0,
                bottom: pinPillPosition,
                child: Container(
                    margin: const EdgeInsets.all(20),
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(40),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 10,
                              offset: Offset.zero)
                        ]),
                    child: Column(
                      children: [
                        Container(
                            color: Colors.white,
                            child: Row(
                              children: [
                                Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    ClipOval(
                                      child: Image.asset(
                                          'assets/images/arandano.png',
                                          width: 60,
                                          height: 60,
                                          fit: BoxFit.cover),
                                    ),
                                    Positioned(
                                        bottom: -10,
                                        right: -10,
                                        child: ClipOval(
                                            child: Container(
                                                color: kArandano,
                                                padding:
                                                    const EdgeInsets.all(2),
                                                child: Image.asset(
                                                    'assets/images/arandano_blanco.png',
                                                    width: 28,
                                                    height: 28,
                                                    fit: BoxFit.cover)))),
                                  ],
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  InkWell(
                                      child: Text("Arandano - Módulo ${moduloselect == null ? '-' : moduloselect!}",
                                          style: TextStyle(
                                              color: Colors.grey[700],
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15)),
                                      onTap: (){
                                        showDialog(
                                            context: context,
                                            builder: (context) =>
                                            const CustomDialogsActividad(
                                                title: "Selecciona el módulo \n al que ingresarás",
                                                description:
                                                'No hay acopios disponibles \n en este modulo',
                                                imagen:
                                                "assets/images/warning.png"));
                                      }),

                                      Text('$jabasporlimpiar JABAS POR SUBIR', style: const TextStyle(
                                          fontWeight: FontWeight.bold, color: Colors.red)),
                                      Text('$jabasporlimpiars Jabas cargadas', style: const TextStyle(
                                          fontWeight: FontWeight.bold)),
                                      Text(
                                          'Distancia total: ${double.parse((distancia == null
                                                      ? '0'
                                                      : distancia!))
                                                  .toStringAsFixed(2)} ${distancia == null
                                                      ? 'METROS': 'METROS'}',
                                          style:
                                              const TextStyle(color: kArandano))
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.upload_outlined),
                                  onPressed: () async {
                                    setState(() {
                                      subirJabasManual();
                                      });
                                  },
                                ),
                              ],
                            )),
                        // ignore: avoid_unnecessary_containers
                        Container(
                            child: Column(
                          children: [
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(50),
                                      image: const DecorationImage(
                                          image: AssetImage(
                                              'assets/images/avatar.png'),
                                          fit: BoxFit.cover),
                                      border: Border.all(
                                          color: kArandano, width: 4)),
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children:  [
                                    Text('CONDUCTOR: ${name == null ? '-' : name!}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold)),
                                    // ignore: unnecessary_null_comparison

                                    Text('Vehículo: ${placa!}'),
                                  ],
                                )),
                              ],
                            )
                          ],
                        ))
                      ],
                    ))),
            Positioned(
                //alignment: Alignment.bottomRight,
                top: 170,
                right: 2,
                child: Column(
                  children: <Widget>[
                    GestureDetector(
                      child: Container(
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                            color: kArandano,
                            shape: BoxShape.rectangle,
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 10.0,
                                offset: Offset(0.0, 10.0),
                              )
                            ]),
                        child: ClipOval(
                            child: Container(
                                color: kArandano,
                                //margin: EdgeInsets.only(top: 45),
                                padding: const EdgeInsets.all(5),
                                child: const Icon(
                                  Icons.sync,
                                  color: Colors.white,
                                  size: 32,
                                ))),
                      ),
                      onTap: () async {
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
                                          Text("Verificando conexión de red")
                                        ]),
                                      )));
                            });
                        try {
                          final result =
                              await InternetAddress.lookup('google.com');
                          if (result.isNotEmpty &&
                              result[0].rawAddress.isNotEmpty) {
                            print('connected');
                            print("-----------prueba sync1--------------");
                            recibirAcopiosMapeados();
                            print("-----------prueba sync2--------------");
                          }
                        } on SocketException catch (_) {
                          codigo_internet = 0;
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
                                        content: const Text(
                                            'Revisa tu conexión a internet'),
                                        actions: [okButton]));
                              });
                          print('not connected');
                        }
                        Navigator.pop(context);
                        // zoomInMarker();
                      },
                    ),
                    const SizedBox(height: 10),
                    GestureDetector(
                      child: Container(
                        margin: const EdgeInsets.only(top: 10, right: 10),
                        decoration: BoxDecoration(
                            color: Colors.grey,
                            shape: BoxShape.rectangle,
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 10.0,
                                offset: Offset(0.0, 10.0),
                              )
                            ]),
                        child: ClipOval(
                            child: Container(
                                color: kArandano,
                                //margin: EdgeInsets.only(top: 45),
                                padding: const EdgeInsets.all(5),
                                child: const Icon(
                                  Icons.add_location_alt,
                                  color: Colors.white,
                                  size: 32,
                                ))),
                      ),
                      onTap: () async {
                        try {
                          final result =
                              await InternetAddress.lookup('google.com');
                          if (result.isNotEmpty &&
                              result[0].rawAddress.isNotEmpty) {
                            print('connected');
                            recibirAcopiosRestantes();
                            print("-----------prueba sync2--------------");
                          }
                        } on SocketException catch (_) {
                          codigo_internet = 0;
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
                                        content: const Text(
                                            'Revisa tu conexión a internet'),
                                        actions: [okButton]));
                              });
                          print('not connected');
                        }
                      },
                    ),
                    GestureDetector(
                      child: Container(
                        margin: const EdgeInsets.only(top: 10, right: 10),
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
                        child: ClipOval(
                            child: Container(
                                color: kPanetone,
                                //margin: EdgeInsets.only(top: 45),
                                padding: const EdgeInsets.all(5),
                                child: const Icon(
                                  Icons.exit_to_app,
                                  color: Colors.white,
                                  size: 32,
                                ))),
                      ),
                      onTap: () async {
                        showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            });
                        totalDistance = _coordinateDistance(
                            -7.067140, -79.558578,
                            currentLocationes!.latitude,
                            currentLocationes!.longitude);
                        var placeDistance = totalDistance * 1000;
                        print("DISTANCIA DEL PUNTO INICIAL: ${placeDistance.toStringAsFixed(2)}");

                        if (double.parse(placeDistance.toStringAsFixed(2)) <=
                            50) {
                          Widget okButton = TextButton(
                            child: const Text("CONFIRMAR"),
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
                                              child: Column(
                                                  children: const <Widget>[
                                                    CircularProgressIndicator(),
                                                    SizedBox(height: 5),
                                                    Text("Guardando viaje")
                                                  ]),
                                            )));
                                  });
                              estadoinsert = "terminado";
                              _obtenerCodigoVehiculo();
                              String codigov = codigoviaje ?? '0';
                              var response = await http.get(
                                  Uri.parse("${url_base}acp/index.php/transportearandano/setTravelUpdate?accion=estadoViaje&idviajes=$codigov&tipo=1"),
                                  headers: {"Accept": "application/json"});
                              if (mounted) {
                                setState(() {
                                  var extraerData = json.decode(response.body);
                                  String results =
                                      extraerData["state"].toString();
                                  print("RESULTADO ESTADO VIAJE: $results");
                                  if (results == "true") {
                                    jabas_moment = 0;
                                    StringBuffer xmlViajesAcopio =
                                        StringBuffer();

                                    String cabeceraXml =
                                        "<?xml version=\"1.0\" encoding=\"ISO-8859-1\"?><SOLICITUD_DESTINO>";
                                    String itemXml = "";
                                    DatabaseProvider.db
                                        .getJabasWithoutAlias(
                                            int.parse(codigov))
                                        .then((List<Jabas> jabas) {
                                      if (jabas.isNotEmpty) {
                                        for (var i = 0; i < jabas.length; i++) {
                                          itemXml += "<Item IDVIAJES=\"${jabas[i].idviaje}\" LATITUD=\"${jabas[i].lat!}\" LONGITUD=\"${jabas[i].long!}\" ALIAS=\"${jabas[i].alias!}\" CANTJABAS=\"${jabas[i]
                                                  .jabascargadas}\" ESTADO=\"1\" DESCRIPCION=\"${jabas[i].descripcion!}\" JABASCARGADAS=\"${jabas[i]
                                                  .jabascargadas}\" FLLEGADA=\"${jabas[i].fllegada!}\" EXPORTABLE=\"${jabas[i].exportable}\" NACIONAL=\"${jabas[i].nacional}\" DESMEDRO=\"${jabas[i].desmedro}\" FRUTAC=\"${jabas[i].frutac}\" VARIEDAD=\"${jabas[i].variedad}\" CONDICION=\"${jabas[i].condicion}\" CONSUMIDOR=\"${jabas[i].consumidor}\" VALVULA=\"${jabas[i].valvula}\" OBSERVACIONES=\"${jabas[i]
                                                  .observaciones}\" />";
                                          DatabaseProvider.db.updateJabasViaje(
                                              jabas[i].idviaje!,
                                              jabas[i].alias!);
                                        }
                                      }
                                      String pieXml = "</SOLICITUD_DESTINO>";
                                      String xml2 =
                                          cabeceraXml + itemXml + pieXml;
                                      xmlViajesAcopio.write(xml2);
                                      guardarAcopios(
                                          xmlViajesAcopio.toString());
                                      print("XML2: $xmlViajesAcopio");
                                    });
                                    reiniciarAcopios();
                                    Navigator.pop(context);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const SecondPage(),
                                      ),
                                    );
                                  }
                                });
                              }
                            },
                          );
                          Widget cancelButton = TextButton(
                            child: const Text("CANCELAR"),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                          );
                          showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                    content: const Text(
                                        "¿Estas seguro de terminar el viaje?"),
                                    actions: [okButton, cancelButton],
                                  ));
                        } else {
                          Widget cancelButton = TextButton(
                            child: const Text("CANCELAR"),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                          );
                          showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                    content: const Text(
                                        "No puedes cerrar el viaje en este punto"),
                                    actions: [cancelButton],
                                  ));
                        }
                      },
                    ),
                  ],
                )),
          ],
        )
            //: Loader(),
            ));
  }
}
class CustomDialogsActividad extends StatefulWidget {
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
  _CustomDialogsActividadState createState() => _CustomDialogsActividadState();
}

class _CustomDialogsActividadState extends State<CustomDialogsActividad> {
  String? dropdownValue;
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
                widget.title!,
                style: const TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Divider(),
              const SizedBox(height: 10.0),
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
                "MODULO 12",
              ].map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                    value: value, child: Text(value));
              }).toList(),
            ),
              const SizedBox(height: 12.0),
              Row( children: <Widget>[
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () {

                      Navigator.pop(context);
                    },
                    child: const Text(
                      "Confirmar",
                      style: TextStyle(
                          fontWeight: FontWeight.w700, color: kPrimaryColor),
                    ),
                  ),
                ),
                SizedBox(width: size.width/4,),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text(
                      "Cancelar",
                      style: TextStyle(
                          fontWeight: FontWeight.w700, color: Colors.grey),
                    ),
                  ),
                )
              ]),
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
            backgroundImage: AssetImage(widget.imagen!),
          ),
        )
      ],
    );
  }
}