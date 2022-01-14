import 'dart:typed_data';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:future_progress_dialog/future_progress_dialog.dart';
// import 'package:http/http.dart' as http;

import './bluSerialService.dart';
import './fetchPallet.dart';
// import './config.dart';

void main() => runApp( Checkout() );


class Checkout extends StatefulWidget
{
  @override
  State createState() => _Checkout();
}

class _Checkout extends State<Checkout> 
{
  Timer? _debounce;

  bool isConnectToDevice = false;
  late BluetoothConnection connectionInstanse;
  BluetoothDevice? bluetoothCurrentDevice;
  // final List<BluetoothDevice> deviceList = <BluetoothDevice>[];

  final rfidTxtctl = TextEditingController();
  final productNameTxtctl = TextEditingController();
  final productCQuantityTxtctl = TextEditingController();
  final exportQuantityTxtctl = TextEditingController();
  var pallet;

  static const numpad = ['7', '8', '9', '4', '5', '6', '1', '2', '3', '0', '<', 'Clear'];
  
  static const List<String> listProduct = [
    'test1',
    'test2',
    'test3',
    'test4',
  ];

  static const List<String> listState = [
    'store',
    'out',
    'transfer',
  ];

  bool eModeSwitch = false;
  late String productNameEMode = 'test1';
  // late String productNameEMode;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: ( eModeSwitch ) ? Text( 'Checkout - Edit mode' ) : Text( 'Checkout' ),
          backgroundColor: ( eModeSwitch ) ? Colors.red : Colors.blue,
          actions: <Widget>[
            Padding(
              padding: EdgeInsets.only( right: 10.0 ),
              child: IconButton(
                onPressed: () => showDialog(
                  context: context, 
                  builder: ( BuildContext context ) => AlertDialog(
                    title: Text( 'Edit mode switch' ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop( context, 'Cancel' ), 
                        child: Text( 'Cancel' ),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            eModeSwitch = !eModeSwitch;
                          });
                          Navigator.pop( context, 'Ok' );
                        }, 
                        child: Text( 'Ok' ),
                      )
                    ],
                  )
                ),
                icon: Icon( Icons.mode ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only( right: 10.0 ),
              child: IconButton(
                // onPressed: () => showDialog( context: context, builder: ( BuildContext context ) => bluetoothDialog() ),
                onPressed: () => bluetoothDialog( context ),
                icon: Icon( Icons.bluetooth ),
              ),
            )
          ],
        ),
        body: ListView(
          children: <Widget>[
            textboxUI(),
            numpadUI(),
            acceptUI( context ),
          ],
        ),
    );
  }

  @override
  void initState()
  {
    super.initState();
    rfidTxtctl.addListener( onRFIDChange );
    // WidgetsBinding.instance!.addPostFrameCallback((_) {
    //   showDialog(
    //     context: context, 
    //     builder: ( BuildContext context ) => bluetoothDialog() ); 
    // });
  }

  @override
  void dispose()
  {
    _debounce?.cancel();
    rfidTxtctl.dispose();
    super.dispose();
  }

  Widget textboxUI() => Container(
    padding: EdgeInsets.all(10),
    child: Column(
      children: <Widget>[
        TextField(
          controller: rfidTxtctl,
          textAlign: TextAlign.right,
          decoration: InputDecoration(
            border: UnderlineInputBorder(),
            labelText: 'RFID',
            enabled: false,
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Expanded(
              flex: 14,
              // child: ( eModeSwitch ) ? productSelectorEMode() : TextField(
              child: TextField(
                controller: productNameTxtctl,
                textAlign: TextAlign.right,
                decoration: InputDecoration(
                  border: UnderlineInputBorder(),
                  labelText: 'ชื่อสินค้า',
                  enabled: false,
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Container()
            ),
            Expanded(
              flex: 5,
              child: TextField(
                controller: productCQuantityTxtctl,
                textAlign: TextAlign.right,
                decoration: InputDecoration(
                  border: UnderlineInputBorder(),
                  labelText: 'จำนวน',
                  enabled: false,
                ),
              ),
            ),
          ]
        ),
        TextField(
          controller: exportQuantityTxtctl,
          textAlign: TextAlign.right,
          decoration: InputDecoration(
            border: UnderlineInputBorder(),
            labelText: 'จำนวนสินค้าออก',
            enabled: false,
          ),
        ),
      ]
    )
  );

  void onRFIDChange() async
  {
    if( rfidTxtctl.text == '' ) return;
    if( _debounce?.isActive ?? false ) _debounce!.cancel();
    _debounce = Timer( const Duration( seconds: 1 ), () async
    {
      // pallet = await fetchPallet( rfidTxtctl.text );
      pallet = await showDialog(
        context: context, 
        builder: ( BuildContext context ) => 
          FutureProgressDialog( fetchPallet( rfidTxtctl.text ) )
      );
      // productNameTxtctl.text = listProduct[ pallet!.lotID - 1 ];
      productNameTxtctl.text = pallet!.name;
      productCQuantityTxtctl.text = pallet!.quantity.toString();
    });
  }

  Widget productSelectorEMode() => DropdownButton<String>(
    value: productNameEMode,
    icon: const Icon( Icons.arrow_downward ),
    elevation: 16,
    isExpanded: true,
    itemHeight: 50,
    style: const TextStyle( color: Colors.deepPurple ),
    underline: Container(
      height: 2,
      color: Colors.deepPurpleAccent,
    ),
    onChanged: ( String? newValue ) {
      setState(() {
        productNameEMode = newValue!;
      });
    },
    items: 
      // <String>[ 
      // 'test1', 
      // 'test2',
      // 'test3',
      // 'test4',
      // ]
      listProduct.map<DropdownMenuItem<String>>(( String value ) {
      return DropdownMenuItem<String>(
        value: value,
        child: Text( value ),
      );
    }).toList(),
  );
  

  Widget numpadUI() => GridView.count(
    primary: false,
    padding: const EdgeInsets.all(20),
    crossAxisSpacing: 10,
    mainAxisSpacing: 10,
    childAspectRatio: 1.5,
    shrinkWrap: true,
    physics: NeverScrollableScrollPhysics(),
    addAutomaticKeepAlives: false,
    crossAxisCount: 3,
    children: [
      for( var i in numpad ) createNumpadBTN(i),
    ],
  );

  Widget createNumpadBTN( String txt ) => ElevatedButton(
    style: ElevatedButton.styleFrom(
      // primary: (txt != '<') ? Colors.blue : Colors.red,
      primary: (txt == '<') ? Colors.orange : ( txt == 'Clear' ) ? Colors.red : Colors.blue,
    ),
    onPressed: () => numpadPressed(txt), 
    child: Text(txt)
  );

  void numpadPressed( String txt )
  {
    if( txt == 'Clear' )
      exportQuantityTxtctl.text = '';
    else if( txt != '<' ) 
      exportQuantityTxtctl.text += txt;
    else if( exportQuantityTxtctl.text.length > 0 )
      exportQuantityTxtctl.text = exportQuantityTxtctl.text.substring( 0, exportQuantityTxtctl.text.length - 1 );
  }

  Widget acceptUI( BuildContext context ) => ButtonBar(
    alignment: MainAxisAlignment.spaceEvenly,
    children: [
      SizedBox(
        width: 150,
        height: 50,
        child: acceptBTN( context ),
      ),
      // SizedBox(
      //   width: 150,
      //   height: 50,
      //   child: ElevatedButton(
      //     style: ElevatedButton.styleFrom(
      //       primary: Colors.red,
      //     ),
      //     onPressed: () => exportQuantityTxtctl.text = '',
      //     child: Text( 'Clear' )
      //   )
      // ),
    ],
  );

  Future<Widget?> bluetoothDialog( BuildContext context ) async => await showDialog(
    context: context,
    builder: ( BuildContext context ) {
      final List<BluetoothDevice> deviceList = <BluetoothDevice>[];
      if( bluetoothCurrentDevice != null ) deviceList.add( bluetoothCurrentDevice! );
      return StatefulBuilder(
        builder: ( BuildContext context, setState ) {
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: EdgeInsets.all(30),
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    color: Colors.white,
                  ),
                  padding: EdgeInsets.all(20),
                  child: Column(
                    children: <Widget>[
                      Text( 'Bluetooth Device' ),
                      Container(
                        padding: EdgeInsets.fromLTRB( 0, 10, 0, 10),
                        child: ElevatedButton(
                          onPressed: () async {
                            deviceList.clear();
                            // deviceList.addAll( await bluSerialService.bluScan() );
                            if( bluetoothCurrentDevice != null ) deviceList.add( bluetoothCurrentDevice! );
                            deviceList.addAll( await showDialog(
                              context: context, 
                              builder: ( BuildContext context ) =>
                                FutureProgressDialog( bluSerialService.bluScan(), message: Text( 'Scanning' ) )
                            ));
                            setState(() {});
                          },
                          child: Text('Scan'),
                        )
                      ),
                      Expanded(
                        child: ( deviceList.length > 0 ) ? listViewUI( deviceList ) : const Text( 'No devices found' ) ,
                      ),
                      Container(
                        padding: EdgeInsets.only( top: 10 ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: <Widget>[ 
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                primary: Colors.red,
                              ),
                              onPressed: () async {
                                // bluSerialService.bluDisconnect();
                                await showDialog(
                                  context: context, 
                                  builder: ( BuildContext context ) =>
                                    FutureProgressDialog( bluSerialService.bluDisconnect(), message: Text( 'Disconnecting' ))
                                );
                                bluetoothCurrentDevice = null;
                                deviceList.clear();
                                setState(() {});
                              },
                              child: Text('Disconnect'),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                primary: Colors.blueGrey,
                              ),
                              onPressed: () async {
                                Navigator.pop( context );
                              },
                              child: Text( 'ปิด' ),
                            ),
                          ],
                        )
                      ),
                    ],
                  ),
                )
              ],
            ),
          );
        }
      );
    },
  );
  // Widget bluetoothDialog() => Dialog(
  //   backgroundColor: Colors.transparent,
  //   insetPadding: EdgeInsets.all(30),
  //   child: Stack(
  //     alignment: Alignment.center,
  //     children: <Widget>[
  //       Container(
  //         width: double.infinity,
  //         height: double.infinity,
  //         decoration: BoxDecoration(
  //           borderRadius: BorderRadius.circular(15),
  //           color: Colors.white,
  //         ),
  //         padding: EdgeInsets.all(20),
  //         child: Column(
  //           children: <Widget>[
  //             Text( 'Bluetooth Device' ),
  //             Container(
  //               padding: EdgeInsets.fromLTRB( 0, 10, 0, 10),
  //               child: ElevatedButton(
  //                 onPressed: () async {
  //                   deviceList.clear();
  //                   deviceList.addAll( await bluSerialService.bluScan() );
  //                   setState(() {});
  //                 },
  //                 child: Text('Scan'),
  //               )
  //             ),
  //             Expanded(
  //               child: ( deviceList.length > 0 ) ? listViewUI() : const Text( 'No devices found' ) ,
  //             ),
  //             Container(
  //               padding: EdgeInsets.only( top: 10 ),
  //               child: ElevatedButton(
  //                 style: ElevatedButton.styleFrom(
  //                   primary: Colors.red,
  //                 ),
  //                 onPressed: () {},
  //                 child: Text('Disconnect'),
  //               )
  //             ),
  //           ],
  //         ),
  //       )
  //     ],
  //   ),
  // );

  Widget listViewUI( List<BluetoothDevice> deviceList ) => ListView.separated(
    padding: EdgeInsets.all( 10 ),
    itemCount: deviceList.length,
    itemBuilder: ( BuildContext context, int index ){
      return Container(
        height: 35,
        // color: Colors.grey,
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text( deviceList[ index ].name.toString() ),
                  Text( deviceList[ index ].address.toString() )
                ],
              ),
            ),
            ElevatedButton(
              onPressed: ( bluetoothCurrentDevice != null) ? null : () async
              { 
                // var _connection = await bluSerialService.bluConnect( deviceList[ index ] );
                var _connection = await showDialog( 
                  context: context, 
                  builder: ( BuildContext context ) => 
                    FutureProgressDialog( bluSerialService.bluConnect( deviceList[ index ] ), message: Text( 'Connecting...' ) )
                );
                // if( _connection != null ) connectionInstanse = _connection;
                if( _connection != null ) 
                {
                  connectionInstanse = _connection;
                  bluetoothCurrentDevice = deviceList[ index ];
                  startListenRFID();
                  Navigator.pop( context );
                }
                else print( 'Cannot connect to device!!!' );
                // print( connectionInstanse );
              },
              child: const Text( 'connect' )
            )
          ],
        ),
      );
    },
    separatorBuilder: ( BuildContext context, int index ) => const Divider(),
  );

  void startListenRFID()
  {
    connectionInstanse.input!.listen(( Uint8List data ) 
    { 
      if( data[0] == 240 && data.length > 26 )
      {
        String result = '';
        // 15 - 26
        Iterable<int> a = data.getRange( 15, 27 );
        for( int i in a )
        {
          result += i.toRadixString(16).padLeft( 2, '0' ).toUpperCase(); 
        }
        print( result );
        rfidTxtctl.text = result;
      }
    });
  }

  Widget acceptBTN( BuildContext context ) => ElevatedButton(
    style: ElevatedButton.styleFrom(
      primary: Colors.green,
    ),
    child: Text( 'ส่งข้อมูล' ),
    onPressed: () => showDialog(
      context: context, 
      builder: ( BuildContext context ) => AlertDialog(
        title: Text('test'),
        content: Text('test'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop( context, 'Cancel' ), 
            child: Text('Cancel')
          ),
          TextButton(
            onPressed: () async {
              if( pallet != null )
              {
                // final res = updatePallet( pallet!.id.toString(), exportQuantityTxtctl.text );
                final res = await showDialog(
                  context: context, 
                  builder: ( BuildContext context ) =>
                    FutureProgressDialog( updatePallet( pallet!.id.toString(), exportQuantityTxtctl.text ) )
                );
                rfidTxtctl.text = '';
                productNameTxtctl.text = '';
                productCQuantityTxtctl.text = '';
                exportQuantityTxtctl.text = '';
                pallet = null;
                print( res );
                Navigator.pop( context, 'OK' );
              }
              else
              {
                print( 'pls scan again' );
              }
            }, 
            child: Text('OK')
          ),
        ],
      )
    )
  );

  Widget acceptBTNEMode( BuildContext context ) => ElevatedButton(
    style: ElevatedButton.styleFrom(
      primary: Colors.green,
    ),
    child: Text( 'ส่งข้อมูล' ),
    onPressed: () => showDialog(
      context: context, 
      builder: ( BuildContext context ) => AlertDialog(
        title: Text('test'),
        content: Text('test'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop( context, 'Cancel' ), 
            child: Text('Cancel')
          ),
          TextButton(
            onPressed: () {
              if( pallet != null )
              {
                final res = editPallet( pallet!.id.toString(), exportQuantityTxtctl.text, /*pallet!.locID.toString(),*/ pallet!.lotID.toString(), pallet!.state );
                // rfidTxtctl.text = '';
                // productNameTxtctl.text = '';
                // productCQuantityTxtctl.text = '';
                // exportQuantityTxtctl.text = '';
                pallet = null;
                print( res );
                Navigator.pop( context, 'OK' );
              }
              else
              {
                print( 'pls scan again' );
              }
            }, 
            child: Text('OK')
          ),
        ],
      )
    )
  );

}