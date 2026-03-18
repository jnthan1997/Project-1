//import express to start server
const express = require("express")
//import mysql
const sql = require("mysql")
//put secrets as env
const dotenv = require('dotenv');
//import path
const path = require('path');
dotenv.config({ path: './.env'});
const jwt = require("jsonwebtoken");
const bcrypt = require("bcryptjs");
const serverless = require("serverless-http");
const cookie = require('cookie-parser');



/** connecting backend to db  create pool to avoid cold start as 
 * lamda create instances pooling prevent failure
*/
const db = sql.createPool({
  host: process.env.DB_HOST,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  port: Number(process.env.DB_PORT),
  connectionLimit: 5
});







/** ROUTES */
//give access to current directory
const app = express();



    //add the directory object
 //app.use(express.static(directory));

app.use(cookie());
 app.use(express.urlencoded({ extended: false}));
 app.use(express.json());

 app.set('view engine', 'hbs');
 app.set('views', path.join(__dirname, 'views'));

 app.get('/',(req,res) => {
    res.render("index")
});


app.get('/login',(req,res) => {
    res.render("index")
});


app.post("/login", (req, res) => {
    
    const email = req.body.email;
    const password = req.body.password;

    if (!email || !password) {
        return res.render("index", { message: "Please enter email and password" });
    }

    // check if user exists
    db.query("SELECT * FROM user WHERE email = ?", [email], async (error, results) => {
        if (error) {
            console.log(error);
            return res.render("index", { message: "Database error" });
        }

        if (results.length === 0) {
            return res.render("index", { message: "User not found" });
        }

        const user = results[0];

        // compare password
        const isMatch = await bcrypt.compare(password, user.password);
        if (!isMatch) {
            return res.render("index", { message: "Incorrect password" });
        }

        // generate JWT
     const token = jwt.sign(
    { id: user.id, email: user.email, first_name: user.first_name, last_name: user.last_name },
    process.env.JWT_SECRET,
    { expiresIn: "1h" }
);

        // set token as http-only cookie
        res.cookie("jwt", token, {
            httpOnly: true,
            secure: true, // set to true if using https
            sameSite: "None",
            maxAge: 60 * 60 * 1000 // 1 hour
        });

       return res.redirect("/dashboard");
    });
}); 

function isAuthenticated(req, res, next) {
    const token = req.cookies.jwt;

    if (!token) {
        // If the request is from our script, send a JSON error, not a redirect
        if (req.headers['accept'] === 'application/json') {
            return res.status(401).json({ success: false, message: "Session expired" });
        }
        return res.redirect("/login");
    }

    try {
        const decoded = jwt.verify(token, process.env.JWT_SECRET);
        req.user = decoded;
        next();
    } catch (err) {
        return res.status(401).json({ success: false, message: "Invalid token" });
    }
}

app.use(cookie());
app.get("/dashboard", isAuthenticated, (req, res) => {
    res.render("dashboard", { user: req.user });
});

app.get("/logout", (req, res) => {
    res.clearCookie("jwt");
    res.redirect("/login");
});

app.get("/signup", (req,res) => {
    res.render("signup")
})


app.post("/register", (req, res) => {
    console.log(req.body);

    const first_name = req.body.fname;
    const last_name = req.body.lastname;
    const email = req.body.email;
    const password = req.body.password;
    const passwordConfirm = req.body.passwordConfirm;

    // check if email exists
    db.query('SELECT email FROM user WHERE email = ?', [email], async (error, result) => {

        if (error) {
            console.log(error);
            return res.render('signup', { message: 'Database error' });
        }

        if (result.length > 0) {
            return res.render('signup', {
                message: 'Email is already registered'
            });
        }

        if (password !== passwordConfirm) {
            return res.render('signup', {
                message: 'Password does not match'
            });
        }

        try {
            const hashedPassword = await bcrypt.hash(password, 9);

            db.query(
                'INSERT INTO user SET ?',
                {
                    first_name,
                    last_name,
                    email,
                    password: hashedPassword
                },
                (error, results) => {
                    if (error) {
                        console.log(error);
                        return res.render('signup', { message: 'Insert failed' });
                    }

                    return res.render('signup', {
                        message: 'Registration Complete'
                    });
                }
            );

        } catch (err) {
            console.log(err);
            return res.render('signup', { message: 'Hashing error' });
        }
    });
});


app.post("/generate-transaction", isAuthenticated, (req, res) => {
    const userId = req.user.id; 
    const amount = (Math.random() * 0.5).toFixed(8); 
    const types = ['BUY', 'SELL', 'DEPOSIT'];
    const type = types[Math.floor(Math.random() * types.length)];
    const currency = 'BTC';

    // 1. Get a connection from the pool
    db.getConnection((err, connection) => {
        if (err) {
            console.error("Error getting connection from pool:", err);
            return res.status(500).json({ success: false });
        }

        // 2. Start transaction on the CONNECTION, not the pool
        connection.beginTransaction((err) => {
            if (err) {
                connection.release(); // Always release connection back to pool
                return res.status(500).json({ success: false });
            }

            const query = "INSERT INTO user_transactions (user_id, amount, type, currency, status) VALUES (?, ?, ?, ?, ?)";
            const values = [userId, amount, type, currency, 'completed'];

            connection.query(query, values, (error, results) => {
                if (error) {
                    return connection.rollback(() => {
                        connection.release();
                        res.status(500).json({ success: false });
                    });
                }

                connection.commit((err) => {
                    if (err) {
                        return connection.rollback(() => {
                            connection.release();
                            res.status(500).json({ success: false });
                        });
                    }
                    
                    // 3. Success! Release connection and send response
                    connection.release();
                    res.json({ success: true, txId: results.insertId });
                });
            });
        });
    });
});



//app.post('/register', authController.register)

/**Encrypt password */
  
module.exports.handler = serverless(app);