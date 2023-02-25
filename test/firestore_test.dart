import 'dart:convert';

import 'package:firedart/firedart.dart';
import 'package:test/test.dart';

import 'test_config.dart';

Future main() async {
  final tokenStore = VolatileStore();
  final auth = FirebaseAuth(apiKey, tokenStore);
  final firestore = Firestore(projectId, auth: auth);

  group(
    'Firestore',
    () {
      var docRefs = <DocumentReference>[];

      var collectionReference =
          firestore.reference('test') as CollectionReference;

      setUpAll(() async {
        await auth.signIn(email, password);

        // add 3 docs to collection
        await Future.wait([
          collectionReference.document('one').set({'field': 'test_value'}),
          collectionReference.document('two').set({'field': 'test_value'}),
          collectionReference.document('three').set({'field': 42}),
        ]);
      });

      // Used when testing sub-collections
      tearDown(() async {
        if (docRefs.isNotEmpty) {
          await Future.wait(docRefs.map((e) => e.delete()));
          docRefs.clear();
        }
        return;
      });

      tearDownAll(() async {
        var documents = await collectionReference.get();

        docRefs.addAll(
          documents.map((element) => element.reference),
        );

        if (docRefs.isNotEmpty) {
          await Future.wait(docRefs.map((e) => e.delete()));
          docRefs.clear();
        }
        return;
      });

      group(
        'Documents',
        () {
          test('Create reference', () async {
            // Ensure document exists
            var reference = firestore.document('test/reference');
            await reference.set({'field': 'test'});

            var documentReference = firestore.reference('test/types');
            expect(documentReference, isA<DocumentReference>());

            // tidy up
            docRefs.add(reference);
          });
        },
      );

      group(
        'Collections',
        () {
          test('Create reference', () async {
            expect(collectionReference, isA<CollectionReference>());
          });

          test('Get collection', () async {
            var documents = await collectionReference.get();
            expect(documents.isNotEmpty, true);
          });

          test('Limit collection page size', () async {
            var documents = await collectionReference.get(pageSize: 1);
            expect(documents.length, 1);
            expect(documents.hasNextPage, isTrue);
          });

          test('Get next collection page', () async {
            var documents = await collectionReference.get(pageSize: 1);
            var first = documents[0];

            documents = await collectionReference.get(
              pageSize: 1,
              nextPageToken: documents.nextPageToken,
            );

            var second = documents[0];
            expect(first.id, isNot(second.id));
          });
        },
      );

      group(
        'Queries',
        () {
          test('Simple query', () async {
            var query = await collectionReference
                .where(
                  'field',
                  isEqualTo: 'test_value',
                )
                .get();

            expect(query.length, equals(2));
          });

          test('Multiple query parameters', () async {
            var query = await collectionReference
                .where(
                  'field',
                  isEqualTo: 42,
                  isGreaterThan: 41,
                  isLessThan: 43,
                )
                .get();

            expect(query.length, equals(1));
          });
        },
      );

      group(
        'CRUD',
        () {
          test('Add and delete collection document', () async {
            var docReference = await collectionReference.add({'field': 'test'});
            expect(docReference['field'], 'test');

            var document = collectionReference.document(docReference.id);
            expect(await document.exists, true);

            await document.delete();
            expect(await document.exists, false);
          });

          test('Add and delete named document', () async {
            var reference = collectionReference.document('add_remove');
            await reference.set({'field': 'test'});
            expect(await reference.exists, true);

            await reference.delete();
            expect(await reference.exists, false);
          });

          test('Path with leading slash', () async {
            var reference = firestore.document('/test/path');
            await reference.set({'field': 'test'});
            expect(await reference.exists, true);

            await reference.delete();
            expect(await reference.exists, false);
          });

          test('Path with trailing slash', () async {
            var reference = firestore.document('test/path/');
            await reference.set({'field': 'test'});
            expect(await reference.exists, true);

            await reference.delete();
            expect(await reference.exists, false);
          });

          test('Path with leading and trailing slashes', () async {
            var reference = firestore.document('/test/path/');
            await reference.set({'field': 'test'});
            expect(await reference.exists, true);
            await reference.delete();
            expect(await reference.exists, false);
          });

          test('Read data from document', () async {
            var reference = collectionReference.document('one');

            var map = await reference.get();
            expect(map['field'], 'test_value');
          });

          test('Read data from document\'s subcollection', () async {
            var reference = collectionReference.document('one');

            // create subcollection
            var subColRef =
                reference.collection('test_sub_col').document('read_data_sub');

            await subColRef.set({'field': 'test'});

            var map = await subColRef.get();
            expect(map['field'], 'test');

            // for tidy up in tearDown
            docRefs.addAll([reference, subColRef]);
          });

          test('Overwrite document', () async {
            var reference = collectionReference.document('overwrite');
            await reference.set({'field1': 'test1', 'field2': 'test1'});
            await reference.set({'field1': 'test2'});

            var doc = await reference.get();
            expect(doc['field1'], 'test2');
            expect(doc['field2'], null);
          });

          test('Update document', () async {
            var reference = collectionReference.document('update');
            await reference.set({'field1': 'test1', 'field2': 'test1'});
            await reference.update({'field1': 'test2'});

            var doc = await reference.get();
            expect(doc['field1'], 'test2');
            expect(doc['field2'], 'test1');
          });
        },
      );

      group(
        'Stream data',
        () {
          // test('Stream document changes', () async {
          //   var reference = firestore.document('test/subscribe');
          //
          //   // Firestore may send empty events on subscription because we're reusing the
          //   // document path.
          //   expect(reference.stream.where((doc) => doc != null),
          //       emits((document) => document['field'] == 'test'));
          //
          //   await reference.set({'field': 'test'});
          //   await reference.delete();
          // });

          test('Stream collection changes', () async {
            expect(
              collectionReference.stream,
              emits((List<Document> documents) => documents.isNotEmpty),
            );
          });

          test(
            'Stream document changes',
            () {
              var reference = collectionReference.document('three');

              expect(
                reference.stream,
                emits((Document document) => document.id == reference.id),
              );
            },
          );
        },
      );

      group(
        'Field types',
        () {
          test('Document field types', () async {
            var reference = collectionReference.document('types');
            var dateTime = DateTime.now();
            var geoPoint = GeoPoint(38.7223, 9.1393);

            await reference.set({
              'null': null,
              'bool': true,
              'int': 1,
              'double': 0.1,
              'timestamp': dateTime,
              'bytes': utf8.encode('byte array'),
              'string': 'text',
              'reference': reference,
              'coordinates': geoPoint,
              'list': [1, 'text'],
              'map': {'int': 1, 'string': 'text'},
            });
            var doc = await reference.get();

            expect(doc['null'], null);
            expect(doc['bool'], true);
            expect(doc['int'], 1);
            expect(doc['double'], 0.1);
            expect(doc['timestamp'], dateTime);
            expect(doc['bytes'], utf8.encode('byte array'));
            expect(doc['string'], 'text');
            expect(
                doc['reference'],
                allOf(
                  isA<DocumentReference<Map<String, dynamic>>>(),
                  equals(reference),
                  equals(doc.reference),
                ));
            expect(doc['coordinates'], geoPoint);
            expect(doc['list'], [1, 'text']);
            expect(doc['map'], {'int': 1, 'string': 'text'});

            docRefs.add(reference);
          });
        },
      );

      group(
        'Transactions',
        () {
          test(
            'Begin & Commit a txn on a Document Read & Update',
            () {
              // var result = await firestore.beginTransaction(())
            },
          );
        },
      );
    },
  );

  group(
    'Auth mgmt',
    () {
      test('Refresh token when expired', () async {
        tokenStore.expireToken();
        var map = await firestore.collection('test').get();
        expect(auth.isSignedIn, true);
        expect(map, isNot(null));
      });

      // Skipped as causes error in TearDownAll
      // Also is already tested in firestore_auth_test
      test(
        'Sign out on bad refresh token',
        () async {
          tokenStore.setToken('user_id', 'bad_token', 'bad_token', 0);
          try {
            await firestore.collection('test').get();
          } catch (_) {}
          expect(auth.isSignedIn, false);
        },
      );
    },
  );
}
