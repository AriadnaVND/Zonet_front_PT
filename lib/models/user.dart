class User {
  final String? name;
  final String? email;
  final String? password;
  final String? plan;

  User({this.name, this.email, this.password, this.plan});

  // Método para convertir el objeto User a JSON para la petición POST
  Map<String, dynamic> toJsonForRegistration() {
    return {
      'name': name,
      'email': email,
      'password': password,
      // No incluimos 'plan' para que el backend use el valor por defecto ('FREE')
    };
  }

  // Constructor para mapear la respuesta del backend (opcional, pero buena práctica)
  factory User.fromJson(Map<String, dynamic> json) {
    return User(name: json['name'], email: json['email'], plan: json['plan']);
  }
}
