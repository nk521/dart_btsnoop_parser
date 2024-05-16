import 'dart:io';
import 'dart:typed_data';

import 'package:btsnoop_parser/btsnoop_parser.dart';

import 'constants.dart' as constants;
import 'utils.dart' as utils;

class BTSnoopFileStruct {
  late BTSnoopHeader header;
  late PacketRecords packetRecords;

  BTSnoopFileStruct(this.header, this.packetRecords);

  static Future<BTSnoopFileStruct> parse(RandomAccessFile stream) async {
    var header = await BTSnoopHeader.parse(stream);
    // print(header.toString());
    var packetRecords = await PacketRecords.parse(stream);

    return BTSnoopFileStruct(header, packetRecords);
  }
}

class BTSnoopHeader {
  late Uint8List idPattern;
  late int version;
  late constants.LinkType dataLinkType;

  BTSnoopHeader(this.idPattern, this.version, this.dataLinkType);

  static Future<BTSnoopHeader> parse(RandomAccessFile stream) async {
    var header = await stream.read(0x08);
    if (!utils.listeq(header, constants.header)) {
      throw Exception("header $header is corrupted ${constants.header}");
    }

    var version = (await stream.read(0x04)).buffer.asByteData().getUint32(0);
    assert(version == 1);

    var dataLink = await stream.read(0x04);
    if (dataLink.buffer.asByteData().getUint32(0) !=
        constants.LinkType.formatUart.value) {
      throw Exception("can only parse type UART");
    }

    return BTSnoopHeader(header, version, constants.LinkType.formatUart);
  }
}

class PacketRecords {
  late List<PacketRecord> packetList;

  PacketRecords(this.packetList);

  static Future<PacketRecords> parse(RandomAccessFile stream) async {
    var packetRecords = <PacketRecord>[];
    int seq = 1;

    while (true) {
      try {
        packetRecords.add(await PacketRecord.parse(stream, seq));
        seq += 1;
      } catch (e) {
        if (e.toString().contains("EOF")) {
          break;
        }
        rethrow;
      }
    }
    return PacketRecords(packetRecords);
  }
}

class PacketRecord {
  late int originalLength;
  late int includedLength;
  late int packetFlags;
  late int cumulativeDrops;
  late int timestampMicroseconds;
  late Uint8List packetData;
  late int seq;

  PacketRecord(
      this.originalLength,
      this.includedLength,
      this.packetFlags,
      this.cumulativeDrops,
      this.timestampMicroseconds,
      this.packetData,
      this.seq);

  // https://github.com/traviswpeters/btsnoop/blob/d7eba8ed4c417da5be4c6d298376c683d9d23636/btsnoop/btsnoop/btsnoop.py#L208
  static Future<PacketRecord> parse(RandomAccessFile stream, int seq) async {
    var packetHeader = await stream.read(4 + 4 + 4 + 4 + 8);
    if (packetHeader.isEmpty || packetHeader.length != 24) {
      throw Exception("EOF reached!");
    }

    var originalLength =
        packetHeader.sublist(0, 4).buffer.asByteData().getUint32(0);
    var includedLength =
        packetHeader.sublist(4, 8).buffer.asByteData().getUint32(0);
    var packetFlags =
        packetHeader.sublist(8, 12).buffer.asByteData().getUint32(0);
    var cumulativeDrops =
        packetHeader.sublist(12, 16).buffer.asByteData().getUint32(0);
    var timestampMicroseconds =
        packetHeader.sublist(16, 24).buffer.asByteData().getInt64(0);

    assert(originalLength == includedLength);

    var packetData = await stream.read(includedLength);
    assert(packetData.length == includedLength);

    return PacketRecord(
      originalLength,
      includedLength,
      packetFlags,
      cumulativeDrops,
      timestampMicroseconds,
      packetData,
      seq,
    );
  }
}

class BTSnoopLogParser {
  late File file;
  late BTSnoopFileStruct btSnoopFileStruct;

  BTSnoopLogParser(this.file, this.btSnoopFileStruct);

  static Future<BTSnoopLogParser> parseFile(String filePath) async {
    var file = File(filePath);
    RandomAccessFile stream = await file.open();
    var btSnoopFileStruct = await BTSnoopFileStruct.parse(stream);

    return BTSnoopLogParser(file, btSnoopFileStruct);
  }
}
