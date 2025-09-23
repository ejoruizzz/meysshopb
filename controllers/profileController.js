const authRepo = require('../repositories/authRepository');

const normalizarOpcional = (valor) => {
  if (valor === undefined) return undefined;
  if (valor === null) return null;
  if (typeof valor === 'string') {
    const trimmed = valor.trim();
    return trimmed === '' ? null : trimmed;
  }
  const str = String(valor).trim();
  return str === '' ? null : str;
};

const getMe = async (req, res) => {
  try {
    const userId = req.user?.id;
    if (!userId) return res.status(401).json({ error: 'No autorizado' });

    const usuario = await authRepo.buscarUsuarioPorId(userId);
    if (!usuario) return res.status(404).json({ error: 'Usuario no encontrado' });

    res.json(usuario);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
};

const updateMe = async (req, res) => {
  try {
    const userId = req.user?.id;
    if (!userId) return res.status(401).json({ error: 'No autorizado' });

    const body = req.body ?? {};
    const patch = {};

    if (Object.prototype.hasOwnProperty.call(body, 'nombre')) {
      if (typeof body.nombre !== 'string' || body.nombre.trim() === '') {
        return res.status(400).json({ error: 'Nombre inválido' });
      }
      patch.nombre = body.nombre.trim();
    }

    if (Object.prototype.hasOwnProperty.call(body, 'email')) {
      if (typeof body.email !== 'string') {
        return res.status(400).json({ error: 'Email inválido' });
      }
      const email = body.email.trim();
      if (email === '' || !email.includes('@')) {
        return res.status(400).json({ error: 'Email inválido' });
      }
      patch.email = email;
    }

    const phoneRaw = Object.prototype.hasOwnProperty.call(body, 'phone')
      ? body.phone
      : body.telefono;
    if (phoneRaw !== undefined) {
      patch.phone = normalizarOpcional(phoneRaw);
    }

    const avatarRaw = Object.prototype.hasOwnProperty.call(body, 'avatarUrl')
      ? body.avatarUrl
      : body.avatar;
    if (avatarRaw !== undefined) {
      patch.avatarUrl = normalizarOpcional(avatarRaw);
    }

    if (Object.keys(patch).length === 0) {
      const actual = await authRepo.buscarUsuarioPorId(userId);
      if (!actual) return res.status(404).json({ error: 'Usuario no encontrado' });
      return res.json(actual);
    }

    if (patch.email) {
      const yaExiste = await authRepo.existeEmail(patch.email, { excluirId: userId });
      if (yaExiste) return res.status(409).json({ error: 'Email ya registrado' });
    }

    const actualizado = await authRepo.actualizarUsuario(userId, patch);
    if (!actualizado) return res.status(404).json({ error: 'Usuario no encontrado' });

    res.json(actualizado);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
};

module.exports = { getMe, updateMe };
