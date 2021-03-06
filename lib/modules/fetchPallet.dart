import 'dart:convert';

import 'package:http/http.dart' as http;

import './config.dart';

class Pallet
{
  final int id;
  final String tagID;
  final String pl;
  final String fg;
  final String lot;
  final int quantity;
  final String state;

  Pallet
  ({
    required this.id,
    required this.tagID,
    required this.pl,
    required this.fg,
    required this.lot,
    required this.quantity,
    required this.state
  });

  factory Pallet.fromJson( Map<String, dynamic> json )
  {
    return Pallet(
      id: json[ 'id' ], 
      tagID: json[ 'tagID' ],
      pl: json[ 'pallet_number' ],
      fg: json[ 'fg_code' ],
      lot: json[ 'lot' ],
      quantity: json[ 'quantity' ],
      state: json[ 'state' ]
    );
  }
}

Future<Pallet> fetchPallet( String rfid ) async
{
  final res = await http.post(
    Uri.parse( 'http://'+ dbLocation +'/find' ),
    headers: <String, String>
    {
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: jsonEncode( <String, String>
    {
      'rfid': rfid
    }),
  );

  if( res.statusCode == 200)
  {
    return Pallet.fromJson( jsonDecode( res.body ) );
  }
  else
  {
    throw Exception( 'Failed to fetch data' );
  }
}

Future updatePallet( String tagID, String exportNumber ) async
{
  final res = await http.post(
    Uri.parse( 'http://'+ dbLocation +'/update' ),
    headers: <String, String>
    {
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: jsonEncode( <String, String>
    {
      'palletID': tagID,
      'exportNumber': exportNumber,
    }),
  );
  if( res.statusCode == 200 )
  {
    return res.body;
  }
  else
  {
    throw Exception( 'Failed to fetch data' );
  }
}

Future editPallet( String tagID, String quantity, ) async
{
  final res = await http.post(
    Uri.parse( 'http://'+ dbLocation +'/edit' ),
    headers: <String, String>
    {
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: jsonEncode( <String, String>
    {
      'palletID': tagID,
      "editnumber": quantity,
    }),
  );
  if( res.statusCode == 200 )
  {
    return jsonDecode( res.body );
  }
  else
  {
    throw Exception( 'Failed to fetch data' );
  }
}