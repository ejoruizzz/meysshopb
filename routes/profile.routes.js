const express = require('express');
const controller = require('../controllers/profileController');
const { requiereAuth } = require('../middleware/authJwt');

const r = express.Router();

r.get('/me', requiereAuth, controller.getMe);
r.put('/me', requiereAuth, controller.updateMe);

module.exports = r;
