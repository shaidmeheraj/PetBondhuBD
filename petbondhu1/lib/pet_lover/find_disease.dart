// Export the mobile TFLite implementation on native builds, and the web-safe
// implementation when compiled for the web. This ensures the Find Disease
// tab uses the on-device model on emulator/device and a safe uploader on web.
export 'find_disease_mobile.dart'
	if (dart.library.html) 'find_disease_web.dart';
