import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:equatable/equatable.dart';

void main() {
  runApp(AplikasiUniversitas());
}

class AplikasiUniversitas extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Universitas di ASEAN',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: BlocProvider(
        create: (_) => UniversitasCubit(),
        child: DaftarUniversitas(),
      ),
    );
  }
}

class Universitas {
  final String nama;
  final String webPage;

  Universitas({required this.nama, required this.webPage});

  factory Universitas.fromJson(Map<String, dynamic> json) {
    return Universitas(
      nama: json['name'],
      webPage: json['web_pages'][0],
    );
  }
}

// Cubit dan State

class UniversitasCubit extends Cubit<UniversitasState> {
  UniversitasCubit() : super(UniversitasInitial());

  Future<void> ambilUniversitas(String negara) async {
    emit(UniversitasLoading());
    final response = await http.get(Uri.parse('http://universities.hipolabs.com/search?country=$negara'));
    if (response.statusCode == 200) {
      List<dynamic> jsonUniversitas = jsonDecode(response.body);
      List<Universitas> universitas = jsonUniversitas.map((json) => Universitas.fromJson(json)).toList();
      emit(UniversitasLoaded(universitas));
    } else {
      emit(UniversitasError("Gagal memuat data universitas"));
    }
  }
}

abstract class UniversitasState extends Equatable {
  const UniversitasState();
  @override
  List<Object> get props => [];
}

class UniversitasInitial extends UniversitasState {}
class UniversitasLoading extends UniversitasState {}
class UniversitasLoaded extends UniversitasState {
  final List<Universitas> universitas;
  const UniversitasLoaded(this.universitas);
  @override
  List<Object> get props => [universitas];
}

class UniversitasError extends UniversitasState {
  final String pesan;
  const UniversitasError(this.pesan);
  @override
  List<Object> get props => [pesan];
}

// Komponen UI

class DaftarUniversitas extends StatefulWidget {
  @override
  _DaftarUniversitasState createState() => _DaftarUniversitasState();
}

class _DaftarUniversitasState extends State<DaftarUniversitas> {
  String negaraSaatIni = 'Indonesia';

  @override
  void initState() {
    super.initState();
    context.read<UniversitasCubit>().ambilUniversitas(negaraSaatIni);
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
                context.read<UniversitasCubit>().ambilUniversitas(nilaiBaru);
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
            child: BlocBuilder<UniversitasCubit, UniversitasState>(
              builder: (context, state) {
                if (state is UniversitasLoading) {
                  return Center(child: CircularProgressIndicator());
                } else if (state is UniversitasLoaded) {
                  return ListView.builder(
                    itemCount: state.universitas.length,
                    itemBuilder: (context, index) {
                      var universitas = state.universitas[index];
                      return ListTile(
                        title: Text(universitas.nama),
                        subtitle: Text(universitas.webPage),
                        onTap: () => bukaWebsite(universitas.webPage),
                      );
                    },
                  );
                } else if (state is UniversitasError) {
                  return Center(child: Text(state.pesan));
                }
                return Container();  // Handle other states
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
