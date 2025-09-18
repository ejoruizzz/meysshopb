const jwt = require("jsonwebtoken");
require('dotenv').config()
const ACCESS_SECRET = process.env.JWT_SECRET;
const REFRESH_SECRET = process.env.JWT_REFRESH_SECRET || 'refresh_secret';

const generateToken = (id) => {
  const expiresIn = 60 * 60 * 2;
  try {
    const token = jwt.sign(
      {
        id: id,
      },
      ACCESS_SECRET,
      {
        expiresIn,
      }
    );
    return {
      token,
      expiresIn,
    };
  } catch (error) {
    console.log(error);
  }
};
const generateRefreshToken = (id) => {
  const expiresIn = 60 * 60 * 24 * 30;
  try {
    const refreshToken = jwt.sign(
      {
        id,
      },
      REFRESH_SECRET,
      {
        expiresIn,
      }
    );
    console.log('refreshToken',refreshToken);
    return refreshToken;
  } catch (error) {
    console.log("error refresh", error);
  }
};
const tokenVerificationError = {
  "invalid signature": "La firma es invalida",
  "jwt expired": "JWT expirado",
  "invlid token": "Token no valido",
  "No Bearer": "Utiliza formato Bearer",
};
module.exports = {
  generateToken,
  generateRefreshToken,
  tokenVerificationError,
};
