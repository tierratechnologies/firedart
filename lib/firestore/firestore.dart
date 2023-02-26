import 'package:firedart/auth/firebase_auth.dart';
import 'package:firedart/generated/google/firestore/v1/common.pb.dart';

import 'firestore_gateway.dart';
import 'models.dart';

typedef TransactionHandler<T> = Future<T> Function(
  Transaction tx,
);

class Firestore {
  /* Singleton interface */
  static Firestore? _instance;

  static Firestore initialize(
    String projectId, {
    String? databaseId,
  }) {
    if (_instance != null) {
      throw Exception('Firestore instance was already initialized');
    }
    FirebaseAuth? auth;
    try {
      auth = FirebaseAuth.instance;
    } catch (e) {
      // FirebaseAuth isn't initialized
    }
    _instance = Firestore(projectId, databaseId: databaseId, auth: auth);
    return _instance!;
  }

  static Firestore get instance {
    if (_instance == null) {
      throw Exception(
          "Firestore hasn't been initialized. Please call Firestore.initialize() before using it.");
    }
    return _instance!;
  }

  /* Instance interface */
  final FirestoreGateway _gateway;

  Firestore(
    String projectId, {
    String? databaseId,
    FirebaseAuth? auth,
    FirestoreGateway? gateway,
  })  : _gateway = gateway ??
            FirestoreGateway(
              projectId,
              databaseId: databaseId,
              auth: auth,
            ),
        assert(projectId.isNotEmpty);

  @Deprecated('Not currently supported')
  factory Firestore.useEmulator(
    String projectId, {
    String? databaseId,
    FirebaseAuth? auth,
  }) =>
      Firestore(
        projectId,
        databaseId: databaseId,
        auth: auth,
        gateway: FirestoreGateway(
          projectId,
          databaseId: databaseId,
          auth: auth,
          useEmulator: true,
        ),
      );

  Reference reference(String path) => Reference.create(_gateway, path);

  CollectionReference<Map<String, dynamic>> collection(String path) =>
      CollectionReference(_gateway, path);

  DocumentReference<Map<String, dynamic>> document(String path) =>
      DocumentReference(_gateway, path);

  Future<dynamic> runTransaction(
    TransactionHandler transactionHandler,
  ) async {
    var txn = await _gateway.beginTransaction(
      TransactionOptions(
        readWrite: TransactionOptions_ReadWrite.create(),
      ),
    );

    var output = await transactionHandler(txn);

    return output;
  }
}
