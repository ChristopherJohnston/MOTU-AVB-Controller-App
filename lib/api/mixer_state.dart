import 'package:motu_control/api/channel_state.dart';
import 'package:motu_control/api/datastore.dart';

///
/// Represents the state of the mixer from the datastore.
///
class MixerState {
  // Indexes for inputs, groups and auxes
  final List<int> allInputsList;
  final List<int> allGroupsList;
  final List<int> allAuxesList;

  // Inputs for aux, group, reverb
  final Map<ChannelType, Map<ChannelType, Map<int, List<int>>>> sendInputList;

  // Channel states for inputs
  final Map<int, ChannelState> allInputChannelStates;
  final Map<ChannelType, Map<int, ChannelState>> outputStates;

  // Presets
  final Map<int, String> devicePresets;

  MixerState({
    required this.allInputsList,
    required this.allGroupsList,
    required this.allAuxesList,
    required this.sendInputList,
    required this.allInputChannelStates,
    required this.outputStates,
    required this.devicePresets,
  });

  static MixerState fromDatastore({
    required Datastore datastore,
    required Map<ChannelType, Map<int, List<int>>> auxInputList,
    required Map<int, List<int>> groupInputList,
    required List<int> groupList,
    required List<int> auxList,
  }) {
    List<int> allInputsList = datastore.getChannelList("obank", "Mix In");

    // State for all mixer inputs
    final Map<int, ChannelState> allInputChannelStates = {};
    for (int index in allInputsList) {
      allInputChannelStates[index] = datastore.getMixerChannelState(
        ChannelType.chan,
        index,
      );
    }

    // State for all groups
    final Map<int, ChannelState> allGroupChannelStates = {};
    for (int index in groupList) {
      allGroupChannelStates[index] = datastore.getOutputChannelState(
        ChannelType.group,
        index,
      );
    }

    // State for all auxes
    final Map<int, ChannelState> allAuxChannelStates = {};
    for (int index in auxList) {
      allAuxChannelStates[index] = datastore.getOutputChannelState(
        ChannelType.aux,
        index,
      );
    }

    Map<int, List<int>> groupsInputList = {};
    for (int index in groupList) {
      groupsInputList[index] = [];
    }

    Map<ChannelType, Map<ChannelType, Map<int, List<int>>>> sendInputList = {
      ChannelType.aux: auxInputList,
      ChannelType.group: {
        ChannelType.chan: groupInputList,
        ChannelType.group: groupsInputList
      },
      ChannelType.reverb: {
        ChannelType.chan: {0: allInputsList},
        ChannelType.group: {0: groupList}
      },
    };

    return MixerState(
      allInputsList: allInputsList,
      allGroupsList: groupList,
      allAuxesList: auxList,
      sendInputList: sendInputList,
      allInputChannelStates: allInputChannelStates,
      outputStates: {
        ChannelType.aux: allAuxChannelStates,
        ChannelType.group: allGroupChannelStates,
        ChannelType.main: {
          0: datastore.getOutputChannelState(ChannelType.main, 0)
        },
        ChannelType.monitor: {
          0: datastore.getOutputChannelState(ChannelType.monitor, 0)
        },
        ChannelType.reverb: {
          0: datastore.getOutputChannelState(ChannelType.reverb, 0)
        },
      },
      devicePresets: datastore.getDevicePresets(),
    );
  }
}
