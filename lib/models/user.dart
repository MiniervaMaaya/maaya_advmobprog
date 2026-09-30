enum LoginType { localDemo, dummyJson, firebase }

class User {
  final int id;
  final String? authUid;
  final LoginType loginType;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final int? age;
  final String contactNo;
  final String gender;
  final String image;
  final bool isOnline;

  const User({
    required this.id,
    this.authUid,
    this.loginType = LoginType.dummyJson,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.age,
    this.contactNo = '',
    this.gender = '',
    this.image = '',
    this.isOnline = false,
  });

  String get displayName => '$firstName $lastName'.trim().isEmpty
      ? username
      : '$firstName $lastName'.trim();

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: int.tryParse('${json['id']}') ?? 0,
      authUid: json['authUid'] as String?,
      loginType: LoginType.values.firstWhere(
        (value) => value.name == json['loginType'],
        orElse: () => LoginType.dummyJson,
      ),
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      age: (json['age'] as num?)?.toInt(),
      contactNo: json['contactNo'] as String? ?? '',
      gender: json['gender'] as String? ?? '',
      image: json['image'] as String? ?? '',
      isOnline: json['isOnline'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'authUid': authUid,
    'loginType': loginType.name,
    'username': username,
    'email': email,
    'firstName': firstName,
    'lastName': lastName,
    'age': age,
    'contactNo': contactNo,
    'gender': gender,
    'image': image,
    'isOnline': isOnline,
  };

  User copyWith({
    int? id,
    String? authUid,
    LoginType? loginType,
    String? username,
    String? email,
    String? firstName,
    String? lastName,
    int? age,
    String? contactNo,
    String? gender,
    String? image,
    bool? isOnline,
  }) => User(
    id: id ?? this.id,
    authUid: authUid ?? this.authUid,
    loginType: loginType ?? this.loginType,
    username: username ?? this.username,
    email: email ?? this.email,
    firstName: firstName ?? this.firstName,
    lastName: lastName ?? this.lastName,
    age: age ?? this.age,
    contactNo: contactNo ?? this.contactNo,
    gender: gender ?? this.gender,
    image: image ?? this.image,
    isOnline: isOnline ?? this.isOnline,
  );
}
