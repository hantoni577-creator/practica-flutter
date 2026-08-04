require('dotenv').config();

const express = require('express');
const cors = require('cors');

const authRoutes = require('./routes/authRoutes');

const app = express();

app.use(cors());

app.use(express.json());

app.use('/api/auth', authRoutes);

const PORT = process.env.PORT;

app.listen(PORT, () => {
    console.log(`Servidor iniciado en puerto ${PORT}`);
});