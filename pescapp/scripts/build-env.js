const fs = require('fs');
const path = require('path');
require('dotenv').config();

const environmentFile = path.join(__dirname, '../web/environment.js');
let content = fs.readFileSync(environmentFile, 'utf8');

// Replace placeholders with actual environment variables
content = content.replace('%GOOGLE_MAPS_API_KEY%', process.env.GOOGLE_MAPS_API_KEY);

fs.writeFileSync(environmentFile, content); 