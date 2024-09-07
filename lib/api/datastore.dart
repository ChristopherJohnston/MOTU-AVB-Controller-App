import 'package:motu_control/api/channel_state.dart';
import 'package:motu_control/utils/db_slider_utils.dart';

enum ValueType { send, pan, fader, solo, mute }

class Datastore {
  Map<String, dynamic> _data;

  Datastore() : _data = {};

  void updateValue(path, value) {
    _data[path] = value;
  }

  void updateValues(newValues) {
    Map<String, dynamic> combinedMap = {..._data, ...newValues};
    _data = combinedMap;
  }

  ///
  /// Finds the bank number for the given bank name in the ibank or obank
  /// e.g. "obank", "Mix In" -> 24
  ///
  int? _getBankNumber(String bankType, String bankName) {
    // Find all the banks using display order
    List<String> banks =
        _data["ext/${bankType}DisplayOrder"]?.toString().split(":") ?? [];

    // Iterate through the banks to find the one with the given name.
    for (String bank in banks) {
      if (_data["ext/$bankType/$bank/name"] == bankName) {
        return int.parse(bank);
      }
    }
    return null;
  }

  ///
  /// Finds the name of the channel at index
  ///
  String _getChannelName(String bankType, String bankName, int index) {
    int? bank = _getBankNumber(bankType, bankName);
    if (bank == null) {
      return "<Not Found>";
    }

    String name = _data["ext/$bankType/$bank/ch/$index/name"] ?? "";
    if (name.isEmpty) {
      name = _data["ext/$bankType/$bank/ch/$index/defaultName"] ?? "";
    }
    return name;
  }

  ///
  /// Determines the format of he given channel.
  /// mix/chan/6/config/format ->
  ///
  /// 2:0 / 2:1 if stereo
  /// 1:0 if mono
  ///
  List<int> _getChannelFormat(ChannelType type, int index) {
    List<String> format =
        _data["mix/${type.name}/$index/config/format"]?.split(":") ??
            ["1", "0"];

    return [int.tryParse(format[0]) ?? 1, int.tryParse(format[1]) ?? 0];
  }

  ///
  /// Gets a list of channel numbers in the given bank.
  /// Skips the "R" channel of any stereo channel.
  ///
  List<int> getChannelList(String bankType, String bankName) {
    int? bank = _getBankNumber(bankType, bankName);
    if (bank == null) {
      return [];
    }
    int? numCh = _data["ext/$bankType/$bank/userCh"];
    if (numCh == null) {
      return [];
    }
    List<int> channels = [];
    for (int i = 0; i < numCh; i++) {
      List<int> format = _getChannelFormat(ChannelType.chan, i);
      if (format[0] == 1 || (format[0] == 2 && format[1] == 0)) {
        channels.add(i);
      }
    }
    return channels;
  }

  Map<ChannelType, String> inputBankMap = {
    ChannelType.aux: "Mix Aux",
    ChannelType.group: "Mix Group",
    ChannelType.reverb: "Mix Reverb",
    ChannelType.main: "Mix Main",
    ChannelType.monitor: "Mix Monitor"
  };

  Map<ChannelType, String> outputBankMap = {
    ChannelType.chan: "Mix In",
  };

  ///
  /// Gets the name of an input channel at the given index.
  /// e.g. ibank, "Mix Aux", 0 -> "Drum HP"
  ///
  String getInputChannelName(String bank, int index) {
    return _getChannelName("ibank", bank, index);
  }

  ///
  /// Gets the name of an output channel at the given index.
  /// e.g. obank, "Mix In", 0 -> "Main Mic"
  ///
  String getOutputChannelName(String bank, int index) {
    return _getChannelName("obank", bank, index);
  }

  //
  // Mixer Channels
  //

  //  mix/chan/0/matrix/solo
  // mix/chan/0/matrix/mute
  // mix/chan/0/matrix/pan
  // mix/chan/0/matrix/fader

