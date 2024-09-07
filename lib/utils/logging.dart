import 'package:logger/logger.dart';

// Create a global logger instance
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
