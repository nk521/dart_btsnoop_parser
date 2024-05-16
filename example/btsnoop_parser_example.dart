import 'package:btsnoop_parser/btsnoop_parser.dart';

void main() async {
  var logs = await BTSnoopLogParser.parseFile("example/btsnoop_hci.log");
  print(logs.btSnoopFileStruct);
  print(logs.btSnoopFileStruct.packetRecords.packetList[124].packetData);
}
