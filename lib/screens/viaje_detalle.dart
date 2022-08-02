import 'dart:collection';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:transporte_arandanov2/constants.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:transporte_arandanov2/screens/edicion_viaje.dart';
import 'package:transporte_arandanov2/screens/second_page.dart';

const double pinVisiblePosition = 20;
const double pinInVisiblePosition = -220;
const LatLng sourceLocation = LatLng(-7.038162, -79.534870);
const LatLng medioLocations = LatLng(-7.036857, -79.534719);
const LatLng destLocation = LatLng(-7.035962, -79.535266);

// ignore: must_be_immutable
class MyViajeDetail extends StatefulWidget {
  String? numeroViaje;
  int? cantjabas;
  double? distance;
  int? tiempo;
  String? finicio;
  String? ffin;
  String? ruta;
  int? idviajes;
  MyViajeDetail(
      {Key? key,
      this.numeroViaje,
      this.cantjabas,
      this.distance,
      this.finicio,
      this.ffin,
      this.idviajes,
      this.ruta})
      : super(key: key);

  @override
  _MyViajeDetailState createState() => _MyViajeDetailState();
}

class _MyViajeDetailState extends State<MyViajeDetail> {
  final Set<Marker> _markers = HashSet<Marker>();
  final Set<Polygon> _polygons = HashSet<Polygon>();
  final Set<Polyline> _polylines = HashSet<Polyline>();
  final Set<Circle> _circles = HashSet<Circle>();
  double pinPillPosition = pinVisiblePosition;
  LatLng? currentLocation;
  LatLng? destinationLocation;
  LatLng? mediaLocation;
  BitmapDescriptor? sourceIcon;
  BitmapDescriptor? destinationIcon;
  BitmapDescriptor? mediaIcon;
  bool userBadgeSelected = false;
  String? placa;
  bool resetToggle = false;

