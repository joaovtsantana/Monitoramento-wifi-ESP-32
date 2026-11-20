
require('dotenv').config();

const express = require('express');
const cors = require('cors');
const pool = require('./config/database');

const coletasRoutes = require('./routes/coletas');

const app = express();

app.use(cors());
app.use(express.json());
app.use('/coletas', coletasRoutes);

app.get('/', (req, res) => {
    res.json({
        mensagem: 'API de monitoramento Wi-Fi funcionando!'
    });
});

app.get('/teste-banco', async (req, res) => {
    try {
        const resultado = await pool.query('SELECT NOW()');

        res.json({
            mensagem: 'Conexão com PostgreSQL realizada!',
            horario: resultado.rows[0].now
        });

    } catch (erro) {
        console.error(erro);
        res.status(500).json({
            erro: 'Falha ao conectar com o banco de dados.'
        });
    }
});

const PORT = 3001;

const servidor = app.listen(PORT, () => {
    console.log(`Servidor rodando na porta ${PORT}`);
});

servidor.on('close', () => {
    console.log('Servidor foi encerrado!');
});