const express = require('express');
const { S3 } = require('@aws-sdk/client-s3');
const { Pool } = require('pg');
const fs = require('fs').promises; 
const path = require('path');

const app = express();




const pool = new Pool({
    user: 'peertube',
    host: 'localhost',
    database: 'visitors',
    password: 'POSTGRESQL_DB_PASSWORD',
    port: 5432,
  });



// Configure AWS SDK for JavaScript v3
const s3 = new S3({
    credentials: {
        accessKeyId: 'STORJ_KEY_ID',
        secretAccessKey: 'STORJ_ACCESS_KEY'
    },
    endpoint: 'https://gateway.storjshare.io',
    s3ForcePathStyle: true,
    signatureVersion: 'v4',
    region: 'global'
});



const CACHE_DIR = '/tmp/peertube-cache'; // Define the cache directory
const MAX_CACHE_AGE_HOURS = 24; // Change this to your desired cache age limit

async function cleanUpCache() {
    try {
        const files = await fs.readdir(CACHE_DIR);
        const currentTime = new Date();

        for (const file of files) {
            const filePath = path.join(CACHE_DIR, file);
            const fileStats = await fs.stat(filePath);
            const fileAgeHours = (currentTime - fileStats.mtime) / (1000 * 60 * 60);

            if (fileAgeHours > MAX_CACHE_AGE_HOURS) {
                console.log(`Deleting old cache file: ${file}`);
                await fs.unlink(filePath);
            }
        }
    } catch (error) {
        console.error('Error cleaning up cache:', error);
    }
}



// Function to check if a file exists in the cache
async function isFileInCache(filePath) {
    try {
        await fs.access(filePath);
        return true;
    } catch {
        return false;
    }
}

// Function to fetch file from S3 and save to cache
async function fetchAndCacheFile(fileName, filePath) {
    try {
        const data = await s3.getObject({ Bucket: 'web-videos', Key: fileName });
        await fs.writeFile(filePath, data.Body);
        return data.Body;
    } catch (error) {
        console.error('Error fetching file from S3:', error);
        throw new Error('File not found in S3');
    }
}


async function getPopularVideos() {
    const result = await pool.query(`
        SELECT file_name, COUNT(*) as request_count
        FROM video_requests
        WHERE request_time > NOW() - INTERVAL '1 week'
        GROUP BY file_name
        ORDER BY request_count DESC
        LIMIT 10;
    `);
    return result.rows;
}


// Schedule cache clean-up
setInterval(cleanUpCache, 60 * 60 * 1000); // Every hour
cleanUpCache().catch(console.error); // Also run on server start


app.get('*.mp4', async (req, res) => {
    const fileName = req.path.substring(1);
    const filePath = path.join(CACHE_DIR, fileName);

    // Log request in the database
    try {
        await pool.query('INSERT INTO video_requests (file_name) VALUES ($1)', [fileName]);
    } catch (dbError) {
        console.error('Database error:', dbError);
    }

    try {
        if (await isFileInCache(filePath)) {
            console.log('file from cache');
            res.sendFile(filePath);
        } else {
            await fetchAndCacheFile(fileName, filePath);
            res.sendFile(filePath);
        }
    } catch (error) {
        res.status(404).send('File not found');
    }
});


app.all('*', (req, res) => {
    res.status(403).send('Forbidden');
});



app.listen(3000, () => {
    console.log('Server is running on port 3000');
});
