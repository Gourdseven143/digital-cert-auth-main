class Certificate {
  final String id;
  final String fullName;
  final String title;
  final String issuer;
  final DateTime issueDate;
  final String signature;

  Certificate({
    required this.id,
    required this.fullName,
    required this.title,
    required this.issuer,
    required this.issueDate,
    required this.signature,
  });

  // 🔧 Add this:
  Certificate copyWith({
    String? id,
    String? fullName,
    String? title,
    String? issuer,
    DateTime? issueDate,
    String? signature,
  }) {
    return Certificate(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      title: title ?? this.title,
      issuer: issuer ?? this.issuer,
      issueDate: issueDate ?? this.issueDate,
      signature: signature ?? this.signature,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fullName': fullName,
      'title': title,
      'issuer': issuer,
      'issueDate': issueDate.toIso8601String(),
      'signature': signature,
    };
  }

  factory Certificate.fromMap(Map<String, dynamic> map) {
    return Certificate(
      id: map['id'],
      fullName: map['fullName'],
      title: map['title'],
      issuer: map['issuer'],
      issueDate: DateTime.parse(map['issueDate']),
      signature: map['signature'],
    );
  }
}
//certificate model