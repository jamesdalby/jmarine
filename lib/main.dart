import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'package:nmea/nmea.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(JMarineShell());
}

class JMarineShell extends StatelessWidget {
  @override Widget build(BuildContext context) {
    return MaterialApp(
        title: 'JMarine',
        theme: ThemeData.dark(),
        home: Scaffold(
          appBar: AppBar(
            title: Text("JMarine"),

          ),
          body: JMarine(),

        )
    );
  }
}

final DateFormat _hms = DateFormat('HH:mm:ss');
final DateFormat _dmy = DateFormat('dd MMM yyyy');
String _deg0(dynamic v) => (v?.toStringAsFixed(0)?.padLeft(3, '0')??'---') + '°';
String _ps(dynamic v) => v == null ? '' : v == 0 || v == 180 ? '-' : v > 180 ? 'P' : 'S';
double _d180(dynamic v) => v == null ? null : v > 180 ? 360 - v : v;
String _deg180(dynamic v) => _deg0(_d180(v));
String _1dp(v) => v?.toStringAsFixed(1) ?? '';
String _kts(v) => 'kts';
String _nm(v) => 'nm';
String _true(v) => 'T';




class JMarine extends StatefulWidget {
  JMarine();

  @override createState() => _JMarineState();
}

// These globals hold the (real) state. They're updated by NMEAHandler,
// and references in the State<> objects.
_OneLineItemState
    _tws,
    _sog,
    _aws,
    _awd,
    _twd,
    _awa,
    _twa,
    _cog;

_TwoLineItemState
  _time,
  _btwdtw;

class _JMarineState extends State<JMarine> {
  WindGauge wind = WindGauge();
  NMEASocketReader _nmea;

  @override initState() {
    super.initState();

    _nmea = NMEASocketReader('www.dealingtechnology.com', 10110);
    _nmea.process(_handleNMEA);
  }

  void _handleNMEA(var msg) {
    if (msg is RMC) {
      _sog.setState(() => _sog.value = msg.sog);
      _time.setState(() => _time.value = [ msg.utc, msg.utc ]);
    }
    if (msg is MWD) {
      _twd.setState(() => _twd.value = msg.trueWindDirection);
      _tws.setState(() => _tws.value = msg.trueWindSpeedKnots);

    }
    if (msg is MWV) {
      // _awa.setState(() => _awa.value = msg.windAngle);

      if (msg.isTrue) {
        _tws.setState(() => _tws.value = msg.windSpeed);
        _twa.setState(() => _twa.value = msg.windAngle);

        _windGaugeState.setState(() => _windGaugeState.twa = msg.windAngle);
      } else {
        _aws.setState(() => _aws.value = msg.windSpeed);
        _windGaugeState.setState(() => _windGaugeState.awa = msg.windAngle);
      }
    }
    if (msg is VTG) {
      _cog.setState(() => _cog.value = msg.cogTrue);
    }
  }

  @override
  Widget build(BuildContext context) {
    OneLineItem tws = OneLineItem(() => _tws = _OneLineItemState('TWS', _1dp, _kts));
    OneLineItem sog = OneLineItem(() => _sog = _OneLineItemState('SOG', _1dp, _kts));
    OneLineItem aws = OneLineItem(() =>_aws = _OneLineItemState('AWS', _1dp, _kts));
    // OneLineItem awd = OneLineItem(() => _awd = _OneLineItemState('AWD', _deg0, _true));

    OneLineItem twd = OneLineItem(() => _twd = _OneLineItemState('TWD', _deg0, _true));
    // OneLineItem awa = OneLineItem(() => _awa = _OneLineItemState('AWA', _deg0, _true));
    OneLineItem twa = OneLineItem(() => _twa = _OneLineItemState('TWA', _deg180, _ps));
    OneLineItem cog = OneLineItem(() => _cog = _OneLineItemState('COG', _deg0, _true));
    TwoLineItem time = TwoLineItem(() => _time = _TwoLineItemState("Time & Date", (v) => v == null ? "--:--:--" : _hms.format(v), null, (v)=>v==null?'':_dmy.format(v), null));
    TwoLineItem wpt = TwoLineItem(() => _btwdtw = _TwoLineItemState("BTW & DTW",  _deg0, (v) => "T", _1dp, _nm));

    if (MediaQuery.of(context).orientation == Orientation.portrait){
      return Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              Expanded(flex: 20, child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [tws, wpt, time]
              )),
              Spacer(flex: 1),
              Expanded(flex: 20, child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [cog, sog]
                )),
              Spacer(flex: 1),
              Expanded(flex: 20, child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [aws, twd, twa]
              ))

              ]
          ),

          wind
        ]
      );

    } else {
      // is landscape


      return Row(children: [
        Expanded(child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [ tws, wpt, time, sog])),
        wind,
        Expanded(child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [aws, twd, twa, cog]
        ))
      ]
      );
    }
  }
}

_WindGaugeState _windGaugeState = _WindGaugeState();

class WindGauge extends StatefulWidget {
  @override _WindGaugeState createState() => _windGaugeState = _WindGaugeState();
}

class _WindGaugeState extends State<WindGauge> {
  double awa = 0;
  double twa = 0;

