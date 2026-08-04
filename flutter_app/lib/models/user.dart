class User {

  final int id;

  final String nombre;

  final String email;

  User({

    required this.id,

    required this.nombre,

    required this.email,

  });

  factory User.fromJson(Map<String, dynamic> json) {

    return User(

      id: json["id"],

      nombre: json["nombre"],

      email: json["email"],

    );

  }

}