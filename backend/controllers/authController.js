const db = require("../config/db");
const bcrypt = require("bcrypt");
const jwt = require("jsonwebtoken");

/*
==========================================
REGISTRO
==========================================
*/
const register = async (req, res) => {

    try {

        const { nombre, email, password } = req.body;

        if (!nombre || !email || !password) {

            return res.status(400).json({
                message: "Todos los campos son obligatorios"
            });

        }

        // Buscar si el correo existe

        const [user] = await db.query(
            "SELECT * FROM usuarios WHERE email=?",
            [email]
        );

        if (user.length > 0) {

            return res.status(400).json({
                message: "El correo ya existe"
            });

        }

        // Encriptar contraseña

        const hash = await bcrypt.hash(password, 10);

        await db.query(

            "INSERT INTO usuarios(nombre,email,password) VALUES(?,?,?)",

            [
                nombre,
                email,
                hash
            ]

        );

        res.status(201).json({

            message: "Usuario registrado correctamente"

        });

    }

    catch (error) {

        console.log(error);

        res.status(500).json({

            message: "Error del servidor"

        });

    }

};

/*
==========================================
LOGIN
==========================================
*/

const login = async (req, res) => {

    try {

        const { email, password } = req.body;

        const [rows] = await db.query(

            "SELECT * FROM usuarios WHERE email=?",

            [email]

        );

        if (rows.length == 0) {

            return res.status(401).json({

                message: "Credenciales incorrectas"

            });

        }

        const user = rows[0];

        const validPassword = await bcrypt.compare(

            password,

            user.password

        );

        if (!validPassword) {

            return res.status(401).json({

                message: "Credenciales incorrectas"

            });

        }

        const token = jwt.sign(

            {

                id: user.id,

                nombre: user.nombre,

                email: user.email

            },

            process.env.JWT_SECRET,

            {

                expiresIn: process.env.JWT_EXPIRES

            }

        );

        res.json({

            token,

            user: {

                id: user.id,

                nombre: user.nombre,

                email: user.email

            }

        });

    }

    catch (error) {

        console.log(error);

        res.status(500).json({

            message: "Error del servidor"

        });

    }

};

module.exports = {

    register,

    login

};