  @override Widget build(BuildContext context) {
    double fs = Theme.of(context).textTheme.headline5.fontSize;
    var smallgrey = TextStyle(fontSize: fs/2, color: Colors.grey);
    return SfRadialGauge(

        axes: <RadialAxis>[
          RadialAxis(
              minimum: 0,
              maximum: 360,
              interval: 30,
              startAngle: 270,
              endAngle: 270,
              radiusFactor: 1,

              canRotateLabels: true,
              onLabelCreated: axisLabelCreated,
              ranges: <GaugeRange>[
                GaugeRange(
                    startValue: 300,
                    endValue: 340,
                    color: Colors.red,
                    startWidth: 10,
                    endWidth: 10
                ),
                GaugeRange(
                    startValue: 20,
                    endValue: 60,
                    color: Colors.green,
                    startWidth: 10,
                    endWidth: 10
                )
              ],
              minorTicksPerInterval: 5,
              axisLabelStyle: GaugeTextStyle(
                  color: const Color(0xFF949494),
                  fontSize: 10
              ),
              minorTickStyle: MinorTickStyle(
                  color: const Color(0xFF616161),
                  thickness: 1.6,
                  length: 0.058,
                  lengthUnit: GaugeSizeUnit.factor
              ),
              majorTickStyle: MajorTickStyle(
                  color: const Color(0xFF949494),
                  thickness: 2.3,
                  length: 0.087,
                  lengthUnit: GaugeSizeUnit.factor
              ),

              pointers: <GaugePointer>[
                MarkerPointer(
                    value: awa,
                    enableAnimation: true,
                    animationDuration: 1000,
                    markerOffset: 0.2,
                    offsetUnit: GaugeSizeUnit.factor,
                    markerType: MarkerType.image,
                    imageUrl: 'images/A.png',
                    markerHeight: 55 ,
                    markerWidth: 19
                ),
                MarkerPointer(
                    value: twa,
                    enableAnimation: true,
                    animationDuration: 1000,
                    markerOffset: 0.2,
                    offsetUnit: GaugeSizeUnit.factor,
                    markerType: MarkerType.image,
                    imageUrl: 'images/T.png',
                    markerHeight: 55,
                    markerWidth: 19
                ),
              ],
              annotations: <GaugeAnnotation>[
                GaugeAnnotation(
                    widget: Container(
                        child:
                        Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('AWA', style: smallgrey),
                              Text(_deg180(awa), style: TextStyle(fontSize: fs*3, fontWeight: FontWeight.w200)),
                              Text(_ps(awa),style: smallgrey),
                            ]
                        )


                    ),
                    angle: 90,
                    positionFactor: 0.3)
              ])
        ]);
  }
  void axisLabelCreated(AxisLabelCreatedArgs args) {
    int a = int.parse(args.text);
    if (a == 360) args.text = '0';
    if (a > 180) args.text = (360-a).toString();
  }
}

class OneLineItem extends StatefulWidget {
  OneLineItem(this.v, {Key key}) : super(key: key);

  final _OneLineItemState Function() v;

  @override _OneLineItemState createState() => v();
}

class _OneLineItemState extends State<OneLineItem> {
  _OneLineItemState(this.label, this.fmtMain, this.fmtSuffix);

  final String label; // box label
  final String Function(dynamic v) fmtMain;
  final String Function(dynamic v) fmtSuffix;

  var v;

  set value(double value) { this.v = value; }

  @override
  Widget build(BuildContext context) {

    TextStyle th = Theme.of(context).textTheme.headline5;
    TextStyle smallgrey = th.apply(color: Colors.grey, fontSizeFactor: 0.5);
    TextStyle bigwhite = th.apply(color: Colors.white).apply(fontSizeFactor: 2, fontWeightDelta: -2);
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Align(
            alignment: Alignment.centerLeft,
            child: Text(
                label,
                style: smallgrey
            )),
        const Divider(height: 10, thickness: 2),
        Align(
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(fmtMain(v), style: bigwhite),
                Text(fmtSuffix?.call(v) ?? '', style: smallgrey),
              ],
            ))
      ],
      // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

class TwoLineItem extends StatefulWidget {
  TwoLineItem(this.v, {Key key}) : super(key: key);

  final _TwoLineItemState Function() v;

  @override _TwoLineItemState createState() => v();
}

class _TwoLineItemState extends State<TwoLineItem> {
  _TwoLineItemState(this.label, this.fmtMainTop, this.fmtSuffixTop, this.fmtMainBottom, this.fmtSuffixBottom);

  final String label;
  final String Function(dynamic v) fmtMainTop;
  final String Function(dynamic v) fmtSuffixTop;
  final String Function(dynamic v) fmtMainBottom;
  final String Function(dynamic v) fmtSuffixBottom;


  var vtop, vbottom;

  set value(List<dynamic > value) {
    vtop = value[0];
    vbottom = value[1];
  }

  @override
  Widget build(BuildContext context) {
    TextStyle th = Theme.of(context).textTheme.headline5;
    TextStyle white = th.apply(color: Colors.white, fontWeightDelta: -2);
    TextStyle smallgrey = th.apply(color: Colors.grey, fontSizeFactor: 0.5);


    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Align(
            alignment: Alignment.centerLeft,
            child: Text(
              label,
              textAlign: TextAlign.left,
              style:smallgrey
        )),
        const Divider(
          height: 10,
          thickness: 2
        ),
        Align(
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [

                Text(fmtMainTop?.call(vtop)??'', style: white),
                Text(fmtSuffixTop?.call(vtop)??'', style: smallgrey),
              ],
            )),
        Align(
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(fmtMainBottom?.call(vbottom) ?? '', style: white),
                Text(fmtSuffixBottom?.call(vbottom) ?? '', style: smallgrey),
              ],
            ))
      ],
      // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
