import 'dart:convert';

class SendUser {
  final String id;
  final String name;
  final String portraitUri;

  SendUser(this.id, this.name, this.portraitUri);

  SendUser.fromJson(Map data)
      : id = data['id'].toString(),
        name = data['name'].toString(),
        portraitUri = data['portraitUri'].toString();

  SendUser.fromFirebaseUser(Map data)
      : id = data['id'].toString(),
        name = data['nickname'].toString(),
        portraitUri = data['portraitUri'].toString();

  Map toMap() {
    Map map = {};
    map["id"] = id;
    map["name"] = name;
    map["portraitUri"] = portraitUri;
    return map;
  }

  String toJson() {
    Map map = toMap();
    return json.encode(map);
  }

  @override
  String toString() {
    return 'SendUser{id: $id, name: $name, portraitUri: $portraitUri}';
  }
}
