import 'dart:typed_data';

Uint8List header =
    Uint8List.fromList([0x62, 0x74, 0x73, 0x6E, 0x6F, 0x6F, 0x70, 0x00]);

enum LinkType {
  formatInvalid(0),
  formatHci(1001),
  formatUart(1002),
  formatBcsp(1003),
  format3wire(1004),
  formatMonitor(2001),
  formatSimulator(2002);
  
  const LinkType(this.value);
  final num value;
}
