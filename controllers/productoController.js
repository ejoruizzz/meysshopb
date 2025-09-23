const fs = require('fs');
const path = require('path');
const productoRepo = require('../repositories/productoRepository');

const IMAGE_RELATIVE_BASE = path.posix.join('uploads', 'products');

const requiredText = (value, fieldName) => {
  const val = value ?? '';
  const trimmed = val.toString().trim();
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

const parseStock = (value, fallback = null) => {
  if (value === undefined || value === null || value === '') {
    return fallback;
  }
  const parsed = Number.parseInt(value, 10);
  if (!Number.isFinite(parsed) || parsed < 0) {
    throw new Error('Stock inválido');
  }
  return parsed;
};

const pickFirst = (...values) => values.find((value) => value !== undefined && value !== null);

const toRelativeImagePath = (file) => {
  if (!file) return null;
  const filename = file.filename || path.basename(file.path);
  return path.posix.join(IMAGE_RELATIVE_BASE, filename);
};

const isRemotePath = (value) => typeof value === 'string' && /^https?:\/\//i.test(value.trim());

const toAbsolutePath = (relativePath) => {
  if (!relativePath || isRemotePath(relativePath)) return null;
  const safe = relativePath.replace(/\\/g, '/');
  return path.join(__dirname, '..', safe.split('/').join(path.sep));
};

const removeImage = (relativePath) => {
  const absolute = toAbsolutePath(relativePath);
  if (!absolute) return;
  fs.promises.unlink(absolute).catch(() => {});
};

const mapIncomingImage = (body) => {
  if (!body) return undefined;
  const raw = pickFirst(body.imagenUrl, body.imageUrl, body.imagen, body.imagen_url);
  if (raw === undefined) return undefined;
  if (raw === null) return '';
  const trimmed = raw.toString().trim();
  return trimmed;
};

const buildPayload = (body, { existing = null, imagePath = null, remoteImage = undefined } = {}) => {
  const nombreRaw = pickFirst(body?.nombre, body?.name);
  const descripcionRaw = pickFirst(body?.descripcion, body?.description);
  const categoriaRaw = pickFirst(body?.categoria, body?.category);
  const precioRaw = pickFirst(body?.precio, body?.price);
  const stockRaw = pickFirst(body?.stock, body?.cantidad);

  if (!existing) {
    const precio = parsePrice(precioRaw, null);
    const stock = parseStock(stockRaw, null);
    if (precio == null) throw new Error('Precio inválido');
    if (stock == null) throw new Error('Stock inválido');

    const payload = {
      nombre: requiredText(nombreRaw, 'Nombre'),
      descripcion: requiredText(descripcionRaw, 'Descripción'),
      categoria: requiredText(categoriaRaw, 'Categoría'),
      precio,
      stock,
      estado: optionalText(body?.estado, 'Activo') || 'Activo'
    };

    if (imagePath) {
      payload.imagen = imagePath;
    } else if (remoteImage !== undefined) {
      payload.imagen = remoteImage ? remoteImage : null;
    }

    return payload;
  }

  const payload = {
    nombre: optionalText(nombreRaw, existing.nombre),
    descripcion: optionalText(descripcionRaw, existing.descripcion),
    categoria: optionalText(categoriaRaw, existing.categoria),
    precio: parsePrice(precioRaw, existing.precio),
    stock: parseStock(stockRaw, existing.stock),
    estado: optionalText(body?.estado, existing.estado || 'Activo') || existing.estado || 'Activo'
  };

  if (imagePath) {
    payload.imagen = imagePath;
  } else if (remoteImage !== undefined) {
    payload.imagen = remoteImage ? remoteImage : null;
  }

  return payload;
};

const mapProductResponse = (req, data) => {
  if (!data) return null;
  const { imagen, ...rest } = data;
  let imagenUrl = '';
  if (imagen) {
    if (isRemotePath(imagen)) {
      imagenUrl = imagen;
    } else {
      const normalized = imagen.replace(/\\/g, '/');
      imagenUrl = `${req.protocol}://${req.get('host')}/${normalized}`;
    }
  }
  return { ...rest, imagen, imagenUrl };
};

const listar = async (req, res) => {
  try {
    const rawQuery = pickFirst(req.query?.q, req.query?.search);
    const q = typeof rawQuery === 'string' && rawQuery.trim() !== '' ? rawQuery.trim() : null;
    const items = await productoRepo.listar({ q });
    res.json(items.map((item) => mapProductResponse(req, item)));
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
};

const crear = async (req, res) => {
  let newImagePath = null;
  try {
    const remoteImage = mapIncomingImage(req.body);
    if (!req.file && (!remoteImage || remoteImage.trim() === '')) {
      return res.status(400).json({ error: 'Imagen requerida (archivo JPG/PNG o URL)' });
    }

    if (req.file) {
      newImagePath = toRelativeImagePath(req.file);
    }

    const payload = buildPayload(req.body, { imagePath: newImagePath, remoteImage });
    const item = await productoRepo.crear(payload);
    res.status(201).json(mapProductResponse(req, item));
  } catch (e) {
    if (newImagePath) removeImage(newImagePath);
    res.status(400).json({ error: e.message });
  }
};

const actualizar = async (req, res) => {
  let newImagePath = null;
  try {
    const id = Number(req.params.id);
    if (Number.isNaN(id) || id <= 0) return res.status(400).json({ error: 'ID inválido' });

    const actual = await productoRepo.buscarPorId(id);
    if (!actual) return res.status(404).json({ error: 'No encontrado' });

    const remoteImage = mapIncomingImage(req.body);
    if (req.file) {
      newImagePath = toRelativeImagePath(req.file);
    }

    const payload = buildPayload(req.body, { existing: actual, imagePath: newImagePath, remoteImage });
    const actualizado = await productoRepo.actualizar(id, payload);
    if (!actualizado) {
      if (newImagePath) removeImage(newImagePath);
      return res.status(404).json({ error: 'No encontrado' });
    }

    if (newImagePath && actual.imagen && actual.imagen !== newImagePath) {
      removeImage(actual.imagen);
    } else if (remoteImage !== undefined && actual.imagen && actual.imagen !== payload.imagen && !isRemotePath(actual.imagen)) {
      removeImage(actual.imagen);
    }

    res.json(mapProductResponse(req, actualizado));
  } catch (e) {
    if (newImagePath) removeImage(newImagePath);
    res.status(400).json({ error: e.message });
  }
};

const eliminar = async (req, res) => {
  try {
    const id = Number(req.params.id);
    if (Number.isNaN(id) || id <= 0) return res.status(400).json({ error: 'ID inválido' });

    const existing = await productoRepo.buscarPorId(id);
    const ok = await productoRepo.eliminar(id);
    if (!ok) return res.status(404).json({ error: 'No encontrado' });

    if (existing?.imagen && !isRemotePath(existing.imagen)) {
      removeImage(existing.imagen);
    }

    res.json({ ok: true });
  } catch (e) {
    res.status(400).json({ error: e.message });
  }
};

module.exports = { listar, crear, actualizar, eliminar };
