import 'package:ata/core/services/office_service.dart';
import 'package:dartz/dartz.dart';
import 'package:ata/util.dart';
import 'package:ata/core/models/failure.dart';
import 'package:ata/core/models/ip_info.dart';

class IpInfoService {
  final OfficeService _officeService;
  IpInfoService(OfficeService officeService) : _officeService = officeService;

  //* Model reference
  Either<Failure, IpInfo> _ipInfo;
  Either<Failure, IpInfo> get ipInfo => _ipInfo;
  void _setIpInfo(Either<Failure, IpInfo> ipInfo) {
    _ipInfo = ipInfo;
  }

  //* all async request here
  Future<void> refreshService() async {
    await fetchDeviceIpInfo();
    await _officeService.fetchOfficeSettings();
  }

  String getDeviceIp() {
    return _ipInfo.fold(
      (failure) => failure.toString(),
      (ipInfo) => ipInfo.ipAddress,
    );
  }

  String getOfficeIp() {
    return _officeService.officeSettings.fold(
      //* '- ' fix error when No Internet shows green status
      (failure) => '- ' + failure.toString(),
      (office) => office.ipAddress,
    );
  }

  bool checkIpForAttendance() {
    var deviceIp = getDeviceIp();
    var officeIp = getOfficeIp();
    return deviceIp == officeIp;
  }

  //* Utils
  Future<void> fetchDeviceIpInfo() async {
    await Util.requestEither<IpInfo>(
      RequestType.GET,
      'http://ip-api.com/json',
    ).then((value) => _setIpInfo(value));
  }
}
