const fs = require('fs');
const path = require('path');
const clienteRepo = require('../repositories/clienteRepository');

const IMAGE_RELATIVE_BASE = path.posix.join('uploads', 'products');

const requiredText = (value, fieldName) => {
  if (typeof value !== 'string') {
    throw new Error(`${fieldName} requerido`);
  }
  const trimmed = value.trim();
  if (!trimmed) {
    throw new Error(`${fieldName} requerido`);
  }
  return trimmed;
};

const optionalText = (value, fallback = null) => {
  if (value === undefined || value === null) {
    return fallback ?? null;
  }
  const trimmed = value.toString().trim();
  if (!trimmed) {
    return fallback ?? null;
  }
  return trimmed;
};

const parsePrice = (value, fallback = null) => {
  if (value === undefined || value === null || value === '') {
    return fallback;
  }
  const parsed = Number.parseFloat(value);
  if (!Number.isFinite(parsed) || parsed <= 0) {
    throw new Error('Precio inválido');
  }
  return parsed;
};

const parseCantidad = (value, fallback = null) => {
  if (value === undefined || value === null || value === '') {
    return fallback;
  }
  const parsed = Number.parseInt(value, 10);
  if (!Number.isFinite(parsed) || parsed < 0) {
    throw new Error('Cantidad inválida');
  }
  return parsed;
};

const toRelativeImagePath = (file) => {
  if (!file) return null;
  const filename = file.filename || path.basename(file.path);
  return path.posix.join(IMAGE_RELATIVE_BASE, filename);
};

const toAbsolutePath = (relativePath) => {
  if (!relativePath) return null;
  const safe = relativePath.replace(/\\/g, '/');
  return path.join(__dirname, '..', safe.split('/').join(path.sep));
};

const removeImage = (relativePath) => {
  const absolute = toAbsolutePath(relativePath);
  if (!absolute) return;
  fs.promises.unlink(absolute).catch(() => {});
};

const buildPayload = (body, { existing = null, imagePath = null } = {}) => {
  if (!existing) {
    const price = parsePrice(body.price ?? body.precio, null);
    const cantidad = parseCantidad(body.cantidad ?? body.stock, null);
    if (price == null) throw new Error('Precio inválido');
    if (cantidad == null) throw new Error('Cantidad inválida');

    return {
      nombre: requiredText(body.nombre, 'Nombre'),
      apellido: requiredText(body.apellido, 'Apellido'),
      email: optionalText(body.email, null),
      telefono: optionalText(body.telefono, null),
      direccion: optionalText(body.direccion, null),
      estado: optionalText(body.estado, 'Activo') || 'Activo',
      price,
      cantidad,
      imagen: imagePath,
    };
  }

  const payload = {
    nombre: optionalText(body.nombre, existing.nombre),
    apellido: optionalText(body.apellido, existing.apellido),
    email: optionalText(body.email, existing.email ?? null),
    telefono: optionalText(body.telefono, existing.telefono ?? null),
    direccion: optionalText(body.direccion, existing.direccion ?? null),
    estado: optionalText(body.estado, existing.estado || 'Activo') || existing.estado || 'Activo',
    price: parsePrice(body.price ?? body.precio, existing.price),
    cantidad: parseCantidad(body.cantidad ?? body.stock, existing.cantidad),
  };

  if (imagePath) {
    payload.imagen = imagePath;
  }

  return payload;
};

const mapProductResponse = (req, data) => {
  if (!data) return null;
  const { imagen, ...rest } = data;
  const normalized = imagen ? imagen.replace(/\\/g, '/') : '';
  return {
    ...rest,
    imageUrl: normalized ? `${req.protocol}://${req.get('host')}/${normalized}` : '',
  };
};

// GET /api/clientes?q=texto
const listar = async (req, res) => {
  try {
    const q = typeof req.query.q === 'string' && req.query.q.trim() !== '' ? req.query.q.trim() : null;
    const items = await clienteRepo.listar({ q });
    res.json(items.map((item) => mapProductResponse(req, item)));
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
};

// POST /api/clientes
const crear = async (req, res) => {
  let newImagePath = null;
  try {
    if (!req.file) {
      return res.status(400).json({ error: 'Imagen requerida (JPG o PNG)' });
    }

    newImagePath = toRelativeImagePath(req.file);
    const payload = buildPayload(req.body, { imagePath: newImagePath });

    if (payload.email) {
      const yaExiste = await clienteRepo.existeEmail(payload.email);
      if (yaExiste) {
        removeImage(newImagePath);
        return res.status(409).json({ error: 'Email ya registrado' });
      }
    }

    const item = await clienteRepo.crear(payload);
    res.status(201).json(mapProductResponse(req, item));
  } catch (e) {
    if (newImagePath) removeImage(newImagePath);
    res.status(400).json({ error: e.message });
  }
};

// PUT /api/clientes/:id
const actualizar = async (req, res) => {
  let newImagePath = null;
  try {
    const id = Number(req.params.id);
    if (Number.isNaN(id) || id <= 0) return res.status(400).json({ error: 'ID inválido' });

    const actual = await clienteRepo.buscarPorId(id);
    if (!actual) return res.status(404).json({ error: 'No encontrado' });

    if (req.file) {
      newImagePath = toRelativeImagePath(req.file);
    }

    const payload = buildPayload(req.body, { existing: actual, imagePath: newImagePath });

    if (payload.email) {
      const yaExiste = await clienteRepo.existeEmail(payload.email, { excluirId: id });
      if (yaExiste) {
        if (newImagePath) removeImage(newImagePath);
        return res.status(409).json({ error: 'Email ya registrado' });
      }
    }

    const actualizado = await clienteRepo.actualizar(id, payload);
    if (!actualizado) {
      if (newImagePath) removeImage(newImagePath);
      return res.status(404).json({ error: 'No encontrado' });
    }

    if (newImagePath && actual.imagen && actual.imagen !== newImagePath) {
      removeImage(actual.imagen);
    }

    res.json(mapProductResponse(req, actualizado));
  } catch (e) {
    if (newImagePath) removeImage(newImagePath);
    res.status(400).json({ error: e.message });
  }
};

// DELETE /api/clientes/:id
const eliminar = async (req, res) => {
  try {
    const id = Number(req.params.id);
    if (Number.isNaN(id) || id <= 0) return res.status(400).json({ error: 'ID inválido' });

    const existing = await clienteRepo.buscarPorId(id);
    const ok = await clienteRepo.eliminar(id);
    if (!ok) return res.status(404).json({ error: 'No encontrado' });
    if (existing?.imagen) {
      removeImage(existing.imagen);
    }
    res.json({ ok: true });
  } catch (e) {
    res.status(400).json({ error: e.message });
  }
};

module.exports = { listar, crear, actualizar, eliminar };
