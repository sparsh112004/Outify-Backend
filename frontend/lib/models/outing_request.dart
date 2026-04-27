class OutingRequest {
  final int id;
  final String reason;
  final DateTime departureDatetime;
  final DateTime expectedReturnDatetime;
  final String? destination;
  final String? studentName;

  final String overallStatus;
  final String facultyStatus;
  final String wardenStatus;
  final String? securityRemarks;
  final DateTime? actualDepartureTime;
  final DateTime? actualReturnTime;

  const OutingRequest({
    required this.id,
    required this.reason,
    required this.departureDatetime,
    required this.expectedReturnDatetime,
    required this.destination,
    this.studentName,
    required this.overallStatus,
    required this.facultyStatus,
    required this.wardenStatus,
    this.securityRemarks,
    this.actualDepartureTime,
    this.actualReturnTime,
  });

  factory OutingRequest.fromJson(Map<String, dynamic> json) {
    try {
      print('OUTING_DEBUG: Starting parse of ID ${json['id']}');
      
      final id = json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? '0') ?? 0;
      print('OUTING_DEBUG: id parsed: $id');
      
      final reason = (json['reason'] ?? 'Unknown') as String;
      print('OUTING_DEBUG: reason parsed');
      
      final departure = json['departure_datetime'] != null 
          ? DateTime.parse(json['departure_datetime'].toString()).toLocal() 
          : DateTime.now();
      print('OUTING_DEBUG: departure parsed: $departure');
      
      final expectedReturn = json['expected_return_datetime'] != null 
          ? DateTime.parse(json['expected_return_datetime'].toString()).toLocal() 
          : DateTime.now();
      print('OUTING_DEBUG: expectedReturn parsed: $expectedReturn');
      
      final actualDeparture = json['actual_departure_time'] != null
          ? DateTime.parse(json['actual_departure_time'].toString()).toLocal()
          : null;
      print('OUTING_DEBUG: actualDeparture parsed: $actualDeparture');

      final actualReturn = json['actual_return_time'] != null
          ? DateTime.parse(json['actual_return_time'].toString()).toLocal()
          : null;
      print('OUTING_DEBUG: actualReturn parsed: $actualReturn');
      
      final destination = json['destination']?.toString();
      print('OUTING_DEBUG: destination parsed');
      
      final studentName = json['student_name']?.toString() ?? 
          (json['student'] != null ? json['student']['name']?.toString() : 'Unknown Student');
      print('OUTING_DEBUG: studentName parsed: $studentName');
      
      final overallStatus = (json['overall_status'] ?? 'unknown').toString();
      print('OUTING_DEBUG: overallStatus parsed: $overallStatus');
      
      final facultyStatus = (json['faculty_status'] ?? 'unknown').toString();
      print('OUTING_DEBUG: facultyStatus parsed');
      
      final wardenStatus = (json['warden_status'] ?? 'unknown').toString();
      print('OUTING_DEBUG: wardenStatus parsed');
      
      final securityRemarks = json['security_remarks']?.toString();

      return OutingRequest(
        id: id,
        reason: reason,
        departureDatetime: departure,
        expectedReturnDatetime: expectedReturn,
        destination: destination,
        studentName: studentName,
        overallStatus: overallStatus,
        facultyStatus: facultyStatus,
        wardenStatus: wardenStatus,
        securityRemarks: securityRemarks,
        actualDepartureTime: actualDeparture,
        actualReturnTime: actualReturn,
      );
    } catch (e, st) {
      print('CRITICAL JSON PARSE ERROR in OutingRequest: $e\nData: $json\n$st');
      rethrow;
    }
  }
}
