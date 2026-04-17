class Department {
  final int id;
  final String name;

  const Department({
    required this.id,
    required this.name,
  });

  factory Department.fromJson(Map<String, dynamic> json) {
    return Department(
      id: json['id'],
      name: json['name'],
    );
  }
}
