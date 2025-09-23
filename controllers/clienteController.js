const clienteRepo = require('../repositories/clienteRepository');

const requiredText = (value, fieldName) => {
  const val = value ?? '';
  const trimmed = val.toString().trim();
  if (!trimmed) {
    throw new Error(`${fieldName} requerido`);
  }
  return trimmed;
};

const optionalText = (value, fallback = null) => {
  if (value === undefined) return fallback;
  if (value === null) return null;
  const trimmed = value.toString().trim();
  if (!trimmed) return null;
  return trimmed;
};

const normalizeEmail = (value, fallback = null) => {
  if (value === undefined) return fallback;
  if (value === null) return null;
  const trimmed = value.toString().trim();
  if (!trimmed) return null;
  return trimmed.toLowerCase();
};

const listar = async (req, res) => {
  try {
    const rawQuery = typeof req.query.q === 'string' ? req.query.q : null;
    const q = rawQuery && rawQuery.trim() !== '' ? rawQuery.trim() : null;
    const items = await clienteRepo.listar({ q });
    res.json(items);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
};

const crear = async (req, res) => {
  try {
    const payload = {
      nombre: requiredText(req.body?.nombre, 'Nombre'),
      apellido: requiredText(req.body?.apellido, 'Apellido'),
      email: normalizeEmail(req.body?.email, null),
      telefono: optionalText(req.body?.telefono, null),
      direccion: optionalText(req.body?.direccion, null),
    };

    if (payload.email) {
      const yaExiste = await clienteRepo.existeEmail(payload.email);
      if (yaExiste) {
        return res.status(409).json({ error: 'Email ya registrado' });
      }
    }

    const item = await clienteRepo.crear(payload);
    res.status(201).json(item);
  } catch (e) {
    res.status(400).json({ error: e.message });
  }
};

const actualizar = async (req, res) => {
  try {
    const id = Number(req.params.id);
    if (Number.isNaN(id) || id <= 0) return res.status(400).json({ error: 'ID inválido' });

    const actual = await clienteRepo.buscarPorId(id);
    if (!actual) return res.status(404).json({ error: 'No encontrado' });

    const payload = {};

    if (req.body?.nombre !== undefined) {
      payload.nombre = requiredText(req.body.nombre, 'Nombre');
    }
    if (req.body?.apellido !== undefined) {
      payload.apellido = requiredText(req.body.apellido, 'Apellido');
    }
    if (req.body?.telefono !== undefined) {
      payload.telefono = optionalText(req.body.telefono, null);
    }
    if (req.body?.direccion !== undefined) {
      payload.direccion = optionalText(req.body.direccion, null);
    }
    if (req.body?.email !== undefined) {
      payload.email = normalizeEmail(req.body.email, null);
      if (payload.email) {
        const yaExiste = await clienteRepo.existeEmail(payload.email, { excluirId: id });
        if (yaExiste) {
          return res.status(409).json({ error: 'Email ya registrado' });
        }
      }
    }

    if (Object.keys(payload).length === 0) {
      return res.json(actual);
    }

    const actualizado = await clienteRepo.actualizar(id, payload);
    if (!actualizado) return res.status(404).json({ error: 'No encontrado' });

    res.json(actualizado);
  } catch (e) {
    res.status(400).json({ error: e.message });
  }
};

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
