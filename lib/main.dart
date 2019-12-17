import 'package:flutter/material.dart';

import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(MaterialApp(
    home: Home(),
  ));
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final _todoController = TextEditingController();

  List _todoList = [];

  Map<String, dynamic> _lastRemoved;
  int _lastRemovePos;

  @override
  void initState() {
    super.initState();

    _readData().then((data) {
      setState(() {
        _todoList = json.decode(data);
      });
    });
  }

  void _addTodo() {
    Map<String, dynamic> newTodo = Map();
    newTodo["title"] = _todoController.text;
    _todoController.text = "";
    newTodo["ok"] = false;

    setState(() {
      _todoList.add(newTodo);
    });

    _saveData();
  }

  Future<File> _getFile() async {
    //path provider abstrai as diferencas entre iOS e android para salvar arquivos em disco
    final directory = await getApplicationDocumentsDirectory();
    return File("${directory.path}/data.json");
  }

  Future<File> _saveData() async {
    String data = json.encode(_todoList);

    final file = await _getFile();
    return file.writeAsString(data);
  }

  Future<String> _readData() async {
    try {
      final file = await _getFile();
      return file.readAsString();
    } catch (e) {
      print(e);
      return null;
    }
  }

  Future<Null> _refresh() async {
    //Apenas para simular o carregar no servidor
    await Future.delayed(Duration(seconds: 1));

    setState(() {
      _todoList.sort((a,b) {
        if (a["ok"] && !b["ok"]) return 1;
        else if (!a["ok"] && b["ok"]) return -1;
        else return 0;
      });
    });

    _saveData();

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Lista de Tarefas'),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
      ),
      body: Column(
        children: <Widget>[
          Container(
            padding: EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _todoController,
                    decoration: InputDecoration(
                      labelText: 'Nova Tarefa',
                      labelStyle: TextStyle(color: Colors.blueAccent),
                    ),
                  ),
                ),
                RaisedButton(
                  color: Colors.blueAccent,
                  child: Text('ADD'),
                  textColor: Colors.white,
                  onPressed: _addTodo,
                )
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: ListView.builder(
                  padding: EdgeInsets.only(top: 10),
                  itemCount: _todoList.length,
                  itemBuilder: buildItem),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildItem(BuildContext context, int index) {
    return Dismissible(
      key: Key(DateTime.now().millisecondsSinceEpoch.toString()),
      background: Container(
        color: Colors.red,
        child: Align(
          alignment: Alignment(-0.9, 0.0),
          child: Icon(
            Icons.delete,
            color: Colors.white,
          ),
        ),
      ),
      direction: DismissDirection.startToEnd,
      child: CheckboxListTile(
        title: Text(_todoList[index]["title"]),
        value: _todoList[index]["ok"],
        secondary: CircleAvatar(
          child: Icon(_todoList[index]["ok"] ? Icons.check : Icons.error),
        ),
        onChanged: (checked) {
          setState(() {
            _todoList[index]["ok"] = checked;
            _saveData();
          });
        },
      ),
      onDismissed: (direction) {
        //Map.from copia/gera um novo mapa do item que acabamos de deletar
        _lastRemoved = Map.from(_todoList[index]);
        _lastRemovePos = index;
        setState(() {
          _todoList.removeAt(index);
        });
        _saveData();

        final snack = SnackBar(
          content: Text('Tarefa \"${_lastRemoved["title"]}\" removida!'),
          action: SnackBarAction(
            label: "Desfazer",
            onPressed: (){
              setState(() {
                _todoList.insert(_lastRemovePos, _lastRemoved);
              });
              _saveData();
            },
          ),
          duration: Duration(seconds: 3),
        );

        Scaffold.of(context).removeCurrentSnackBar();
        Scaffold.of(context).showSnackBar(snack);
      },
    );
  }
}
