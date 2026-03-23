/// Stub for dart:io on web platforms.
/// Provides a minimal [File] shim so that API/provider code that
/// accepts an optional [File] parameter compiles on Flutter Web.
/// On web, callers always use [Uint8List] bytes instead of [File].

/// Web-only stub for [dart:io]'s `File` class.
///
/// File I/O operations are NOT supported on web. This class exists solely
/// so that method signatures that accept an optional `File?` parameter can
/// compile on web. On web those parameters are always `null`; actual file
/// content is passed as `Uint8List` bytes instead.
class File {
  final String path;
  const File(this.path);
}
