library simple_url_preview_v2;

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart';
import 'package:http/http.dart';
import 'package:shimmer/shimmer.dart';
import 'package:simple_url_preview_v2/widgets/preview_description.dart';
import 'package:simple_url_preview_v2/widgets/preview_image.dart';
import 'package:simple_url_preview_v2/widgets/preview_site_name.dart';
import 'package:simple_url_preview_v2/widgets/preview_title.dart';
import 'package:string_validator/string_validator.dart';
import 'package:url_launcher/url_launcher.dart';

class SimpleUrlPreview extends StatefulWidget {
  /// Whether or not to show link for the preview
  final bool? isShowLink;

  /// URL for which preview is to be shown
  final String url;

  /// Height of the preview
  final double previewHeight;

  /// elevation of the preview card
  final double elevation;

  /// Whether or not to show close button for the preview
  final bool? isClosable;

  /// Background color
  final Color? bgColor;

  /// Style of Title.
  final TextStyle? titleStyle;

  /// Number of lines for Title. (Max possible lines = 2)
  final int titleLines;

  /// Style of Description
  final TextStyle? descriptionStyle;

  /// Number of lines for Description. (Max possible lines = 3)
  final int descriptionLines;

  /// Style of site title
  final TextStyle? siteNameStyle;

  /// Color for loader icon shown, till image loads
  final Color? imageLoaderColor;

  /// Container padding
  final EdgeInsetsGeometry? previewContainerPadding;

  /// onTap URL preview, by default opens URL in default browser
  final VoidCallback? onTap;

  const SimpleUrlPreview({
    required this.url,
    this.previewHeight = 130.0,
    this.elevation = 5,
    this.isClosable,
    this.bgColor,
    this.titleStyle,
    this.titleLines = 2,
    this.descriptionStyle,
    this.descriptionLines = 3,
    this.siteNameStyle,
    this.imageLoaderColor,
    this.previewContainerPadding,
    this.isShowLink,
    this.onTap,
  })  : assert(previewHeight >= 130.0,
            'The preview height should be greater than or equal to 130'),
        assert(titleLines <= 2 && titleLines > 0,
            'The title lines should be less than or equal to 2 and not equal to 0'),
        assert(descriptionLines <= 3 && descriptionLines > 0,
            'The description lines should be less than or equal to 3 and not equal to 0');

  @override
  State<SimpleUrlPreview> createState() => _SimpleUrlPreviewState();
}

class _SimpleUrlPreviewState extends State<SimpleUrlPreview> {
  Map? _urlPreviewData;
  bool _isVisible = true;
  late bool _isClosable;
  double? _previewHeight;
  double? _elevation;
  Color? _bgColor;
  TextStyle? _titleStyle;
  int? _titleLines;
  TextStyle? _descriptionStyle;
  int? _descriptionLines;
  TextStyle? _siteNameStyle;
  Color? _imageLoaderColor;
  EdgeInsetsGeometry? _previewContainerPadding;
  VoidCallback? _onTap;
  late bool _isShowLink;

  late bool _isLoadingData;

  @override
  void initState() {
    super.initState();
    _getUrlData();
    _isLoadingData = false;
  }

  @override
  void didUpdateWidget(SimpleUrlPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    _getUrlData();
  }

  void _initialize() {
    _previewHeight = widget.previewHeight;
    _elevation = widget.elevation;
    _descriptionStyle = widget.descriptionStyle;
    _descriptionLines = widget.descriptionLines;
    _titleStyle = widget.titleStyle;
    _titleLines = widget.titleLines;
    _siteNameStyle = widget.siteNameStyle;
    _previewContainerPadding = widget.previewContainerPadding;
    _onTap = widget.onTap ?? _launchURL;
  }

  void _getUrlData() async {
    _isLoadingData = true;

    if (!isURL(widget.url)) {
      setState(() {
        _urlPreviewData = null;
      });
      return;
    }

    var response = await get(Uri.parse(widget.url));
    if (response.statusCode != 200) {
      if (!mounted) {
        return;
      }
      setState(() {
        _urlPreviewData = null;
      });
    }

    var document = parse(response.body);
    Map data = {};
    _extractOGData(document, data, 'og:title');
    _extractOGData(document, data, 'og:description');
    _extractOGData(document, data, 'og:site_name');
    _extractOGData(document, data, 'og:image');

    if (!mounted) {
      return;
    }

    if (data.isNotEmpty) {
      setState(() {
        _urlPreviewData = data;
        _isVisible = true;
      });
    }
    _isLoadingData = false;
  }

  void _extractOGData(Document document, Map data, String parameter) {
    var titleMetaTag = document
        .getElementsByTagName("meta")
        .firstWhereOrNull((meta) => meta.attributes['property'] == parameter);
    if (titleMetaTag != null) {
      data[parameter] = titleMetaTag.attributes['content'];
    }
  }

  void _launchURL() async {
    final Uri url = Uri.parse(widget.url);

    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      throw 'Could not launch ${widget.url}';
    }
  }

  @override
  Widget build(BuildContext context) {
    _isClosable = widget.isClosable ?? false;
    _isShowLink = widget.isShowLink ?? false;
    _bgColor = widget.bgColor ?? Theme.of(context).primaryColor;
    _imageLoaderColor =
        widget.imageLoaderColor ?? Theme.of(context).colorScheme.secondary;
    _initialize();

    if (_urlPreviewData == null || !_isVisible) {
      return const SizedBox();
    }

    return _isLoadingData
        ? Shimmer.fromColors(
            // Wrap your widget into Shimmer.
            baseColor: Colors.grey[200]!,
            highlightColor: Colors.grey[350]!,
            child: Card(
              elevation: 1.0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: SizedBox(
                height: _previewHeight,
              ),
            ))
        : Container(
            padding: _previewContainerPadding,
            height: _previewHeight,
            child: Stack(
              children: [
                GestureDetector(
                  onTap: _onTap,
                  child: _buildPreviewCard(context),
                ),
                _buildClosablePreview(),
              ],
            ),
          );
  }

  Widget _buildClosablePreview() {
    return _isClosable
        ? Align(
            alignment: Alignment.topRight,
            child: IconButton(
              icon: const Icon(
                Icons.clear,
              ),
              onPressed: () {
                setState(() {
                  _isVisible = false;
                });
              },
            ),
          )
        : const SizedBox();
  }

  Card _buildPreviewCard(BuildContext context) {
    print(_isLoadingData);
    return Card(
      elevation: _elevation,
      color: _bgColor,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          SizedBox(
            width: (MediaQuery.of(context).size.width -
                    MediaQuery.of(context).padding.left -
                    MediaQuery.of(context).padding.right) *
                0.25,
            child: PreviewImage(
              _urlPreviewData!['og:image'],
              _imageLoaderColor,
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  PreviewTitle(
                      _urlPreviewData!['og:title'],
                      _titleStyle ??
                          TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                      _titleLines),
                  PreviewDescription(
                    _urlPreviewData!['og:description'],
                    _descriptionStyle ??
                        TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                    _descriptionLines,
                  ),
                  PreviewSiteName(
                    _isShowLink ? widget.url : _urlPreviewData!['og:site_name'],
                    _siteNameStyle ??
                        TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
