import 'package:flutter/material.dart';
import 'package:motu_control/api/motu.dart';

// Theme

final ThemeData kMainTheme = ThemeData(
  primarySwatch: Colors.red,
  brightness: Brightness.dark,
  scaffoldBackgroundColor: const Color(0xFF1F2022),
  inputDecorationTheme: const InputDecorationTheme(
    filled: true,
    fillColor: Color(0xFF1F2022),
  ),
  menuTheme: const MenuThemeData(
    style: MenuStyle(
      backgroundColor: WidgetStatePropertyAll(
        Color(0xFF1F2022),
      ),
    ),
  ),
);

// Fader Colors
const Map<ChannelType, Color> kFaderColors = {
  ChannelType.chan: Color(0xFFFF0000),
  ChannelType.aux: Color.fromARGB(255, 0, 255, 30),
  ChannelType.group: Color.fromARGB(255, 2, 25, 204),
  ChannelType.reverb: Color.fromARGB(255, 204, 250, 0),
  ChannelType.main: Color.fromARGB(255, 142, 0, 158),
  ChannelType.monitor: Color.fromARGB(255, 142, 0, 158),
};
const kFaderActiveTrackColor = Color(0xFFFF0000);
const kFaderInactiveTrackColor = Color(0XFF111111);
final kFaderOverlayColor = Colors.white.withOpacity(.1);
const kActiveFaderTickMarkColor = Colors.white;
const kInactiveFaderTickMarkColor = Colors.grey;

// Mute Button

const kMuteActiveColor = Color(0xFFFF0000);
const kMuteInactiveColor = Color.fromRGBO(147, 147, 147, 1);
const kMuteIcon = Icons.mic_off;

// Solo Button

const kSoloActiveColor = Color.fromARGB(255, 150, 182, 10);
const kSoloInactiveColor = Color.fromRGBO(147, 147, 147, 1);
const kSoloIcon = Icons.settings_voice;
