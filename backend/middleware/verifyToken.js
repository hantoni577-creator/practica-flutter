const jwt = require("jsonwebtoken");

const verifyToken = (req, res, next) => {

    const authHeader = req.headers["authorization"];

    if (!authHeader) {

        return res.status(401).json({

            message: "Token requerido"

        });

    }

    const token = authHeader.split(" ")[1];

    if (!token) {

        return res.status(401).json({

            message: "Token inválido"

        });

    }

    jwt.verify(

        token,

        process.env.JWT_SECRET,

        (err, decoded) => {

            if (err) {

                return res.status(403).json({

                    message: "Token expirado o inválido"

                });

            }

            req.user = decoded;

            next();

        }

    );

};

module.exports = verifyToken;