  // mix/aux/1/matrix/mute
  // mix/aux/1/matrix/panner
  // mix/aux/1/matrix/fader

  ///
  /// Builds the path to a mixer channel
  /// e.g chan, 0, pan -> "mix/chan/0/matrix/pan"
  ///
  String getChannelPath(ChannelType type, int index, ValueType channelValue) {
    return "mix/${type.name}/$index/matrix/${channelValue.name}";
  }

  ///
  /// Retrieves a double value for the given channel.
  ///
  double? getChannelDoubleValue(
      ChannelType type, int index, ValueType channelValue) {
    return _data[getChannelPath(type, index, channelValue)];
  }

  ///
  /// Retrieves the fader value for the given channel.
  ///
  double? getChannelFaderValue(ChannelType type, int index) {
    return getChannelDoubleValue(type, index, ValueType.fader);
  }

  ///
  /// Retrieves the pan value for the given channel.
  ///
  double? getChannelPanValue(ChannelType type, int index) {
    return getChannelDoubleValue(type, index, ValueType.pan);
  }

  ///
  /// Retrieves the solo value for the given channel.
  ///
  bool? getChannelSoloValue(ChannelType type, int index) {
    double? val = getChannelDoubleValue(type, index, ValueType.solo);
    if (val != null) {
      return val == 1.0;
    }
    return null;
  }

  ///
  /// Retrieves the mute value for the given channel.
  ///
  bool? getChannelMuteValue(ChannelType type, int index) {
    double? val = getChannelDoubleValue(type, index, ValueType.mute);
    if (val != null) {
      return val == 1.0;
    }
    return null;
  }

  //
  // Output Channels
  //

  // Reverb send
  // mix/chan/0/matrix/reverb/send
  // mix/chan/0/matrix/reverb/pan

  // Aux Send
  // mix/chan/1/matrix/aux/0/send
  // mix/chan/1/matrix/aux/0/pan
  // reverb/0/matrix/aux/1/send

  // Group Send
  // mix/chan/1/matrix/group/0/send
  // mix/chan/1/matrix/group/0/pan
  // mix/group/1/matrix/aux/1/send

  // For future use: levels: http://1248.local/meters?meters=mix/level:ext/input

  ///
  /// Builds the path for a mixer channel output
  /// e.g. mix/chan/0/matrix/aux/0/send
  ///
  String getOutputPath(
    ChannelType inputChannelType,
    int inputChannelIndex,
    ChannelType outputChannelType,
    int outputChannelIndex,
    ValueType channelValue,
  ) {
    return "mix/${inputChannelType.name}/$inputChannelIndex/matrix/${outputChannelType.name}/$outputChannelIndex/${channelValue.name}";
  }

  ///
  /// Retrieves a double value for the given output.
  ///
  double? getOutputDoubleValue(
    ChannelType inputChannelType,
    int inputChannelIndex,
    ChannelType outputChannelType,
    int outputChannelIndex,
    ValueType channelValue,
  ) {
    return _data[getOutputPath(
      inputChannelType,
      inputChannelIndex,
      outputChannelType,
      outputChannelIndex,
      channelValue,
    )];
  }

  ///
  /// Retrieves a pan value for the given output.
  ///
  double? getOutputPanValue(
    ChannelType inputChannelType,
    int inputChannelIndex,
    ChannelType outputChannelType,
    int outputChannelIndex,
  ) {
    return getOutputDoubleValue(
      inputChannelType,
      inputChannelIndex,
      outputChannelType,
      outputChannelIndex,
      ValueType.pan,
    );
  }

  ///
  /// Retrieves a send value for the given output.
  ///
  double? getOutputSendValue(
    ChannelType inputChannelType,
    int inputChannelIndex,
    ChannelType outputChannelType,
    int outputChannelIndex,
  ) {
    return getOutputDoubleValue(
      inputChannelType,
      inputChannelIndex,
      outputChannelType,
      outputChannelIndex,
      ValueType.send,
    );
  }

