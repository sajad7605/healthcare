class RoleDto {
  final int? id;
  final String name;
  final String description;

  RoleDto({
    this.id,
    required this.name,
    required this.description,
  });

  factory RoleDto.fromJson(Map<String, dynamic> json) {
    return RoleDto(
      id: json['id'] as int?,
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'description': description,
    };
  }
}

class RoleSelectDto {
  final int id;
  final String? name;
  final String? normalizedName;
  final String? concurrencyStamp;
  final String? description;

  RoleSelectDto({
    required this.id,
    this.name,
    this.normalizedName,
    this.concurrencyStamp,
    this.description,
  });

  factory RoleSelectDto.fromJson(Map<String, dynamic> json) {
    return RoleSelectDto(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String?,
      normalizedName: json['normalizedName'] as String?,
      concurrencyStamp: json['concurrencyStamp'] as String?,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (name != null) 'name': name,
      if (normalizedName != null) 'normalizedName': normalizedName,
      if (concurrencyStamp != null) 'concurrencyStamp': concurrencyStamp,
      if (description != null) 'description': description,
    };
  }
}

class ApiResult {
  final bool isSuccess;
  final int statusCode; 
  final String? message;

  ApiResult({
    required this.isSuccess,
    required this.statusCode,
    this.message,
  });

  factory ApiResult.fromJson(Map<String, dynamic> json) {
    return ApiResult(
      isSuccess: json['isSuccess'] as bool? ?? false,
      statusCode: json['statusCode'] as int? ?? 0,
      message: json['message'] as String?,
    );
  }
}

class RoleSelectDtoApiResult {
  final bool isSuccess;
  final int statusCode;
  final String? message;
  final RoleSelectDto? data;

  RoleSelectDtoApiResult({
    required this.isSuccess,
    required this.statusCode,
    this.message,
    this.data,
  });

  factory RoleSelectDtoApiResult.fromJson(Map<String, dynamic> json) {
    return RoleSelectDtoApiResult(
      isSuccess: json['isSuccess'] as bool? ?? false,
      statusCode: json['statusCode'] as int? ?? 0,
      message: json['message'] as String?,
      data: json['data'] != null ? RoleSelectDto.fromJson(json['data'] as Map<String, dynamic>) : null,
    );
  }
}

class AddUserRoleDto {
  final int userId;
  final int roleId;

  AddUserRoleDto({
    required this.userId,
    required this.roleId,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'roleId': roleId,
    };
  }
}

class UserDto {
  final int? id;
  final String? userName;
  final String? firstName;
  final String? lastName;
  final String? phoneNumber;
  final String? nationalCode;
  final String? password;
  final int sazmanId;

  UserDto({
    this.id,
    this.userName,
    this.firstName,
    this.lastName,
    this.phoneNumber,
    this.nationalCode,
    this.password,
    required this.sazmanId,
  });

  factory UserDto.fromJson(Map<String, dynamic> json) {
    return UserDto(
      id: json['id'] as int?,
      userName: json['userName'] as String?,
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      nationalCode: json['nationalCode'] as String?,
      password: json['password'] as String?,
      sazmanId: json['sazmanId'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (userName != null) 'userName': userName,
      if (firstName != null) 'firstName': firstName,
      if (lastName != null) 'lastName': lastName,
      if (phoneNumber != null) 'phoneNumber': phoneNumber,
      if (nationalCode != null) 'nationalCode': nationalCode,
      if (password != null) 'password': password,
      'sazmanId': sazmanId,
    };
  }
}

class UserSelectDto {
  final int id;
  final String? firstName;
  final String? lastName;
  final DateTime created;
  final DateTime? lastLoginDate;
  final String? userName;
  final String? phoneNumber;

  UserSelectDto({
    required this.id,
    this.firstName,
    this.lastName,
    required this.created,
    this.lastLoginDate,
    this.userName,
    this.phoneNumber,
  });

  factory UserSelectDto.fromJson(Map<String, dynamic> json) {
    return UserSelectDto(
      id: json['id'] as int? ?? 0,
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      created: DateTime.parse(json['created'] as String),
      lastLoginDate: json['lastLoginDate'] != null ? DateTime.parse(json['lastLoginDate'] as String) : null,
      userName: json['userName'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
    );
  }
}

class UserSelectDtoPaginated {
  final List<UserSelectDto> content;
  final int totalPages;
  final int pageSize;

  UserSelectDtoPaginated({
    required this.content,
    required this.totalPages,
    required this.pageSize,
  });

  factory UserSelectDtoPaginated.fromJson(Map<String, dynamic> json) {
    return UserSelectDtoPaginated(
      content: (json['content'] as List? ?? [])
          .map((u) => UserSelectDto.fromJson(u as Map<String, dynamic>))
          .toList(),
      totalPages: json['totalPages'] as int? ?? 0,
      pageSize: json['pageSize'] as int? ?? 0,
    );
  }
}
