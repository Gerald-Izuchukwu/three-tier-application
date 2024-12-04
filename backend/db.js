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
    await connection.query(`USE ${DATABASE}`);
    console.log(`Using database: ${DATABASE}`);
    
        // Create a table (example: a 'countries' table)
        const createTableQuery = `
          CREATE TABLE IF NOT EXISTS countries (
            id INT AUTO_INCREMENT PRIMARY KEY,
            name VARCHAR(100) NOT NULL,
            timezones VARCHAR(100) NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
          )
        `;
        await connection.query(createTableQuery); // Execute the query
        console.log('Table "countries" ensured to exist.');

    return connection;
  } catch (err) {
    console.error('Error connecting to MySQL:', err);
    throw err;
  }
}

module.exports = connectDB;
