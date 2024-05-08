import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(AplikasiSaya());
}

class AplikasiSaya extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Universitas di ASEAN',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: ChangeNotifierProvider(
        create: (context) => PenyediaUniversitas(),
        child: DaftarUniversitas(),
      ),
    );
  }
}

class University {
  final String name;
  final String webPage;

  University({required this.name, required this.webPage});

  factory University.fromJson(Map<String, dynamic> json) {
    return University(
      name: json['name'],
      webPage: json['web_pages'][0],
    );
  }
}

class PenyediaUniversitas with ChangeNotifier {
  List<University> _universities = [];

  List<University> get universities => _universities;

  Future<void> ambilUniversitas(String negara) async {
    final response = await http.get(Uri.parse('http://universities.hipolabs.com/search?country=$negara'));
    if (response.statusCode == 200) {
      List<dynamic> jsonUniversitas = jsonDecode(response.body);
      _universities = jsonUniversitas.map((json) => University.fromJson(json)).toList();
      notifyListeners();
    } else {
      throw Exception('Gagal memuat data universitas');
    }
  }
}

class DaftarUniversitas extends StatefulWidget {
  @override
  _DaftarUniversitasState createState() => _DaftarUniversitasState();
}

class _DaftarUniversitasState extends State<DaftarUniversitas> {
  String negaraSaatIni = 'Indonesia';

  @override
  void initState() {
    super.initState();
    Provider.of<PenyediaUniversitas>(context, listen: false).ambilUniversitas(negaraSaatIni);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Universitas di $negaraSaatIni'),
      ),
      body: Column(
        children: [
          DropdownButton<String>(
            value: negaraSaatIni,
            onChanged: (String? nilaiBaru) {
              if (nilaiBaru != null) {
                setState(() => negaraSaatIni = nilaiBaru);
                Provider.of<PenyediaUniversitas>(context, listen: false).ambilUniversitas(nilaiBaru);
              }
            },
            items: <String>['Indonesia', 'Singapura', 'Malaysia', 'Thailand', 'Filipina']
                .map<DropdownMenuItem<String>>((String nilai) {
              return DropdownMenuItem<String>(
                value: nilai,
                child: Text(nilai),
              );
            }).toList(),
          ),
          Expanded(
            child: Consumer<PenyediaUniversitas>(
              builder: (context, penyedia, child) {
                if (penyedia.universities.isNotEmpty) {
                  return ListView.builder(
                    itemCount: penyedia.universities.length,
                    itemBuilder: (context, index) {
                      var universitas = penyedia.universities[index];
                      return ListTile(
                        title: Text(universitas.name),
                        subtitle: Text(universitas.webPage),
                        onTap: () => bukaWebsite(universitas.webPage),
                      );
                    },
                  );
                } else {
                  return Center(child: CircularProgressIndicator());
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  void bukaWebsite(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Tidak bisa membuka $url';
    }
  }
}
