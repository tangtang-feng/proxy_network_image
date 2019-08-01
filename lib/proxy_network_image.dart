library proxy_network_image;

import 'dart:io';

import 'package:flutter/painting.dart';

import '_proxy_network_image_io.dart'

if (dart.library.html) '_network_image_web.dart' as proxy_network_image;


/// Fetches the given URL from the network, associating it with the given scale.
///
/// The image will be cached regardless of cache headers from the server.
///
/// See also:
///
///  * [Image.network] for a shorthand of an [Image] widget backed by [NetworkImage].
// TODO(ianh): Find some way to honor cache headers to the extent that when the
// last reference to an image is released, we proactively evict the image from
// our cache if the headers describe the image as having expired at that point.
abstract class ProxyNetworkImage extends ImageProvider<ProxyNetworkImage> {
  /// Creates an object that fetches the image at the given URL.
  ///
  /// The arguments [url] and [scale] must not be null.
  const factory ProxyNetworkImage(String url, {String proxy, double scale, Map<String, String> headers }) = proxy_network_image.ProxyNetworkImage;

  /// The URL from which the image will be fetched.
  String get url;

  /// The scale to place in the [ImageInfo] object of the image.
  double get scale;

  /// The HTTP headers that will be used with [HttpClient.get] to fetch image from network.
  ///
  /// When running flutter on the web, headers are not used.
  Map<String, String> get headers;

  String get proxy;

  @override
  ImageStreamCompleter load(ProxyNetworkImage key);
}
