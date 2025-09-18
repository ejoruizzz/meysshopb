const clienteRepo = require('../repositories/clienteRepository');

// GET /api/clientes?q=texto
const listar = async (req, res) => {
  try {
    const q = typeof req.query.q === 'string' && req.query.q.trim() !== '' ? req.query.q.trim() : null;
    const items = await clienteRepo.listar({ q });
    res.json(items);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
};

// POST /api/clientes
const crear = async (req, res) => {
  try {
    // opcional: validar unicidad de email desde repo
    if (req.body.email) {
      const yaExiste = await clienteRepo.existeEmail(req.body.email);
      if (yaExiste) return res.status(409).json({ error: 'Email ya registrado' });
    }
    const item = await clienteRepo.crear(req.body);
    res.status(201).json(item);
  } catch (e) {
    res.status(400).json({ error: e.message });
  }
};

// PUT /api/clientes/:id
const actualizar = async (req, res) => {
  try {
    const id = Number(req.params.id);
    if (Number.isNaN(id) || id <= 0) return res.status(400).json({ error: 'ID inválido' });

    // opcional: validar unicidad si mandan email
    if (req.body.email) {
      const yaExiste = await clienteRepo.existeEmail(req.body.email, { excluirId: id });
      if (yaExiste) return res.status(409).json({ error: 'Email ya registrado' });
    }

    const actualizado = await clienteRepo.actualizar(id, req.body);
    if (!actualizado) return res.status(404).json({ error: 'No encontrado' });
    res.json(actualizado);
  } catch (e) {
    res.status(400).json({ error: e.message });
  }
};

// DELETE /api/clientes/:id
const eliminar = async (req, res) => {
  try {
    const id = Number(req.params.id);
    if (Number.isNaN(id) || id <= 0) return res.status(400).json({ error: 'ID inválido' });

    const ok = await clienteRepo.eliminar(id);
    if (!ok) return res.status(404).json({ error: 'No encontrado' });
    res.json({ ok: true });
  } catch (e) {
    res.status(400).json({ error: e.message });
  }
};

module.exports = { listar, crear, actualizar, eliminar };