  ///
  /// Creates a ChannelValues object for the given type/index
  ///
  ChannelValues getChannelValues(ChannelType type, int index) {
    return ChannelValues(
      fader: getChannelFaderValue(type, index) ?? inputForMinusInfdB,
      pan: getChannelPanValue(ChannelType.chan, index) ?? 0.0,
      mute: getChannelMuteValue(type, index) ?? false,
      solo: getChannelSoloValue(type, index) ?? false,
    );
  }

  ///
  /// Creates a ChannelOutputValues object for the given
  /// type/index/outputType/outputIndex
  ///
  /// e.g.
  ///
  /// type/index: chan/0
  /// output type/index: /aux/0
  /// ->
  ///   mix/chan/0/matrix/aux/0/send
  ///   mix/chan/0/matrix/aux/0/pan
  ///
  ChannelOutputValues getChannelOutputValues(
    ChannelType inputType,
    int inputIndex,
    ChannelType outputType,
    int outputIndex,
  ) {
    return ChannelOutputValues(
        send: getOutputSendValue(
              inputType,
              inputIndex,
              outputType,
              outputIndex,
            ) ??
            inputForMinusInfdB,
        pan: getOutputPanValue(
              inputType,
              inputIndex,
              outputType,
              outputIndex,
            ) ??
            0.0);
  }

  ///
  /// Builds a map of the channel output values for sends of the given output type
  ///
  Map<int, ChannelOutputValues> getChannelOutputValuesForSends(
    ChannelType inputType,
    int inputIndex,
    ChannelType outputType,
  ) {
    List<int> sendsList = getChannelList("ibank", inputBankMap[outputType]!);

    Map<int, ChannelOutputValues> sendMap = {};
    for (int outputIndex in sendsList) {
      sendMap[outputIndex] = getChannelOutputValues(
        inputType,
        inputIndex,
        outputType,
        outputIndex,
      );
    }
    return sendMap;
  }

  ///
  /// Builds a map of ChannelOutputValues for each output type
  /// (main, reverb, aux, group)
  ///
  Map<ChannelType, Map<int, ChannelOutputValues>> getChannelOutputValueMap(
    ChannelType type,
    int index,
  ) {
    return {
      ChannelType.main: {
        0: getChannelOutputValues(type, index, ChannelType.main, 0),
      },
      ChannelType.reverb: {
        0: getChannelOutputValues(type, index, ChannelType.reverb, 0),
      },
      ChannelType.aux:
          getChannelOutputValuesForSends(type, index, ChannelType.aux),
      ChannelType.group:
          getChannelOutputValuesForSends(type, index, ChannelType.group),
    };
  }

  ///
  /// Creates a channelState object for the mixer channel of type/index
  ///
  ChannelState getMixerChannelState(ChannelType type, int index) {
    return ChannelState(
        index: index,
        type: ChannelType.chan,
        name: getOutputChannelName(outputBankMap[type]!, index),
        channelValues: getChannelValues(type, index),
        outputValues: getChannelOutputValueMap(type, index),
        format: _getChannelFormat(type, index));
  }

  ///
  /// Creates a ChannelState object for the output channel of type/index
  ///
  ChannelState getOutputChannelState(ChannelType type, int index) {
    return ChannelState(
      index: index,
      type: type,
      name: getInputChannelName(inputBankMap[type]!, index),
      channelValues: getChannelValues(type, index),
      outputValues: getChannelOutputValueMap(type, index),
      format: _getChannelFormat(type, index),
    );
  }

  ///
  /// Builds a Map of device preset indices and names.
  ///
  Map<int, String> getDevicePresets() {
    String presetsStr = _data["ext/presets/device"];
    List<String> presets = presetsStr.split(":");
    Map<int, String> presetsMap = {};
    for (int i = 0; i < presets.length; i += 2) {
      presetsMap[int.parse(presets[i])!] = presets[i + 1];
    }
    return presetsMap;
  }
}
