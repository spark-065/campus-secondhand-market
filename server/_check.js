const mysql = require('mysql2/promise');
(async () => {
  const c = await mysql.createConnection({host:'localhost',port:3306,user:'root',password:'',database:'shop_db'});
  const [r] = await c.query('SHOW TABLES');
  console.log('Tables:', r.map(x => Object.values(x)[0]).join(', '));
  try {
    const [cols] = await c.query('SHOW COLUMNS FROM goods');
    console.log('goods columns:', cols.map(x => x.Field).join(', '));
  } catch(e) { console.log('no goods table'); }
  await c.end();
})();