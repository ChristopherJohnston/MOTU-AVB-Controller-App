import 'package:flutter/material.dart';
import 'package:motu_control/components/fader.dart';
import 'package:motu_control/components/icon_toggle_button.dart';
import 'package:motu_control/components/panner.dart';
import 'package:motu_control/utils/constants.dart';
import 'package:motu_control/utils/db_slider_utils.dart';
import 'package:motu_control/api/motu.dart';
import 'package:logger/logger.dart';

final Logger logger = Logger(
  printer: PrettyPrinter(
      // or use SimplePrinter
      methodCount: 2, // number of method calls to be displayed
      errorMethodCount: 8, // number of method calls if stacktrace is provided
      lineLength: 120, // width of the output
      colors: true, // Colorful log messages
      printEmojis: false, // Print an emoji for each log level
      printTime: false // Should each log print contain a timestamp
      ),
);

class Channel extends StatelessWidget {
  final String name;
  final int channelNumber;
  final Datastore snapshotData;
  final ChannelType type;
  final ChannelType outputType;
  final int outputChannel;

  final Function(String, bool) toggleBoolean;
  final Function(String, double) valueChanged;
  final Function(ChannelType, int)? channelClicked;

  const Channel(
    this.name,
    this.channelNumber,
    this.snapshotData,
    this.toggleBoolean,
    this.valueChanged, {
    super.key,
    this.type = ChannelType.chan,
    this.outputType = ChannelType.chan, // input
    this.outputChannel = 0,
    this.channelClicked,
  });

  @override
  Widget build(BuildContext context) {
    bool soloValue = snapshotData.getChannelSoloValue(
          type,
          channelNumber,
        ) ??
        false;
    bool muteValue = snapshotData.getChannelMuteValue(
          type,
          channelNumber,
        ) ??
        false;

    double faderValue = ((outputType == ChannelType.chan)
            ? snapshotData.getChannelFaderValue(
                type,
                channelNumber,
              )
            : snapshotData.getOutputSendValue(
                type,
                channelNumber,
                outputType,
                outputChannel,
              )) ??
        inputForMinusInfdB;

    double panValue = ((outputType == ChannelType.chan)
            ? snapshotData.getChannelPanValue(
                type,
                channelNumber,
              )
            : snapshotData.getOutputPanValue(
                type,
                channelNumber,
                outputType,
                outputChannel,
              )) ??
        0.0;

    List<int> channelConfig = snapshotData.getChannelFormat(
      type,
      channelNumber,
    );

    bool isStereo = (channelConfig[0] == 2 ||
        [
          ChannelType.reverb,
          ChannelType.group,
          ChannelType.main,
          ChannelType.monitor
        ].contains(type));

    Widget header = TextButton(
      onPressed: () {
        if (channelClicked != null) {
          channelClicked!(type, channelNumber);
        }
      },
      child: Text(
        name,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
      ),
    );

    return Column(
      children: [
        header,
        const SizedBox(height: 10),
        Row(children: [
          IconToggleButton(
            label: "",
            icon: kMuteIcon,
            activeColor: kMuteActiveColor,
            inactiveColor: kMuteInactiveColor,
            active: muteValue,
            onPressed: () {
              toggleBoolean(
                snapshotData.getChannelPath(
                  type,
                  channelNumber,
                  ChannelValue.mute,
                ),
                muteValue,
              );
            },
          ),
          IconToggleButton(
            label: "",
            icon: kSoloIcon,
            activeColor: kSoloActiveColor,
            inactiveColor: kSoloInactiveColor,
            active: soloValue,
            onPressed: () {
              toggleBoolean(
                snapshotData.getChannelPath(
                  type,
                  channelNumber,
                  ChannelValue.solo,
                ),
                soloValue,
              );
            },
          ),
        ]),
        Fader(
          sliderHeight: 440,
          value: faderValue,
          type: outputType,
          valueChanged: (value) => {
            valueChanged(
              (outputType == ChannelType.chan)
                  ? snapshotData.getChannelPath(
                      type,
                      channelNumber,
                      ChannelValue.fader,
                    )
                  : snapshotData.getOutputPath(
                      type,
                      channelNumber,
                      outputType,
                      outputChannel,
                      ChannelValue.send,
                    ),
              value,
            )
          },
        ),
        const SizedBox(height: 20),
        !isStereo
            ? Panner(
                min: -1.0,
                max: 1.0,
                value: panValue,
                valueChanged: (value) => {
                  valueChanged(
                    (outputType == ChannelType.chan)
                        ? snapshotData.getChannelPath(
                            type,
                            channelNumber,
                            ChannelValue.pan,
                          )
                        : snapshotData.getOutputPath(
                            type,
                            channelNumber,
                            outputType,
                            outputChannel,
                            ChannelValue.pan,
                          ),
                    value,
                  )
                },
              )
            : const Text("Stereo"),
        // IconToggleButton(
        //   label: "",
        //   icon: Icons.animation,
        //   activeColor: const Color(0xFFFFFFFF),
        //   inactiveColor: const Color(0xFF939393),
        //   active: snapshotData['mix/reverb/$channelNumber/reverb/enable'] == 1.0
        //       ? true
        //       : false,
        //   onPressed: () {
        //     toggleBoolean('mix/reverb/$channelNumber/reverb/enable',
        //         snapshotData['mix/reverb/$channelNumber/reverb/enable'] ?? 0.0);
        //   },
        // )
      ],
    );
  }
}
