/// Enum of all the types of mixer channel
enum ChannelType { chan, group, aux, reverb, main, monitor }

///
/// Represents the mixer values for a given channel
/// e.g. mix/chan/0/matrix/fader
///
class ChannelValues {
  final double fader;
  final double pan;
  final bool mute;
  final bool solo;

  ChannelValues({
    this.fader = 0.0,
    this.pan = 0.0,
    this.solo = false,
    this.mute = false,
  });

  static ChannelValues get empty {
    return ChannelValues();
  }
}

///
/// Represents the output values for a given channel.
/// e.g. mix/chan/0/matrix/aux/0/fader
///
class ChannelOutputValues {
  final double send;
  final double pan;

  ChannelOutputValues({
    this.send = 0.0,
    this.pan = 0.0,
  });

  static ChannelOutputValues get empty {
    return ChannelOutputValues();
  }
}

///
/// Represents the datastore state for a single channel
///
class ChannelState {
  final int index;
  final ChannelType type;
  final String _name;
  List<int> format;

  late final ChannelValues channelValues;
  final Map<ChannelType, Map<int, ChannelOutputValues>> outputValues;

  ChannelState({
    required this.index,
    required this.type,
    required String name,
    required this.channelValues,
    this.format = const [1, 0],
    this.outputValues = const {},
  }) : _name = name;

  ///
  /// The name of the channel. Remove any trailing "L" if it
  /// is a stereo channel.
  ///
  String get name {
    return (isStereo) ? _name.replaceAll(r" L", "") : _name;
  }

  ///
  /// Is the channel stereo. if the channel format is 2:0 or 2:1 then true
  /// Also true if it's an output channel.
  ///
  bool get isStereo {
    return format[0] == 2 ||
        [
          ChannelType.reverb,
          ChannelType.group,
          ChannelType.main,
          ChannelType.monitor
        ].contains(type);
  }
}