  List? data;
  List? data1;
  List? datareal;
  List? datarutas;
  Future<void> recibirDatos() async {
    // ignore: prefer_typing_uninitialized_variables
    var idtransp;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      idtransp = prefs.get("id") ?? 0;
      placa = (prefs.get("placa") ?? "-") as String?;
      print('IDS: ' + idtransp);
    });
    var response = await http.get(
        Uri.parse("${url_base}WSPowerBI/controller/transportearandano.php?accion=detalleviajes&idviajes=${widget.idviajes}&estado=1"),
        headers: {"Accept": "application/json"});
    setState(() {
      var extraerData = json.decode(response.body);
      data = extraerData["datos"];
      _markers.add(Marker(
          markerId: const MarkerId("V1"),
          position: const LatLng(-7.066769, -79.558876),
          //position: LatLng(-6.7859793, -79.8468537),
          icon: mediaIcon!));
      for (var i = 0; i < data!.length; i++) {
        _markers.add(
          Marker(
              markerId: MarkerId(data![i]["ALIAS"]),
              position: LatLng(double.parse(data![i]["LATITUD"]),
                  double.parse(data![i]["LONGITUD"])),
              icon: sourceIcon!),
        );
      }
    });
  }

  Future<void> recibirRutaReal() async {
    var response = await http.get(
        Uri.parse("${url_base}WSPowerBI/controller/transportearandano.php?accion=positionreal&idviajes=${widget.idviajes}"),
        headers: {"Accept": "application/json"});
    setState(() {
      var extraerData = json.decode(response.body);
      datareal = extraerData["datos"];
      List<LatLng> polylineLatLongs = [];

      for (var i = 0; i < datareal!.length; i++) {
        polylineLatLongs.add(LatLng(double.parse(datareal![i]["LATITUD"]),
            double.parse(datareal![i]["LONGITUD"])));
        print(datareal![i]["LATITUD"] + " LONGITUD" + datareal![i]["LONGITUD"]);
        _polylines.add(
          Polyline(
            polylineId: const PolylineId("rutareal"),
            points: polylineLatLongs,
            color: Colors.red,
            width: 8,
          ),
        );
      }
    });
  }

  Future<void> EliminarRegistro(String idviajee, String cantjabase, String fechafine) async {
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
                      Text("Eliminando trazabilidad")
                    ]),
                  )));
        });
    //var hra = new DateFormat('hh:mm:ss');
    //var hras = hra.format(fechafine as DateTime);
   // print("-"+idviajee+"-"+cantjabase+"-"+hras);
    String hras = fechafine.replaceAll("-", "");
    var response = await http.post(
        Uri.parse(
            "${url_base}acp/index.php/transportearandano/setDeleteJabasApp"),
        body: {"idviajes": idviajee, "jabascargadas": cantjabase, "hora": hras});
    if (mounted) {
      setState(() {
        var extraerData = json.decode(response.body);
        String result = extraerData["state"].toString();
        print("RESULTADO DE INSERCIÓN DE acopios: $result");
      });
    }
    Navigator.pop(context);
  }


  Future<void> recibirArcos() async {
    if (widget.ruta == '-') {
      print("RUTA:${widget.ruta!}");
    } else {
      var extraerData = Map<String, dynamic>.from(json.decode(widget.ruta!));
      data1 = extraerData["datos"]["coordenadas"];
      print("RESPUESTA RUTA: $data1");
      List<LatLng> polylineLatLongs = [];

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
    }
    // });
  }

  @override
  void initState() {
    super.initState();
    recibirDatos();
    recibirArcos();
    setInitialLocation();
  }

  void setInitialLocation() {
    currentLocation = LatLng(sourceLocation.latitude, sourceLocation.longitude);

    mediaLocation = LatLng(medioLocations.latitude, medioLocations.longitude);

    destinationLocation = LatLng(destLocation.latitude, destLocation.longitude);
  }

  void setSourceAndDestinationMarkerIcons(BuildContext context) async {
    sourceIcon = await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(devicePixelRatio: 2),
        'assets/images/arandano_marker.png');

    mediaIcon = await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(devicePixelRatio: 2),
        'assets/images/flages.png');

    destinationIcon = await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(devicePixelRatio: 1),
        'assets/images/arandano_marker.png');
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    setSourceAndDestinationMarkerIcons(context);
    return Scaffold(
      body: Stack(children: <Widget>[
        ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
            bottomRight: Radius.circular(30),
            bottomLeft: Radius.circular(30),
          ),
          child: SizedBox(
            height: size.height / 2.2,
            child: Align(
              alignment: Alignment.bottomRight,
              heightFactor: 0.3,
              widthFactor: 2.5,
              child: Scaffold(
                body: Stack(
                  children: <Widget>[
                    GoogleMap(
                      initialCameraPosition: const CameraPosition(
                        target: LatLng(-7.043901, -79.541921),
                        zoom: 12,
                      ),
                      compassEnabled: false,
                      mapType: MapType.satellite,
                      markers: _markers,
                      polygons: _polygons,
                      polylines: _polylines,
                      circles: _circles,
                      myLocationEnabled: false,
                      myLocationButtonEnabled: true,
                    ),
                    Align(
                        alignment: Alignment.bottomRight,
                        child: GestureDetector(
                          child: Container(
                            margin:
                                const EdgeInsets.only(bottom: 60, right: 30),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              child: const Text(
                                "ARANDANO",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontStyle: FontStyle.italic),
                              ),
                            ),
                            decoration: BoxDecoration(
                                // color: kArandano,
                                shape: BoxShape.rectangle,
                                borderRadius: BorderRadius.circular(50),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 10.0,
                                    offset: Offset(0.0, 10.0),
                                  )
                                ]),
                          ),
                          onTap: () {},
                        )),
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
                            Navigator.pop(context);
                           /* Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SecondPage(),
                              ),
                            );*/
                          },
                        )),
                    Align(
                        alignment: Alignment.bottomRight,
                        child: GestureDetector(
                          child: Container(
                            margin:
                                const EdgeInsets.only(bottom: 20, right: 30),
                            decoration: BoxDecoration(
                              color: kPanetone,
                              shape: BoxShape.rectangle,
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              child: Text(
                                "${widget.cantjabas} jabas",
                                style: const TextStyle(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          onTap: () {},
                        )),
                  ],
                ),
                floatingActionButtonLocation:
                    FloatingActionButtonLocation.startFloat,
                floatingActionButton: FloatingActionButton(
                  backgroundColor: kArandano,
                  onPressed: (){
                    recibirDatos();
                  },
                  child: Image.asset('assets/images/arandano_blanco.png',
                      width: 28, height: 28, fit: BoxFit.cover),
                ),
              ),
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            height: size.height / 2,
            margin: const EdgeInsets.only(left: 22, right: 22),
            padding: const EdgeInsets.only(top: 10),
            child: SizedBox(
                height: size.height / 2,
                child: ListView.builder(
                    scrollDirection: Axis.vertical,
                    shrinkWrap: true,
                    itemCount: data == null ? 0 : data!.length,
                    itemBuilder: (BuildContext context, i) {
                      if (data == null) {
                        return const CircularProgressIndicator();
                      } else {
                        if (data![i]["DESCRIPCION"] == '-') {
                          return Container();
                        } else {
                          return Container(
                            margin: const EdgeInsets.only(top: 15),
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: [
                                  BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 10,
                                      offset: Offset.zero)
                                ]),
                            child: Row(
                              children: [
                                Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    ClipOval(
                                      child: Image.asset(
                                          'assets/images/arandano_icon.png',
                                          width: 60,
                                          height: 60,
                                          fit: BoxFit.cover),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(data![i]["DESCRIPCION"] ?? "-",
                                          style: TextStyle(
                                              color: Colors.grey[700],
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15)),
                                      const SizedBox(height: 2),
                                      Text('JABAS: ' +
                                          data![i]["JABASCARGADAS"]),
                                      const SizedBox(height: 2),
                                      Text(
                                          // ignore: unnecessary_null_comparison
                                          'LLEGADA: ' + data![i]["FLLEGADA"] ==
                                                  null
                                              ? '00:00:00'
                                              : data![i]["FLLEGADA"],
                                          style: const TextStyle(
                                              color: kPrimaryColor,
                                              fontSize: 14)),
                                      const SizedBox(height: 2),
                                    ],
                                  ),
                                ),
                                placa!.contains('ADM') ?
                                Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      IconButton(
                                      icon: const Icon(Icons.edit,
                                          color: kPrimaryColor, size: 30), onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                EdicionViaje(
                                                  idviajes: widget.idviajes.toString(), jabascargadas: data![i]["JABASCARGADAS"],fecha: data![i]["FLLEGADA"]
                                                ),
                                          ),
                                        );
                                      }),
                                      const SizedBox(height: 20,),
                                      IconButton(onPressed:() async{
                                        await EliminarRegistro(widget.idviajes.toString(), data![i]["JABASCARGADAS"], data![i]["FLLEGADA"]);
                                        await recibirDatos();
                                      }, icon: const Icon(Icons.cleaning_services,
                                          color: Colors.red, size: 30))

                                    ]
                                ): Container()

                              ],
                            ),
                          );
                        }
                      }
                    })),
          ),
        )
      ]),
    );
  }
}
