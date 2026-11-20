
const express = require('express');
const multer = require('multer');
const { parse } = require('csv-parse/sync');
const pool = require('../config/database');

const router = express.Router();

const upload = multer({
    storage: multer.memoryStorage()
});

router.post('/importar', upload.single('arquivo'), async (req, res) => {

    if (!req.file) {
        return res.status(400).json({
            erro: 'Nenhum arquivo CSV foi enviado.'
        });
    }

    let medicoes;

    try {
        medicoes = parse(req.file.buffer, {
            columns: true,
            skip_empty_lines: true,
            trim: true,
            bom: true
        });
    } catch (erro) {
        return res.status(400).json({
            erro: 'Não foi possível interpretar o CSV.'
        });
    }

    if (medicoes.length === 0) {
        return res.status(400).json({
            erro: 'O arquivo CSV não possui medições.'
        });
    }

    const cabecalhos = ['Leitura', 'Ambiente', 'Rede', 'RSSI'];

    if (!cabecalhos.every(campo => Object.hasOwn(medicoes[0], campo))) {
        return res.status(400).json({
            erro: 'O CSV não possui as colunas esperadas.'
        });
    }

    for (const medicao of medicoes) {
        if (
            !medicao.Ambiente ||
            !medicao.Rede ||
            !Number.isInteger(Number(medicao.Leitura)) ||
            !Number.isInteger(Number(medicao.RSSI))
        ) {
            return res.status(400).json({
                erro: 'O CSV contém medições inválidas.'
            });
        }
    }

    const client = await pool.connect();

    try {
        await client.query('BEGIN');

        const coleta = await client.query(
            `INSERT INTO coletas (descricao)
             VALUES ($1)
             RETURNING id`,
            [req.body.descricao || 'Coleta importada do ESP32']
        );

        const coletaId = coleta.rows[0].id;

        for (const medicao of medicoes) {
            await client.query(
                `INSERT INTO medicoes
                 (coleta_id, numero_leitura, ambiente, rede, rssi)
                 VALUES ($1, $2, $3, $4, $5)`,
                [
                    coletaId,
                    Number(medicao.Leitura),
                    medicao.Ambiente,
                    medicao.Rede,
                    Number(medicao.RSSI)
                ]
            );
        }

        await client.query('COMMIT');

        res.status(201).json({
            mensagem: 'Coleta importada com sucesso!',
            coleta_id: coletaId,
            total_medicoes: medicoes.length
        });

    } catch (erro) {
        await client.query('ROLLBACK');

        console.error(erro);

        res.status(500).json({
            erro: 'Erro ao salvar as medições no banco.'
        });

    } finally {
        client.release();
    }
});


router.post('/receber', async (req, res) => {

    const { descricao, medicoes } = req.body;

    if (!Array.isArray(medicoes) || medicoes.length === 0) {
        return res.status(400).json({
            erro: 'Nenhuma medição foi enviada.'
        });
    }

    for (const medicao of medicoes) {
        if (
            !medicao.Ambiente ||
            !medicao.Rede ||
            !Number.isInteger(Number(medicao.Leitura)) ||
            !Number.isInteger(Number(medicao.RSSI)) ||
            Number(medicao.RSSI) < -100 ||
            Number(medicao.RSSI) > 0
        ) {
            return res.status(400).json({
                erro: 'O envio contém medições inválidas.'
            });
        }
    }

    const client = await pool.connect();

    try {
        await client.query('BEGIN');

        const coleta = await client.query(
            `INSERT INTO coletas (descricao)
             VALUES ($1)
             RETURNING id`,
            [descricao || 'Coleta enviada pelo ESP32']
        );

        const coletaId = coleta.rows[0].id;

        for (const medicao of medicoes) {
            await client.query(
                `INSERT INTO medicoes
                 (coleta_id, numero_leitura, ambiente, rede, rssi)
                 VALUES ($1, $2, $3, $4, $5)`,
                [
                    coletaId,
                    Number(medicao.Leitura),
                    medicao.Ambiente,
                    medicao.Rede,
                    Number(medicao.RSSI)
                ]
            );
        }

        await client.query('COMMIT');

        res.status(201).json({
            mensagem: 'Coleta recebida com sucesso!',
            coleta_id: coletaId,
            total_medicoes: medicoes.length
        });

    } catch (erro) {
        await client.query('ROLLBACK');

        console.error(erro);

        res.status(500).json({
            erro: 'Erro ao salvar as medições no banco.'
        });

    } finally {
        client.release();
    }
});

// Listar todas as coletas
router.get('/', async (req, res) => {
    try {
        const resultado = await pool.query(
            `SELECT id, data_coleta, descricao
             FROM coletas
             ORDER BY data_coleta DESC`
        );

        res.json(resultado.rows);

    } catch (erro) {
        console.error(erro);
        res.status(500).json({
            erro: 'Erro ao buscar coletas.'
        });
    }
});


// Buscar uma coleta e suas medições
router.get('/:id', async (req, res) => {
    const { id } = req.params;

    try {
        const coleta = await pool.query(
            `SELECT id, data_coleta, descricao
             FROM coletas
             WHERE id = $1`,
            [id]
        );

        if (coleta.rows.length === 0) {
            return res.status(404).json({
                erro: 'Coleta não encontrada.'
            });
        }

        const medicoes = await pool.query(
            `SELECT numero_leitura, ambiente, rede, rssi
             FROM medicoes
             WHERE coleta_id = $1
             ORDER BY ambiente, numero_leitura`,
            [id]
        );

        res.json({
            coleta: coleta.rows[0],
            medicoes: medicoes.rows
        });

    } catch (erro) {
        console.error(erro);
        res.status(500).json({
            erro: 'Erro ao buscar medições.'
        });
    }
});

module.exports = router;
