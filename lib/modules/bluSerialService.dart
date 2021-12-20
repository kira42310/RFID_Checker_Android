// import 'package:flutter_blue/flutter_blue.dart';
import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

class BluSerialService
{

  static final BluSerialService _bluSerialService = new BluSerialService._internal();// 

  final FlutterBluetoothSerial blueSerial = FlutterBluetoothSerial.instance;

  BluetoothDevice? connectedDevice;
  BluetoothConnection? connection;
  // BluetoothService? deviceService;
  bool get isConnected => ( connection != null && connection!.isConnected );

  factory BluSerialService()
  {
    return _bluSerialService;
  }

  Future< List<BluetoothDevice> > bluScan() async
  {
    final List<BluetoothDevice> deviceList = <BluetoothDevice>[];
    StreamSubscription<BluetoothDiscoveryResult> streamSubscription = blueSerial.startDiscovery().listen((r) { 
      deviceList.add(r.device);
    });
    await Future.delayed( const Duration( seconds: 1 ));
    streamSubscription.cancel();
    // final List<BluetoothDevice> deviceList = await blueSerial.getBondedDevices();
    print( deviceList.length );
    return deviceList;
  }

  Future< BluetoothConnection? > bluConnect( BluetoothDevice device ) async
  {
    print( 'connect to device' );
    // connectedDevice = device;
    // if( device != null )
    // {
    connection = await BluetoothConnection.toAddress( device.address );
    // }
    print( connection!.isConnected );
    if( connection!.isConnected ) 
    {
      connectedDevice = device;
      return connection!;
    }
    else
    {
      return null;
    }
    // if( connection == null || connection!.isConnected )
    // {
    //   connectedDevice = null;
    // }
  }

  void testSendCmd() async
  {
    print( connection?.isConnected );
    // connection!.output.add( Uint8List.fromList( [0x40, 0x02, 0x02, 0x44 ] ) );
    // await connection!.output.allSent;
    connection!.input!.listen((Uint8List data) { print(data);});
    print( '-- end test --' );
  }

  Future bluDisconnect() async
  {
    print( 'disconnect from device' );
    if( isConnected )
    {
      await connection!.close();
      connectedDevice = null;
    }
    print( isConnected );
  }

  BluSerialService._internal();

}

final bluSerialService = BluSerialService();