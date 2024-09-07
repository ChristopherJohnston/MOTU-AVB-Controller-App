import 'package:motu_control/api/channel_state.dart';
import 'dart:convert';

// In Touch console, fader visibility is stored in browser local storage
// at touch-console_faderVisibility

// Channels to show as inputs to each aux.

ChannelType? channelTypeFromString(String? channel) {
  return ChannelType.values.firstWhere(
    (e) => e.toString().split('.').last == channel,
    orElse: () => ChannelType.chan, // Default value if no match is found
  );
}

class InputSettings {
  Map<ChannelType, Map<int, List<int>>> auxInputList;
  Map<int, List<int>> groupInputList;
  List<int> groupList;
  List<int> auxList;
  String? deviceUrl;

  // Constructor
  InputSettings({
    required this.auxInputList,
    required this.groupInputList,
    required this.groupList,
    required this.auxList,
    this.deviceUrl,
  });

  factory InputSettings.defaults() {
    Map<ChannelType, Map<int, List<int>>> auxInputList = {
      ChannelType.chan: {
        0: [0, 1, 2, 3, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22, 23, 35],
        2: [0, 1, 2, 3, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22, 23, 35],
        4: [0, 1, 2, 3, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22, 23, 35],
        6: [0, 1, 2, 3, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22, 23, 35],
        8: [0, 1, 2, 3, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22, 23, 35],
        10: [0, 1, 2, 3, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22, 23, 35],
        12: [0, 1, 2, 3, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22, 23, 35],
      },
      ChannelType.group: {
        0: [0],
        2: [0],
        4: [0],
        6: [0],
        8: [0],
        10: [0],
        12: [0],
      }
    };

    // Channels to show as inputs to each group.
    Map<int, List<int>> groupInputList = {
      0: [24, 25, 26, 27, 28, 29, 30, 31, 32, 34],
      2: [],
      4: [],
    };

    // Active Groups
    List<int> groupList = [0, 2, 4];

    // Active Auxes
    List<int> auxList = [0, 2, 4, 6, 8, 10, 12];
    return InputSettings(
      auxInputList: auxInputList,
      groupInputList: groupInputList,
      groupList: groupList,
      auxList: auxList,
    );
  }

  ///
  /// Create a settings object from the provided json.
  ///
  factory InputSettings.fromJson(Map<String, dynamic> json) {
    String? deviceUrl = json['deviceUrl'];

    Map<ChannelType, Map<int, List<int>>> auxInputList = {};
    if (json['auxInputList'] != null) {
      json['auxInputList'].forEach((key, value) {
        ChannelType? channelType = channelTypeFromString(key);
        if (channelType != null) {
          Map<int, List<int>> channelData = {};
          (value as Map<String, dynamic>).forEach((chanKey, chanValue) {
            channelData[int.parse(chanKey)] = List<int>.from(chanValue);
          });
          auxInputList[channelType] = channelData;
        }
      });
    }

    Map<int, List<int>> groupInputList = {};
    if (json['groupInputList'] != null) {
      (json['groupInputList'] as Map<String, dynamic>).forEach((key, value) {
        groupInputList[int.parse(key)] = List<int>.from(value);
      });
    }

    List<int> groupList = List<int>.from(json['groupList']);
    List<int> auxList = List<int>.from(json['auxList']);

    return InputSettings(
      auxInputList: auxInputList,
      groupInputList: groupInputList,
      groupList: groupList,
      auxList: auxList,
      deviceUrl: deviceUrl,
    );
  }

  factory InputSettings.fromBase64(String base64EncodedString) {
    final json = jsonDecode(utf8.decode(base64Decode(base64EncodedString)));
    return InputSettings.fromJson(json);
  }
}
