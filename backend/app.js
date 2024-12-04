require('dotenv').config({ path: './config.env' });
const express = require('express')
const axios = require('axios')
const ct = require('countries-and-timezones');
const cors = require('cors')
const domain = "0.0.0.0" || "127.0.0.1" || "localhost"
const connectDB = require('./db')

const app = express()
app.use(express.json())
app.use(cors())


app.get('/welcome', (req, res)=>{
    res.status(200).json('Hi welcome to School For the Good, where we teach you how to use your powers for good')
})

app.get('/health', (req, res) => {
    res.status(200).sendFile(__dirname + '/index.html');
});

app.get('/list_db_parameters', (req, res)=>{
    res.status(200).json({
        "HOST":process.env.HOST,
        "MYSQL_USER":process.env.MYSQL_USER,
        "PASSWORD":process.env.PASSWORD,
        "DATABASE":process.env.DATABASE
    })
})


app.get('/thetimenow', async(req, res)=>{
    const date = new Date
    console.log (date.toString())
    return res.status(200).json({"date": date.toString()})
})

app.post('/gettime', async(req, res)=>{
    try {
        const date = new Date
        const {hours} = req.body
        console.log(req.body);
        date.setHours(date.getHours() + parseInt(hours, 10));
        const formattedDate = date.toString();
        console.log(formattedDate); 
        res.status(200).json({"date" : formattedDate})
    } catch (error) {
        if(error){
            console.log(error)
            res.send(error)
        }
    }
    
})

app.post('/getcountry', async(req, res)=>{
    try {
        const {countryID} = req.body
        console.log(countryID);
        const country = ct.getCountry(countryID)
        if (!country) {
            return res.status(404).json({ error: 'Country not found' });
          }
        console.log(country)
        console.log(process.env.HOST);
        console.log(process.env.MYSQL_USER);
        // return res.status(200).json(country)

        const db = await connectDB();

        const checkQuery = 'SELECT * FROM countries WHERE id = ?';
        const [rows] = await db.execute(checkQuery, [countryID]);
    
        if (rows.length > 0) {
          console.log('Country already exists:', rows[0]);
            return res.status(200).json(country)
        //   return res.status(200).json({ message: 'Country already exists', country: rows[0] });
        }
        const query = 'INSERT INTO countries (id, name, timezones) VALUES (?, ?, ?)';
        const values = [countryID, country.name, JSON.stringify(country.timezones)]; // Customize these fields based on your table structure

        const [result] = await db.execute(query, values);
        return res.status(200).json(country)
    } catch (error) {
        if(error){
            console.log(error)
            res.send(error)
        }
    }
})
// update this file on s3
app.get('/getallcountries', async(req, res)=>{
    try {
        const countries = ct.getAllCountries({})
        res.status(200).json(countries)
    } catch (error) {
        if(error){
            console.log(error)
            res.send(error)
        }
    }
})


app.get('/previouscountries', async (req, res) => {
    try {
      const db = await connectDB(); 
      const [rows] = await db.execute('SELECT * FROM countries'); 
      console.log(rows);
      res.status(200).json(rows);
    } catch (err) {
      console.error('Database error:', err);
      res.status(500).json({ error: 'Database error' });
    }
});

app.get('/deletepreviouscountries', async(req, res)=>{
    try {
        const db = await connectDB()
        const [rows] = await db.execute('DELETE FROM countries')
        res.status(200).json({msg: "COuntries Deleted"})
    } catch (error) {
        
    }
})

app.listen(9662, domain, ()=>{
    console.log("server a is listening on 9662")
})


// using HTTPS
// const express = require('express');
// const axios = require('axios');
// const ct = require('countries-and-timezones');
// const cors = require('cors');
// const https = require('https');
// const fs = require('fs');

// const domain = "0.0.0.0" || "127.0.0.1" || "localhost";
// const app = express();

// app.use(express.json());
// app.use(cors());

// // Load SSL certificate and key
// const sslOptions = {
//     key: fs.readFileSync('path/to/server.key'), // Path to your SSL private key
//     cert: fs.readFileSync('path/to/server.cert') // Path to your SSL certificate
// };

// // Define routes
// app.get('/welcome', (req, res) => {
//     res.status(200).json('Hi welcome to School For the Good, where we teach you how to use your powers for good');
// });

// app.get('/health', (req, res) => {
//     res.status(200).sendFile(__dirname + '/index.html');
// });

// app.get('/timenow', async (req, res) => {
//     const date = new Date();
//     console.log(date.toString());
//     return res.status(200).json({ "date": date.toString() });
// });

// app.post('/gettime', async (req, res) => {
//     try {
//         const date = new Date();
//         const { hours } = req.body;
//         console.log(req.body);
//         date.setHours(date.getHours() + parseInt(hours, 10));
//         const formattedDate = date.toString();
//         console.log(formattedDate);
//         res.status(200).json({ "date": formattedDate });
//     } catch (error) {
//         console.log(error);
//         res.status(500).send(error);
//     }
// });

// app.post('/getcountry', async (req, res) => {
//     try {
//         const { countryID } = req.body;
//         console.log(countryID);
//         const country = ct.getCountry(countryID);
//         console.log(country);
//         return res.status(200).json(country);
//     } catch (error) {
//         console.log(error);
//         res.status(500).send(error);
//     }
// });

// app.get('/getcountries', async (req, res) => {
//     try {
//         const countries = ct.getAllCountries({});
//         res.status(200).json(countries);
//     } catch (error) {
//         console.log(error);
//         res.status(500).send(error);
//     }
// });

// // Create HTTPS server
// const httpsServer = https.createServer(sslOptions, app);

// // Listen on port 443 for HTTPS
// httpsServer.listen(443, domain, () => {
//     console.log("Server is listening on port 443 (HTTPS)");
// });

// // Optionally, set up a redirect from HTTP to HTTPS
// const http = require('http');
// http.createServer((req, res) => {
//     res.writeHead(301, { "Location": "https://" + req.headers['host'] + req.url });
//     res.end();
// }).listen(80, domain, () => {
//     console.log("HTTP server is listening on port 80 and redirecting to HTTPS");
// });
