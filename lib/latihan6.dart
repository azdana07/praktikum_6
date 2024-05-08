import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Universities in ASEAN',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: BlocProvider(
        create: (_) => UniversityBloc()..add(UniversityFetchRequested('Indonesia')),
        child: UniversityList(),
      ),
    );
  }
}

// Models
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

// Bloc Events
abstract class UniversityEvent {}
class UniversityFetchRequested extends UniversityEvent {
  final String country;

  UniversityFetchRequested(this.country);
}

// Bloc States
abstract class UniversityState {}
class UniversityInitial extends UniversityState {}
class UniversityLoading extends UniversityState {}
class UniversityLoaded extends UniversityState {
  final List<University> universities;

  UniversityLoaded(this.universities);
}
class UniversityError extends UniversityState {
  final String message;

  UniversityError(this.message);
}

// Bloc
class UniversityBloc extends Bloc<UniversityEvent, UniversityState> {
  UniversityBloc() : super(UniversityInitial());

  @override
  Stream<UniversityState> mapEventToState(UniversityEvent event) async* {
    if (event is UniversityFetchRequested) {
      yield UniversityLoading();
      try {
        final universities = await fetchUniversities(event.country);
        yield UniversityLoaded(universities);
      } catch (e) {
        yield UniversityError(e.toString());
      }
    }
  }
}

Future<List<University>> fetchUniversities(String country) async {
  final response = await http.get(Uri.parse('http://universities.hipolabs.com/search?country=$country'));
  if (response.statusCode == 200) {
    List<dynamic> universitiesJson = jsonDecode(response.body);
    return universitiesJson.map((json) => University.fromJson(json)).toList();
  } else {
    throw Exception('Failed to load university data');
  }
}

// UI Component
class UniversityList extends StatefulWidget {
  @override
  _UniversityListState createState() => _UniversityListState();
}

class _UniversityListState extends State<UniversityList> {
  String currentCountry = 'Indonesia';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Universities in $currentCountry'),
      ),
      body: Column(
        children: [
          DropdownButton<String>(
            value: currentCountry,
            onChanged: (String? newValue) {
              if (newValue != null) {
                setState(() {
                  currentCountry = newValue;
                });
                context.read<UniversityBloc>().add(UniversityFetchRequested(newValue));
              }
            },
            items: <String>['Indonesia', 'Singapore', 'Malaysia', 'Thailand', 'Philippines']
                .map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
          ),
          Expanded(
            child: BlocBuilder<UniversityBloc, UniversityState>(
              builder: (context, state) {
                if (state is UniversityLoading) {
                  return Center(child: CircularProgressIndicator());
                } else if (state is UniversityLoaded) {
                  return ListView.builder(
                    itemCount: state.universities.length,
                    itemBuilder: (context, index) {
                      var university = state.universities[index];
                      return ListTile(
                        title: Text(university.name),
                        subtitle: Text(university.webPage),
                        onTap: () => launchWebsite(university.webPage),
                      );
                    },
                  );
                } else if (state is UniversityError) {
                  return Center(child: Text(state.message));
                }
                return Center(child: Text('Select a country to view universities'));
              },
            ),
          ),
        ],
      ),
    );
  }

  void launchWebsite(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }
}
