import 'dart:convert';
import 'dart:async';
import 'dart:math' show Random, pow;
import 'package:http/http.dart' as http;
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
      printTime: true // Should each log print contain a timestamp
      ),
);

class ApiPolling {
  String apiBaseUrl;
  bool _isRequestInProgress = false;
  Timer? _timer;

  // Client ID is a randomly generated integer between 0 and 2^32-1
  final int clientId = Random().nextInt(pow(2, 32).toInt() - 1);
  final _controller = StreamController<Map<String, dynamic>>();
  Stream<Map<String, dynamic>> get stream => _controller.stream;

  String apiETag = "";
  Map<String, dynamic> datastore = {};

  ApiPolling(this.apiBaseUrl) {
    // Fetch data in a continuous loop.
    resetTimer();
  }

  void resetTimer() {
    _timer?.cancel();
    _timer = Timer(const Duration(seconds: 1), () {
      fetchData();
    });
  }

  void stopPolling() {
    _timer?.cancel();
    _timer = null;
  }

  void _updateDatastore(Map<String, dynamic> newValues) {
    // Merge incoming updates into datastore overwriting existing matching keys
    Map<String, dynamic> combinedMap = {...datastore, ...newValues};
    datastore = combinedMap;
    // Push the updated datastore
    _controller.sink.add(combinedMap);
  }

  void fetchData() async {
    if (_isRequestInProgress) return; // Prevent overlapping requests
    _isRequestInProgress = true;

    try {
      // Long polling request to the Motu AVB Datastore API
      var url = Uri.parse("$apiBaseUrl?client=$clientId");

      Map<String, String> headers = {};

      // Send the eTag in the If-None-Match header if we know it
      // This will ensure that the server starts a long-polling request.
      if (apiETag != "") {
        headers = {
          'If-None-Match': apiETag,
        };
      }

      http.Response response = await http.get(
        url,
        headers: headers,
      );

      // Update stored ETag that later will be sent to the API for updates check
      apiETag = response.headers['etag'] ?? apiETag;

      logger.i(
        "ApiPolling: Response Status: ${response.statusCode}. ETag: $apiETag",
      );

      // 304 means no updates since last check
      // 200 means there's data, so update the local store.
      if (response.statusCode == 200) {
        try {
          _updateDatastore(jsonDecode(response.body));
        } catch (e) {
          logger.e("Error decoding JSON", e);
        }
      } else if (response.statusCode == 304) {
        logger.d("No new updates from the server.");
      }
    } catch (error, stacktrace) {
      logger.e("Error fetching data", error, stacktrace);
    } finally {
      _isRequestInProgress = false;
      resetTimer();
    }
  }

  Uri getUri(String apiEndpoint) {
    return Uri.parse('$apiBaseUrl/$apiEndpoint?client=$clientId');
  }

  void _setValue(String apiEndpoint, dynamic value) async {
    try {
      await http.patch(
        getUri(apiEndpoint),
        body: {
          'json': '{"value":"$value"}',
        },
      );

      // The update will not be sent through the api since we are the same
      // client. Update datastore with the value we just pushed.
      _updateDatastore({apiEndpoint: value});
    } catch (error, stacktrace) {
      logger.e("Error setting value", error, stacktrace);
    }
  }

  void setString(String apiEndpoint, String value) async {
    _setValue(apiEndpoint, value);
  }

  void setInt(String apiEndpoint, int value) async {
    _setValue(apiEndpoint, value);
  }

  void setDouble(String apiEndpoint, double value) async {
    _setValue(apiEndpoint, value);
  }

  void toggleBoolean(String apiEndpoint, double currentValue) async {
    double newValue = (currentValue == 0.0) ? 1.0 : 0.0;
    _setValue(apiEndpoint, newValue);
  }

  String getChannelName(String bankType, String bankName, int channel) {
    List<String> banks =
        datastore["ext/${bankType}DisplayOrder"]?.toString().split(":") ?? [];

    for (String bank in banks) {
      if (datastore["ext/$bankType/$bank/name"] == bankName) {
        String name = datastore["ext/$bankType/$bank/ch/$channel/name"] ?? "";
        if (name.isEmpty) {
          name = datastore["ext/$bankType/$bank/ch/$channel/defaultName"] ?? "";
        }
        return name;
      }
    }
    return "<Not Found>";
  }

  String getInputChannelName(String bank, int channel) {
    return getChannelName("ibank", bank, channel);
  }

  String getOutputChannelName(String bank, int channel) {
    return getChannelName("obank", bank, channel);
  }

  String getAuxName(int channel) {
    if (channel % 2 > 0) {
      channel -= 1;
    }
    String auxName = getInputChannelName("Mix Aux", channel);
    return auxName.replaceAll(r" L", "");
  }

  String getGroupName(int channel) {
    return getInputChannelName("Mix Group", channel).replaceAll(r" L", "");
  }

  String getReverbName(int channel) {
    return getInputChannelName("Mix Reverb", channel).replaceAll(r" L", "");
  }

  String getMixerChannelName(int channel) {
    return getOutputChannelName("Mix In", channel).replaceAll(r" L", "");
  }

  void dispose() {
    logger.i("Disposing ApiPolling instance.");
    closeStream();
    stopPolling();
  }

  void closeStream() {
    _controller.close();
  }
}
