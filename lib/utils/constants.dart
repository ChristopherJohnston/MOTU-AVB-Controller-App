import 'package:flutter/material.dart';
import 'package:motu_control/api/channel_state.dart';

//
// Main Theme
//

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

//
// Mixer Screen
//

const IconData kMixerIcon = Icons.settings_input_component;
const IconData kInputIcon = Icons.mic;
const IconData kMainIcon = Icons.speaker;
const IconData kReverbIcon = Icons.double_arrow;
const IconData kGroupIcon = Icons.group;
const IconData kAuxIcon = Icons.headphones;

//
// Fader Colors
//

const TextStyle kThumbTextStyle = TextStyle(
  fontSize: 10,
  fontWeight: FontWeight.w700,
  color: Colors.black,
);

class FaderThumbStyle {
  final double thumbRadius;
  final double strokeWidth;
  final Color color;
  final TextStyle thumbTextStyle;

  FaderThumbStyle({
    this.thumbRadius = 15,
    this.color = Colors.white,
    this.strokeWidth = 3,
    this.thumbTextStyle = kThumbTextStyle,
  });
}

const kFaderActiveTrackColor = Color(0xFFFF0000);
const kFaderActiveTickMarkColor = Colors.white;

const kFaderInactiveTrackColor = Color(0XFF111111);
const kFaderInactiveTickMarkColor = Colors.grey;
final kFaderOverlayColor = Colors.white.withOpacity(.1);

const kFaderValueTextStyle = TextStyle(
  fontSize: 12,
  fontWeight: FontWeight.w600,
  color: Colors.white,
);

final FaderThumbStyle kDefaultFaderThumbStyle = FaderThumbStyle();

///
/// Styling information for Faders
///
class FaderStyle {
  final double sliderHeight;
  final Color activeTrackColor;
  final Color activeTickMarkColor;
  final Color inactiveTrackColor;
  final Color inactiveTickMarkColor;
  late final Color overlayColor;
  final TextStyle valueTextStyle;
  final double trackHeight;
  late final FaderThumbStyle thumbStyle;
  final double tickMarkRadius;
  final int divisions;
  final double width;

  FaderStyle({
    this.sliderHeight = 440,
    this.activeTrackColor = kFaderActiveTrackColor,
    this.activeTickMarkColor = kFaderActiveTickMarkColor,
    this.inactiveTrackColor = kFaderInactiveTrackColor,
    this.inactiveTickMarkColor = kFaderInactiveTickMarkColor,
    Color? overlayColor,
    this.valueTextStyle = kFaderValueTextStyle,
    this.trackHeight = 5,
    FaderThumbStyle? thumbStyle,
    this.tickMarkRadius = 3.0,
    this.divisions = 100,
    this.width = 100,
  }) {
    this.thumbStyle = thumbStyle ?? kDefaultFaderThumbStyle;
    this.overlayColor = overlayColor ?? kFaderOverlayColor;
  }

  ///
  /// Initialise a new FaderStyle with tracks and thumbs
  /// having the given color.
  ///
  static FaderStyle fromColor(Color color) {
    return FaderStyle(
      activeTrackColor: color,
      valueTextStyle: kFaderValueTextStyle.copyWith(
        color: color,
      ),
      thumbStyle: FaderThumbStyle(
        color: color,
      ),
    );
  }
}

final FaderStyle kDefaultFaderStyle = FaderStyle();

//
// Panner
//

final FaderThumbStyle kDefaultPannerThumbStyle = FaderThumbStyle(
  thumbRadius: 8,
  thumbTextStyle: kThumbTextStyle.copyWith(
    fontSize: 6,
  ),
);

///
/// Styling information for Panners (which are essentially
/// just horizontal Faders with 0 at the centre)
///
class PannerStyle extends FaderStyle {
  PannerStyle({
    super.sliderHeight = 36,
    super.activeTrackColor,
    super.activeTickMarkColor,
    super.inactiveTrackColor,
    super.inactiveTickMarkColor,
    Color? overlayColor,
    super.valueTextStyle,
    super.trackHeight,
    FaderThumbStyle? thumbStyle,
    super.tickMarkRadius,
    super.divisions = 24,
    super.width,
  }) : super(thumbStyle: thumbStyle ?? kDefaultPannerThumbStyle);

  ///
  /// Initialise a new PannerStyle with tracks and thumbs
  /// having the given color.
  ///
  static PannerStyle fromColor(Color color) {
    return PannerStyle(
      activeTrackColor: color,
      valueTextStyle: kFaderValueTextStyle.copyWith(
        color: color,
      ),
      thumbStyle: FaderThumbStyle(
        thumbRadius: 8,
        thumbTextStyle: kThumbTextStyle.copyWith(
          fontSize: 8,
        ),
        color: color,
      ),
    );
  }
}

final PannerStyle kDefaultPannerStyle = PannerStyle();

//
// Channel Colors and Syles
//

const Color kChannelColor = Color(0xFF2f78c2);
const Color kAuxColor = Color(0xFF36afad);
const Color kGroupColor = Color(0XFFd9af4f);
const Color kReverbColor = Color(0xFFDD5C5E);
const Color kMainColor = Color(0xFFaf7ec4);
const Color kMonitorColor = Color(0xFFaf7ec4);

final Map<ChannelType, Color> kChannelTypeColors = {
  ChannelType.chan: kChannelColor,
  ChannelType.aux: kAuxColor,
  ChannelType.group: kGroupColor,
  ChannelType.reverb: kReverbColor,
  ChannelType.main: kMainColor,
  ChannelType.monitor: kMonitorColor
};

final Map<ChannelType, FaderStyle> kFaderStyles = {
  ChannelType.chan: FaderStyle.fromColor(kChannelColor),
  ChannelType.aux: FaderStyle.fromColor(kAuxColor),
  ChannelType.group: FaderStyle.fromColor(kGroupColor),
  ChannelType.reverb: FaderStyle.fromColor(kReverbColor),
  ChannelType.main: FaderStyle.fromColor(kMainColor),
  ChannelType.monitor: FaderStyle.fromColor(kMonitorColor),
};

//
// Mute Button
//

const kMuteActiveColor = Color(0xFFFF0000);
const kMuteInactiveColor = Color.fromRGBO(147, 147, 147, 1);
const kMuteIcon = Icons.mic_off;

//
// Solo Button
//

const kSoloActiveColor = Color.fromARGB(255, 150, 182, 10);
const kSoloInactiveColor = Color.fromRGBO(147, 147, 147, 1);
const kSoloIcon = Icons.settings_voice;
