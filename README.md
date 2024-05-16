# BTSnoop Parser

Easy to use BTSnoop log file parser in Dart. 

## Features

This library will parse all the packets and return a list of raw data.

## Usage

```dart
import 'package:btsnoop_parser/btsnoop_parser.dart';

void main() async {
  var logs = await BTSnoopLogParser.parseFile("example/btsnoop_hci.log");
  print(logs.btSnoopFileStruct);
  print(logs.btSnoopFileStruct.packetRecords.packetList[124].packetData);
}
```
