import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CommsSettings extends StatefulWidget {
  final String _prefix;

  const CommsSettings(this._prefix);

  @override State<CommsSettings> createState() => _CommsSettingsState();
}

class _CommsSettingsState extends State<CommsSettings> {
  final TextEditingController _hc = TextEditingController(text: 'www.dealingtechnology.com');
  final TextEditingController _pc = TextEditingController(text: '10110');

  Future<SharedPreferences> _prefs; // NMEA default port

  _CommsSettingsState();

  String get host => _hc.text..trim();
  int get port => int.parse(_pc.text..trim());

  final _formKey = GlobalKey<FormState>();

  @override initState() {
    super.initState();
    _prefs = SharedPreferences.getInstance();
  }

  @override
  Widget build(BuildContext context) {


    return Scaffold(

        appBar: AppBar(title: Text('Settings')),
        body: Form(
          key: _formKey,
          child: FutureBuilder(
              future: _prefs,
              builder: (context, prefs) {
                _hc.text = prefs.data.get("${widget._prefix}.host")??"www.jmarine.org";
                _pc.text = prefs.data.get("${widget._prefix}.port").toString()??"10110";
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    TextFormField(
                      controller: _hc,
                      decoration: InputDecoration(
                          counterText: 'Hostname or IP address',
                          hintText: 'Hostname'
                      ),
                      validator: (value) {
                        if (value.isEmpty) {
                          return 'Please enter some text';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: _pc,
                      decoration: InputDecoration(
                          counterText: 'Port number',
                          hintText: 'Port number'
                      ),
                      validator: (value) {
                        try {
                          if (int.parse(value) > 0) {
                            return null;
                          }
                        } catch (err) {}
                        return 'Please enter positive number';
                      },
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: RaisedButton(
                        onPressed: () {
                          if (_formKey.currentState.validate() == true) {
                            prefs.data.setString("${widget._prefix}.host", host);
                            prefs.data.setInt("${widget._prefix}.port", port);
                            Navigator.of(context).pop(this);
                          }
                        },
                        child: Text('Submit'),
                      ),
                    ),
                  ],
                );
              }),
        ));
  }
}
