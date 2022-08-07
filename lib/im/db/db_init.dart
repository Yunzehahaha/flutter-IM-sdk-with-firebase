import 'dart:async';
import 'dart:developer';
import 'package:im_sdk/im/im_client.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseInit {
  final String _createConversationSql =
      '''CREATE TABLE `Conversation` (`senderId` TEXT PRIMARY KEY,
                             `type` TEXT not null, `sentTime` INTEGER not null,`user` TEXT not null, 
                             `unreadCount` INTEGER DEFAULT 0, `isTop` INTEGER not null, `lastMessage` TEXT not null, `notify` INTEGER DEFAULT 1,
                             `atCount` INTEGER DEFAULT 0);''';
  final String _createMessageContentSql =
      '''CREATE TABLE `MessageContent` (`messageId` INTEGER PRIMARY KEY AUTOINCREMENT,
                             `type` TEXT not null, `conversationType` TEXT not null, `receiverId` TEXT not null,
                             `senderId` TEXT not null, `user` TEXT not null, `targetId` TEXT not null,
                             `messageUid` INTEGER not null, `content` TEXT not null,
                             `sentTime` INTEGER not null, `status` TEXT not null,
                             `imageUrl` TEXT, `thumb` TEXT, `audioUrl` TEXT, 
                             `duration` INTEGER, `extra` TEXT);''';

  final String _crateConversationIndex =
      'CREATE INDEX `index_Conversation_sentTime` ON `Conversation` (`sentTime`)';

  final String _createMessageContentIndex =
      'CREATE INDEX `index_MessageContent_sentTime_messageUId` ON `MessageContent` (`sentTime`, `messageUId`)';

  static const DB_NAME = "im-sdk.db";

  static const DB_SUB_DIR = "im";

  Database? _db = null;

  static final DatabaseInit _instance = DatabaseInit._internal();

  factory DatabaseInit() => _instance;

  Future<Database> get db async {
    if (_db != null && _db!.isOpen) {
      return _db!;
    }
    _db = await initDb();
    return _db!;
  }

  DatabaseInit._internal();

  Future<Database> initDb() async {
    var databasesPath = await getDatabasesPath();
    String path =
        join(databasesPath, DB_SUB_DIR, IMClient.currentUser.id, DB_NAME);
    log('db_path = $path');
    var ourDb = await openDatabase(path,
        version: 1, onCreate: _onCreate, onUpgrade: _onUpgrade);
    return ourDb;
  }

  void _onCreate(Database db, int version) async {
    await db.execute(_createConversationSql);
    log("Table [Conversation] is created");
    await db.execute(_createMessageContentSql);
    log("Table [MessageContent] is created");
    await db.execute(_crateConversationIndex);
    log("Conversation index is created");
    await db.execute(_createMessageContentIndex);
    log("MessageContent index is created");
  }

  void _onUpgrade(Database db, int oldVersion, int newVersion) async {
    log("_onUpgrade oldVersion = $oldVersion, newVersion = $newVersion");
    // if (oldVersion == 1) {
    //   _dbUpgradeV2(db);
    // }
  }

  // void _dbUpgradeV2(Database db) async {
  //   await db.execute("alter table Conversation add atCount INTEGER DEFAULT 0 ");
  // }

  void closeByLogout() async {
    log("closeByLogout");
    await _db!.close();
  }
}
