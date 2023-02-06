import 'package:first_flutter_app/addTodo.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'todo.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Future<Database> database = initDatabase();

    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => DatabaseApp(database),
        '/add': (context) => AddTodoApp(database),
      },
    );
  }

  Future<Database> initDatabase() async {
    return openDatabase(
      join(
        await getDatabasesPath(),
        'todo_database.db',
      ),
      onCreate: ((db, version) {
        return db.execute(
          "CREATE TABLE todos(id INTEGER PRIMARY KEY AUTOINCREMENT, "
          "title TEXT, content TEXT, active INTEGER)",
        );
      }),
      version: 1,
    );
  }
}

class DatabaseApp extends StatefulWidget {
  // const DatabaseApp({Key? key}) : super(key: key);
  final Future<Database> db;

  const DatabaseApp(this.db);

  @override
  State<DatabaseApp> createState() => _DatabaseAppState();
}

class _DatabaseAppState extends State<DatabaseApp> {
  Future<List<Todo>>? todoList;

  @override
  void initState() {
    super.initState();
    todoList = getTodos();
  }

  void _insertTodo(Todo todo) async {
    final Database database = await widget.db;
    await database.insert(
      'todos',
      todo.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    setState(() {
      todoList = getTodos();
    });
  }

  Future<List<Todo>> getTodos() async {
    final Database database = await widget.db;
    final List<Map<String, dynamic>> maps = await database.query('todos');

    return List.generate(
      maps.length,
      ((index) {
        int active = maps[index]['active'] == 1 ? 1 : 0;

        return Todo(
          title: maps[index]['title'].toString(),
          content: maps[index]['content'].toString(),
          active: active,
          id: maps[index]['id'],
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Database Example'),
      ),
      body: Container(
        child: Center(
          child: FutureBuilder(
            builder: ((context, snapshot) {
              switch (snapshot.connectionState) {
                case ConnectionState.none:
                  return const CircularProgressIndicator();
                case ConnectionState.waiting:
                  return const CircularProgressIndicator();
                case ConnectionState.active:
                  return const CircularProgressIndicator();
                case ConnectionState.done:
                  if (snapshot.hasData) {
                    return ListView.builder(
                      itemBuilder: ((context, index) {
                        Todo todo = (snapshot.data as List<Todo>)[index];
                        return Card(
                          child: Column(
                            children: <Widget>[
                              Text(todo.title!),
                              Text(todo.content!),
                              Text(todo.active == 1 ? 'true' : 'false'),
                            ],
                          ),
                        );
                      }),
                      itemCount: (snapshot.data as List<Todo>).length,
                    );
                  } else {
                    return const Text('No data');
                  }
              }
              return const CircularProgressIndicator();
            }),
            future: todoList,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final todo = await Navigator.of(context).pushNamed('/add');
          if (todo != null) {
            _insertTodo(todo as Todo);
          }
        },
        child: const Icon(
          Icons.add,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
