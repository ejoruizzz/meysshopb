const express = require('express');
const path = require('path');
const cors = require('cors');
const app = express()
require('dotenv').config()
const bodyParser = require('body-parser');
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({
    extended: true
}));
app.use(express.urlencoded({
    extended: true
}));
const PORT = process.env.PORT || 3001

app.get('/', (req, res) => {
    res.send('Hello World!')
})
app.get('/about', (req, res) => {
    res.send('About Page')
})
app.get('/contact', (req, res) => {
    res.send('Contact Page')
})
const db = require('./models/index.js')
const indexRoutes = require('./routes')

const DEFAULT_FRONTEND_ORIGIN = 'http://localhost:3000'
const configuredOrigins = process.env.FRONTEND_URL
    ? process.env.FRONTEND_URL.split(',').map((origin) => origin.trim()).filter(Boolean)
    : []
const allowedOrigins = configuredOrigins.length > 0 ? configuredOrigins : [DEFAULT_FRONTEND_ORIGIN]

const isOriginAllowed = (origin, whitelist) => whitelist.some((allowedOrigin) => allowedOrigin === origin)

app.use(cors({
    origin: (origin, callback) => {
        if (!origin || isOriginAllowed(origin, allowedOrigins)) {
            return callback(null, true)
        }

        return callback(new Error(`Origin ${origin} is not allowed by CORS policy`))
    },
    credentials: true,
}))
app.use(indexRoutes)

const startServer = async () => {
    try {
        await db.sequelize.authenticate()
        console.log('Database connection has been established successfully')

        await db.sequelize.sync()
        console.log('Database synced successfully')

        app.listen(PORT, () => {
            console.log(`Server is running on port ${PORT}`)
        })
    } catch (err) {
        console.error('Unable to connect to the database:', err.message)
        process.exit(1)
    }
}

startServer()
