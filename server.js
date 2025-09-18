const express = require('express');
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
const db = require('./src/models')
db.sequelize.sync()
    .then(() => {
        console.log('Database synced successfully')
    })
    .catch((err) => {
        console.log('Error syncing database: ', err.message)
    })
const indexRoutes = require('./src/routes/index')
app.use(indexRoutes)
app.listen(PORT, () => {
    console.log(`Server is running on port ${PORT}`)
})