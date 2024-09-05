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

class MotuDatastoreApi {
  String apiBaseUrl;
  bool _isRequestInProgress = false;
  bool _closed = false;
  Timer? _timer;

  int? _clientId;
  int? get clientId => _clientId;

  final _controller = StreamController<Map<String, dynamic>>();
  Stream<Map<String, dynamic>> get stream => _controller.stream;

  String apiETag = "";
  Map<String, dynamic> datastore = {};

  MotuDatastoreApi(this.apiBaseUrl, {int? clientId}) {
    logger.i("ApiPolling: New ApiPolling instance");
    _clientId = clientId ?? getClientId();
    // Fetch data in a continuous loop.
    resetTimer();
  }

  /// Client ID is a randomly generated integer between 0 and 2^32-1
  static int getClientId() {
    int newClientId = Random().nextInt(pow(2, 32).toInt() - 1);
    logger.i("ApiPolling.getClientId: New ClientId: $newClientId");
    return newClientId;
  }

  void resetTimer() {
    _timer?.cancel();

    if (_closed) {
      logger.e("ApiPolling.resetTimer: $clientId: Controller is closed.");
      throw "Controller is closed";
    }

    _timer = Timer(const Duration(seconds: 1), () {
      fetchData();
    });
  }

  void stopPolling() {
    _timer?.cancel();
    _timer = null;
  }

  void closeStream() {
    _controller.close();
    _closed = true;
  }

  void dispose() {
    logger.i("ApiPolling.dispose: Disposing ApiPolling instance.");
    closeStream();
    stopPolling();
  }

  void _updateDatastore(Map<String, dynamic> newValues) {
    // Merge incoming updates into datastore overwriting existing matching keys
    Map<String, dynamic> combinedMap = {...datastore, ...newValues};
    datastore = combinedMap;
    // Push the updated datastore
    _controller.sink.add(combinedMap);
  }

  Uri getUri(String apiEndpoint) {
    return Uri.parse('$apiBaseUrl/$apiEndpoint?client=$clientId');
  }

  void fetchData() async {
    String logPrefix = "ApiPolling.fetchData: $clientId";
    if (_isRequestInProgress) {
      logger.w("$logPrefix: Request is already in progress.");
      return; // Prevent overlapping requests
    }

    _isRequestInProgress = true;
    bool shouldResetTimer = true;

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

      if (_controller.isClosed | _closed) {
        logger.w(
            "$logPrefix: Controller was closed before response was received.");
        shouldResetTimer = false;
        return;
      }

      // Update stored ETag that later will be sent to the API for updates check
      apiETag = response.headers['etag'] ?? apiETag;

      // 304 means no updates since last check
      // 200 means there's data, so update the local store.
      if (response.statusCode == 200) {
        try {
          logger.i(
            "$logPrefix: New Data Received. New ETag: $apiETag",
          );
          _updateDatastore(jsonDecode(response.body));
        } catch (e) {
          logger.e("$logPrefix: Error decoding JSON: '${response.body}'", e);
        }
      } else if (response.statusCode == 304) {
        logger.d(
            "$logPrefix: No new updates from the server. New ETag: $apiETag");
      }
    } catch (error, stacktrace) {
      logger.e("$logPrefix: Error fetching data", error, stacktrace);
    } finally {
      _isRequestInProgress = false;
      if (shouldResetTimer) {
        resetTimer();
      }
    }
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

  int? getBankNumber(String bankType, String bankName) {
    List<String> banks =
        datastore["ext/${bankType}DisplayOrder"]?.toString().split(":") ?? [];

    for (String bank in banks) {
      if (datastore["ext/$bankType/$bank/name"] == bankName) {
        return int.parse(bank);
      }
    }
    return null;
  }

  String getChannelName(String bankType, String bankName, int channel) {
    int? bank = getBankNumber(bankType, bankName);
    if (bank == null) {
      return "<Not Found>";
    }

    String name = datastore["ext/$bankType/$bank/ch/$channel/name"] ?? "";
    if (name.isEmpty) {
      name = datastore["ext/$bankType/$bank/ch/$channel/defaultName"] ?? "";
    }
    return name;
  }

  List<int> getChannelList(String bankType, String bankName) {
    int? bank = getBankNumber(bankType, bankName);
    if (bank == null) {
      return [];
    }
    int? numCh = datastore["ext/$bankType/$bank/userCh"];
    if (numCh == null) {
      return [];
    }
    List<int> channels = [];
    for (int i = 0; i < numCh; i++) {
      // mix/chan/6/config/format -> 2:0 / 2:1 if stereo, 1:0 if mono
      List<String> format =
          datastore["mix/chan/$i/config/format"]?.split(":") ?? ["1", "0"];
      if (format[0] == "1" || (format[0] == "2" && format[1] == "0")) {
        channels.add(i);
      }
    }
    return channels;
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
}
