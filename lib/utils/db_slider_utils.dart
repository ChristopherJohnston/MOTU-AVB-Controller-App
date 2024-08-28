import 'dart:math';

const double negativeInfinityDb = double.negativeInfinity;
const double faderMaxdB = 12.0;

// Final variables representing input values for specific dB levels
// The interface maps -∞dB to +12dB in a 0.0 - 4.0 scale, where:

// 10^(-∞/20) = 0.0 = -∞dB
// 10^(-24/20) = 0.063096 = -24dB
// 10^(-12/20) = 0.251189 = -12dB
// 10^(0/20) = 1.0 = 0dB
// 10^(12/20) = 4.0 = +12dB

// Input value for -∞ dB
const double inputForMinusInfdB = 0.0;
// Input value for -24 dB
final double inputForMinus24dB = pow(10, -24 / 20).toDouble();
// Input value for -12 dB
final double inputForMinus12dB = pow(10, -12 / 20).toDouble();
// Input value for 0 dB
const double inputFor0dB = 1.0;
// Input value for +12 dB
final double inputForPlus12dB = pow(10, 12 / 20).toDouble();

/// Helper function to compute log base 10
double log10(num x) => log(x) / ln10;

/// Helper function to convert an input value to a text label
/// showing the value in decibels.
String inputToDbStr(double input) {
  double dBValue = inputToDb(input);
  return dBValue == negativeInfinityDb
      ? "-∞ dB"
      : "${dBValue.toStringAsFixed(2)} dB";
}

/// Convert the input value (0.0 to 4.0) to the corresponding dB value
/// This can be used to display the value in decibels.
double inputToDb(double input) {
  if (input <= inputForMinusInfdB) {
    return double.negativeInfinity; // -∞ dB
  }

  // Calculate the dB value directly from the input
  double dB = 20 * log10(input);

  // Clamp the dB value to the desired range
  if (dB <= -24) {
    return dB; // Input is in the range -∞ to -24 dB
  } else if (dB <= -12) {
    return dB; // Input is in the range -24 to -12 dB
  } else if (dB <= 0) {
    return dB.abs() < 0.01 ? 0.0 : dB; // Correctly handle near-zero dB values
  } else {
    return dB; // Input is in the range 0 to +12 dB
  }
}

/// Convert the input value (0.0 to 4.0) to the slider value (0.0 to 1.0)
/// we want to scale this so the values fall in nice places on the slider
/// -∞dB to -24dB in first quarter
/// -24dB to -12dB in second quarter
/// -12db to 0dB in third quarter
/// 0dB to 12dB in fourth quarter
double inputToSlider(double input) {
  if (input <= inputForMinusInfdB) {
    // -∞dB corresponds to 0% slider
    return 0.0;
  } else if (input <= inputForMinus24dB) {
    // Linear interpolation from input -∞dB to -24dB (0% to 25%)
    return (input / inputForMinus24dB) * 0.25;
  } else if (input <= inputForMinus12dB) {
    // Linear interpolation from input -24dB to -12dB (25% to 50%)
    return 0.25 +
        ((input - inputForMinus24dB) /
                (inputForMinus12dB - inputForMinus24dB)) *
            0.25;
  } else if (input <= inputFor0dB) {
    // Linear interpolation from input -12dB to 0dB (50% to 75%)
    return 0.5 +
        ((input - inputForMinus12dB) / (inputFor0dB - inputForMinus12dB)) *
            0.25;
  } else {
    // Linear interpolation from input 0dB to 12dB (75% to 100%)
    double sliderValue = 0.75 +
        ((input - inputFor0dB) / (inputForPlus12dB - inputFor0dB)) * 0.25;
    return sliderValue > 1.0 ? 1.0 : sliderValue;
  }
}

/// Convert the slider value (0.0 to 1.0) back to the input value (0.0 to 4.0)
double sliderToInput(double slider) {
  if (slider <= 0.0) {
    return 0.0; // 0% slider corresponds to -∞ dB
  } else if (slider <= 0.25) {
    // Linear interpolation from slider 0.0 to 0.25 (input -∞dB to -24dB)
    return slider * (inputForMinus24dB / 0.25);
  } else if (slider <= 0.5) {
    // Linear interpolation from slider 0.25 to 0.5 (input -24dB to -12dB)
    return inputForMinus24dB +
        ((slider - 0.25) * (inputForMinus12dB - inputForMinus24dB) / 0.25);
  } else if (slider <= 0.75) {
    // Linear interpolation from slider 0.5 to 0.75 (input -12dB to 0dB)
    return inputForMinus12dB +
        ((slider - 0.5) * (inputFor0dB - inputForMinus12dB) / 0.25);
  } else {
    // Linear interpolation from slider 0.75 to 1.0 (input 0dB to 12dB)
    return 1.0 + ((slider - 0.75) * (inputForPlus12dB - inputFor0dB) / 0.25);
  }
}
