const mysql = require('mysql2/promise');
const HOST = process.env.HOST
const MYSQL_USER = process.env.MYSQL_USER
const PASSWORD = process.env.PASSWORD
const DATABASE = process.env.DATABASE

async function connectDB() {
  try {
    const connection = await mysql.createConnection({
      host: HOST,    
      user: MYSQL_USER,   
      password: PASSWORD,  
      database: DATABASE,  
    });
    console.log('Connected to MySQL');
    return connection;
  } catch (err) {
    console.error('Error connecting to MySQL:', err);
    throw err;
  }
}

module.exports = connectDB;
