import 'dart:convert';
import 'dart:async';
import 'dart:math' show Random, pow;
import 'package:http/http.dart' as http;
import 'package:motu_control/utils/logging.dart';
import 'package:motu_control/api/channel_state.dart';
import 'package:motu_control/api/datastore.dart';

///
/// API for calling the MOTU datastore web service and maintaining a local
/// copy of its state.
/// Uses a Timer to continuously poll the web service, passing an If-None-Match
/// header to ensure that the device holds the request in a long-poll for
/// up to 15 seconds.
///
class MotuDatastoreApi {
  String apiBaseUrl;
  bool _isRequestInProgress = false;
  bool _closed = false;
  Timer? _timer;

  int? _clientId;
  int? get clientId => _clientId;

  final _controller = StreamController<Datastore>();
  Stream<Datastore> get stream => _controller.stream;

  String apiETag = "";
  Datastore datastore = Datastore();

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
    datastore.updateValues(newValues);
    // Push the updated datastore
    _controller.sink.add(datastore);
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

  void _setValue({
    required ChannelType type,
    required int index,
    required ValueType valueType,
    ChannelType? outputChannelType,
    int? outputIndex,
    required dynamic value,
  }) async {
    try {
      String apiEndpoint = (outputChannelType == null)
          ? datastore.getChannelPath(
              type,
              index,
              valueType,
            )
          : datastore.getOutputPath(
              type,
              index,
              outputChannelType,
              outputIndex!,
              valueType,
            );

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

  void setString(
    ChannelType type,
    int index,
    ValueType valueType,
    ChannelType? outputChannelType,
    int? outputIndex,
    String value,
  ) async {
    _setValue(
      type: type,
      index: index,
      valueType: valueType,
      outputChannelType: outputChannelType,
      outputIndex: outputIndex,
      value: value,
    );
  }

  void setInt(
    ChannelType type,
    int index,
    ValueType valueType,
    ChannelType? outputChannelType,
    int? outputIndex,
    int value,
  ) async {
    _setValue(
      type: type,
      index: index,
      valueType: valueType,
      outputChannelType: outputChannelType,
      outputIndex: outputIndex,
      value: value,
    );
  }

  void setDouble(
    ChannelType type,
    int index,
    ValueType valueType,
    ChannelType? outputChannelType,
    int? outputIndex,
    double value,
  ) async {
    _setValue(
      type: type,
      index: index,
      valueType: valueType,
      outputChannelType: outputChannelType,
      outputIndex: outputIndex,
      value: value,
    );
  }

  void toggleBoolean(
    ChannelType type,
    int index,
    ValueType valueType,
    bool currentValue,
  ) async {
    _setValue(
      type: type,
      index: index,
      valueType: valueType,
      value: (currentValue) ? 0.0 : 1.0,
    );
  }
}
