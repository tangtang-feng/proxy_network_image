import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'proxy_network_image.dart' as image_provider;

/// The dart:io implemenation of [image_provider.ProxyNetworkImage].
class ProxyNetworkImage extends ImageProvider<image_provider.ProxyNetworkImage> implements image_provider.ProxyNetworkImage {
  /// Creates an object that fetches the image at the given URL.
  ///
  /// The arguments [url] and [scale] must not be null.
  const ProxyNetworkImage(this.url, { this.proxy, this.scale = 1.0, this.headers })
      : assert(url != null),
        assert(scale != null);

  @override
  final String url;

  @override
  final String proxy;

  @override
  final double scale;

  @override
  final Map<String, String> headers;

  @override
  Future<ProxyNetworkImage> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<ProxyNetworkImage>(this);
  }

  @override
  ImageStreamCompleter load(image_provider.ProxyNetworkImage key) {
    // Ownership of this controller is handed off to [_loadAsync]; it is that
    // method's responsibility to close the controller's stream when the image
    // has been loaded or an error is thrown.
    final StreamController<ImageChunkEvent> chunkEvents = StreamController<ImageChunkEvent>();

    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(key, chunkEvents),
      chunkEvents: chunkEvents.stream,
      scale: key.scale,
      informationCollector: () {
        return <DiagnosticsNode>[
          DiagnosticsProperty<ImageProvider>('Image provider', this),
          DiagnosticsProperty<image_provider.ProxyNetworkImage>('Image key', key),
        ];
      },
    );
  }

  // Do not access this field directly; use [_httpClient] instead.
  // We set `autoUncompress` to false to ensure that we can trust the value of
  // the `Content-Length` HTTP header. We automatically uncompress the content
  // in our call to [consolidateHttpClientResponseBytes].
  static final HttpClient _sharedHttpClient = HttpClient()
    ..autoUncompress = false;

  static HttpClient get _httpClient {
    HttpClient client = _sharedHttpClient;
    assert(() {
      if (debugNetworkImageHttpClientProvider != null)
        client = debugNetworkImageHttpClientProvider();
      return true;
    }());
    return client;
  }

  Future<ui.Codec> _loadAsync(ProxyNetworkImage key,
      StreamController<ImageChunkEvent> chunkEvents,) async {
    try {
      assert(key == this);

      final Uri resolved = Uri.base.resolve(key.url);
      if (proxy != null && proxy.length > 0) {
        _httpClient.findProxy = (url) {
          return proxy;
        };
      }
      _httpClient.badCertificateCallback = (cert, host, port) {
        return true;
      };

      final HttpClientRequest request = await _httpClient.getUrl(resolved);
      headers?.forEach((String name, String value) {
        request.headers.add(name, value);
      });
      final HttpClientResponse response = await request.close();
      if (response.statusCode != HttpStatus.ok)
        throw Exception('HTTP request failed, statusCode: ${response?.statusCode}, $resolved');

      final Uint8List bytes = await consolidateHttpClientResponseBytes(
        response,
        onBytesReceived: (int cumulative, int total) {
          chunkEvents.add(ImageChunkEvent(
            cumulativeBytesLoaded: cumulative,
            expectedTotalBytes: total,
          ));
        },
      );
      if (bytes.lengthInBytes == 0)
        throw Exception('NetworkImage is an empty file: $resolved');

      return PaintingBinding.instance.instantiateImageCodec(bytes);
    } finally {
      chunkEvents.close();
    }
  }

  @override
  bool operator ==(dynamic other) {
    if (other.runtimeType != runtimeType)
      return false;
    final ProxyNetworkImage typedOther = other;
    return url == typedOther.url
        && scale == typedOther.scale;
  }

  @override
  int get hashCode => ui.hashValues(url, scale);

  @override
  String toString() => '$runtimeType("$url", scale: $scale)';
}
