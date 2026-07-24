class ParentProfile {
  final String id;
  final String parentName;
  final String phone;
  final DateTime createdAt;

  ParentProfile({
    required this.id,
    required this.parentName,
    required this.phone,
    required this.createdAt,
  });

  factory ParentProfile.fromJson(Map<String, dynamic> json) {
    return ParentProfile(
      id: (json['id'] ?? json['Id'] ?? '').toString(),
      parentName: (json['parentName'] ?? json['name'] ?? json['ParentName'] ?? 'والدین').toString(),
      phone: (json['phone'] ?? json['phoneNumber'] ?? json['PhoneNumber'] ?? '').toString(),
      createdAt: json['createdAt'] != null && json['createdAt'].toString().isNotEmpty
          ? (DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'parentName': parentName,
      'phone': phone,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class ParentRegisterRequest {
  final String parentName;
  final String phone;
  final String password;
  final String childName;
  final int childAge;

  ParentRegisterRequest({
    required this.parentName,
    required this.phone,
    required this.password,
    required this.childName,
    required this.childAge,
  });

  Map<String, dynamic> toJson() {
    return {
      'parentName': parentName,
      'phone': phone,
      'password': password,
      'childName': childName,
      'childAge': childAge,
    };
  }
}

class ChildProfile {
  final String id;
  final String childName;
  final int childAge;
  final String? avatarUrl;
  final int stars;
  final DateTime createdAt;

  ChildProfile({
    required this.id,
    required this.childName,
    required this.childAge,
    this.avatarUrl,
    required this.stars,
    required this.createdAt,
  });

  factory ChildProfile.fromJson(Map<String, dynamic> json) {
    return ChildProfile(
      id: (json['id'] ?? json['childId'] ?? json['Id'] ?? '').toString(),
      childName: (json['childName'] ?? json['name'] ?? json['ChildName'] ?? 'فرزند من').toString(),
      childAge: int.tryParse((json['childAge'] ?? json['age'] ?? json['ChildAge'] ?? 7).toString()) ?? 7,
      avatarUrl: (json['avatarUrl'] ?? json['AvatarUrl'])?.toString(),
      stars: int.tryParse((json['stars'] ?? json['Stars'] ?? 0).toString()) ?? 0,
      createdAt: json['createdAt'] != null && json['createdAt'].toString().isNotEmpty
          ? (DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'childName': childName,
      'childAge': childAge,
      'avatarUrl': avatarUrl,
      'stars': stars,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class ParentRegisterResponse {
  final String token;
  final ParentProfile parent;
  final ChildProfile child;

  ParentRegisterResponse({
    required this.token,
    required this.parent,
    required this.child,
  });

  factory ParentRegisterResponse.fromJson(Map<String, dynamic> jsonMap) {
    final json = (jsonMap.containsKey('isSuccess') && jsonMap.containsKey('data') && jsonMap['data'] is Map<String, dynamic>)
        ? jsonMap['data'] as Map<String, dynamic>
        : (jsonMap.containsKey('data') && jsonMap['data'] is Map<String, dynamic> ? jsonMap['data'] as Map<String, dynamic> : jsonMap);
    return ParentRegisterResponse(
      token: json['token'] as String? ?? '',
      parent: ParentProfile.fromJson(json['parent'] as Map<String, dynamic>),
      child: ChildProfile.fromJson(json['child'] as Map<String, dynamic>),
    );
  }
}

class LoginRequest {
  final String phone;
  final String password;
  final String role; 
  final String? childId;

  LoginRequest({
    required this.phone,
    required this.password,
    this.role = 'Parent',
    this.childId,
  });

  Map<String, dynamic> toJson() {
    return {
      'phone': phone,
      'password': password,
      'role': role,
      if (childId != null) 'childId': childId,
    };
  }
}

class LoginResponse {
  final String token;
  final String role;
  final ParentProfile? parent;
  final ChildProfile? child;
  final List<ChildProfile>? kids;

  LoginResponse({
    required this.token,
    required this.role,
    this.parent,
    this.child,
    this.kids,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> jsonMap) {
    final json = (jsonMap.containsKey('isSuccess') && jsonMap.containsKey('data') && jsonMap['data'] is Map<String, dynamic>)
        ? jsonMap['data'] as Map<String, dynamic>
        : (jsonMap.containsKey('data') && jsonMap['data'] is Map<String, dynamic> ? jsonMap['data'] as Map<String, dynamic> : jsonMap);
    return LoginResponse(
      token: (json['token'] ?? json['accessToken'] ?? '').toString(),
      role: (json['role'] ?? 'Parent').toString(),
      parent: json['parent'] != null && json['parent'] is Map
          ? ParentProfile.fromJson(Map<String, dynamic>.from(json['parent'] as Map))
          : null,
      child: json['child'] != null && json['child'] is Map
          ? ChildProfile.fromJson(Map<String, dynamic>.from(json['child'] as Map))
          : null,
      kids: json['kids'] != null && json['kids'] is List
          ? (json['kids'] as List)
              .whereType<Map>()
              .map((k) => ChildProfile.fromJson(Map<String, dynamic>.from(k)))
              .toList()
          : null,
    );
  }
}

class TokenRequest {
  final String grantType;
  final String? username;
  final String? password;

  TokenRequest({
    required this.grantType,
    this.username,
    this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'grantType': grantType,
      if (username != null) 'username': username,
      if (password != null) 'password': password,
    };
  }
}

class UpdateProfileRequest {
  final String? firstName;
  final String? lastName;
  final String? nationalCode;
  final String? phoneNumber;
  final String? address;
  final String? state;
  final String? city;
  final String? postalCode;
  final String? economicCode;
  final String? birthday; 

  UpdateProfileRequest({
    this.firstName,
    this.lastName,
    this.nationalCode,
    this.phoneNumber,
    this.address,
    this.state,
    this.city,
    this.postalCode,
    this.economicCode,
    this.birthday,
  });

  Map<String, dynamic> toJson() {
    return {
      if (firstName != null) 'firstName': firstName,
      if (lastName != null) 'lastName': lastName,
      if (nationalCode != null) 'nationalCode': nationalCode,
      if (phoneNumber != null) 'phoneNumber': phoneNumber,
      if (address != null) 'address': address,
      if (state != null) 'state': state,
      if (city != null) 'city': city,
      if (postalCode != null) 'postalCode': postalCode,
      if (economicCode != null) 'economicCode': economicCode,
      if (birthday != null) 'birthday': birthday,
    };
  }
}

class CreateInitialUserRequest {
  final String? username;
  final String? password;
  final String? firstName;
  final String? lastName;
  final String? masterPassword;

  CreateInitialUserRequest({
    this.username,
    this.password,
    this.firstName,
    this.lastName,
    this.masterPassword,
  });

  Map<String, dynamic> toJson() {
    return {
      if (username != null) 'username': username,
      if (password != null) 'password': password,
      if (firstName != null) 'firstName': firstName,
      if (lastName != null) 'lastName': lastName,
      if (masterPassword != null) 'masterPassword': masterPassword,
    };
  }
}
