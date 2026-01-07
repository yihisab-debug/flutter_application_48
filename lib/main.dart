import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class User {
  final String name;
  final String image;
  final String? id;

  User({
    required this.name,
    required this.image,
    this.id,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      name: json['name'] ?? '',
      image: json['image'] ?? '',
      id: json['id'], // MockAPI -> String
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'image': image,
    };
  }
}

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mock API Users',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: UserListScreen(),
    );
  }
}

class UserListScreen extends StatefulWidget {
  @override
  _UserListScreenState createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  final String baseUrl =
      'https://6939834cc8d59937aa082275.mockapi.io/project';

  List<User> users = [];
  bool isLoading = false;
  bool isAdding = false;

  final _nameController = TextEditingController();
  final _avatarController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  void showError(String text) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> fetchUsers() async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(Uri.parse(baseUrl));
      if (response.statusCode == 200) {
        users = (json.decode(response.body) as List)
            .map((e) => User.fromJson(e))
            .toList();
        setState(() {});
      }
    } catch (e) {
      showError("Ошибка загрузки $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> addUser() async {
    if (_nameController.text.isEmpty) {
      showError("Имя обязательно");
      return;
    }

    setState(() => isAdding = true);

    try {
      await http.post(
        Uri.parse(baseUrl),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "name": _nameController.text,
          "avatar": _avatarController.text.isEmpty
              ? "https://i.pravatar.cc/150"
              : _avatarController.text,
        }),
      );
      _nameController.clear();
      _avatarController.clear();
      fetchUsers();
    } catch (e) {
      showError("Ошибка добавления");
    } finally {
      setState(() => isAdding = false);
    }
  }

  Future<void> deleteUser(String? id) async {
    if (id == null) return;
    try {
      await http.delete(Uri.parse('$baseUrl/$id'));
      fetchUsers();
    } catch (e) {
      showError("Ошибка удаления");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.indigoAccent,
      appBar: AppBar(title: Text('Пользователи')),
      floatingActionButton: FloatingActionButton(
        onPressed: fetchUsers,
        child: Icon(Icons.refresh),
      ),
      body: Column(
        children: [

          Padding(
            padding: EdgeInsets.all(8),
            child: TextField(
              style: TextStyle(color: Colors.white),
              controller: _nameController,
                decoration: InputDecoration(
                labelText: 'Имя',
                labelStyle: TextStyle(color: Colors.white),
              ),
            ),
          ),

          Padding(
            padding: EdgeInsets.all(8),
            child: TextField(
              style: TextStyle(color: Colors.white),              
              controller: _avatarController,
                decoration: InputDecoration(
                labelText: 'Avatar URL',
                labelStyle: TextStyle(color: Colors.white),
              ),
            ),
          ),
          
          ElevatedButton(
            onPressed: isAdding ? null : addUser,
            child: isAdding
                ? CircularProgressIndicator(color: Colors.white)
                : Text('Добавить'),
          ),
          
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: users.length,
                    itemBuilder: (_, index) {
                      final user = users[index];
                      return Card(
                        color: Colors.white,
                        child: ListTile(

                          leading: CircleAvatar(
                            backgroundImage:
                                NetworkImage(user.image),
                          ),

                          title: Text(user.name),
                          
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    UserDetailScreen(user: user),
                              ),
                            );
                          },

                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [

                              IconButton(
                                icon: Icon(Icons.edit, color: Colors.green),
                                onPressed: () async {
                                  final updated =
                                      await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          EditUserScreen(user: user),
                                    ),
                                  );
                                  if (updated == true) fetchUsers();
                                },
                              ),

                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () =>
                                    deleteUser(user.id),
                              ),

                            ],
                          ),

                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}


class UserDetailScreen extends StatelessWidget {
  final User user;

  UserDetailScreen({required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.indigoAccent,
      appBar: AppBar(title: Text('Профиль')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            CircleAvatar(
              radius: 60,
              backgroundImage: NetworkImage(user.image),
            ),

            SizedBox(height: 20),

            Text(
              user.name,
              style:
                  TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
            ),

          ],
        ),
      ),
    );
  }
}

class EditUserScreen extends StatefulWidget {
  final User user;

  EditUserScreen({required this.user});

  @override
  _EditUserScreenState createState() => _EditUserScreenState();
}

class _EditUserScreenState extends State<EditUserScreen> {
  final String baseUrl =
      'https://6939834cc8d59937aa082275.mockapi.io/project';

  late TextEditingController nameController;
  late TextEditingController imageController;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    nameController =
        TextEditingController(text: widget.user.name);
    imageController =
        TextEditingController(text: widget.user.image);
  }

  Future<void> updateUser() async {
    setState(() => isSaving = true);
    try {
      await http.put(
        Uri.parse('$baseUrl/${widget.user.id}'),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "name": nameController.text,
          "image": imageController.text,
        }),
      );
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Ошибка обновления")),
      );
    } finally {
      setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.indigoAccent,
      appBar: AppBar(title: Text('Редактировать')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [

            TextField(
              style: TextStyle(color: Colors.white),
              controller: nameController,
                decoration: InputDecoration(
                labelText: 'Имя',
                labelStyle: TextStyle(color: Colors.white),
              ),
            ),

            TextField(
              style: TextStyle(color: Colors.white),
              controller: imageController,
                decoration: InputDecoration(
                labelText: 'Avatar URL',
                labelStyle: TextStyle(color: Colors.white),
              ),
            ),

            SizedBox(height: 20),

            ElevatedButton(
              onPressed: isSaving ? null : updateUser,
              child: isSaving
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text('Сохранить'),
            ),

          ],
        ),
      ),
    );
  }
}