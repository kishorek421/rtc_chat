require('dotenv').config();
const express = require('express');
const http = require('http');
const WebSocket = require('ws');
const { MongoClient } = require('mongodb');

const app = express();
const server = http.createServer(app);
const wss = new WebSocket.Server({ server });

const uri = process.env.MONGODB_URI || 'mongodb://localhost:27017/';
const client = new MongoClient(uri);

let usersCollection;
let auditCollection;
let clients = {};

client.connect().then(() => {
  console.log('Connected to MongoDB');
  const db = client.db('webrtc');
  usersCollection = db.collection('users');
  auditCollection = db.collection('audit');
}).catch(err => console.error('MongoDB connection error:', err));

wss.on('connection', (ws) => {
  console.log('New client connected');

  ws.on('message', async (message) => {
    const data = JSON.parse(message);
    switch (data.type) {
      case 'register':
        const existingUser = await usersCollection.findOne({ mobile: data.mobile });
        if (!existingUser) {
          await usersCollection.insertOne({
            mobile: data.mobile,
            status: 'online',
            registeredAt: new Date(),
          });
          ws.send(JSON.stringify({ type: 'registered', success: true }));
          console.log(`User registered with mobile: ${data.mobile}`);
        } else {
          await usersCollection.updateOne({ mobile: data.mobile }, { $set: { status: 'online' } });
          console.log(`User authenticated and set to online: ${data.mobile}`);
        }
        break;
      case 'offer':
        handleOffer(data, ws);
        break;
      case 'answer':
        handleAnswer(data, ws);
        break;
      case 'candidate':
        handleCandidate(data, ws);
        break;
      case 'disconnect':
        handleDisconnect(data, ws);
        break;
    }
  });

  ws.on('close', async () => {
    console.log('Client disconnected');
    for (let mobile in clients) {
      if (clients[mobile] === ws) {
        delete clients[mobile];
        await usersCollection.updateOne({ mobile }, { $set: { status: 'offline' } });
        console.log(`User with mobile: ${mobile} set to offline`);
        break;
      }
    }
  });
});

async function handleOffer(data, ws) {
  console.log(`Received offer from ${data.mobile} for ${data.targetMobile}`);
  if (clients[data.targetMobile]) {
    clients[data.targetMobile].send(JSON.stringify(data));
    console.log(`Sent offer from ${data.mobile} to ${data.targetMobile}`);

    await auditCollection.insertOne({
      type: 'offer',
      from: data.mobile,
      to: data.targetMobile,
      timestamp: new Date(),
    });
  } else {
    console.log(`Target ${data.targetMobile} not found`);
  }
}

async function handleAnswer(data, ws) {
  console.log(`Received answer from ${data.mobile} for ${data.targetMobile}`);
  if (clients[data.targetMobile]) {
    clients[data.targetMobile].send(JSON.stringify(data));
    console.log(`Sent answer from ${data.mobile} to ${data.targetMobile}`);

    await auditCollection.insertOne({
      type: 'answer',
      from: data.mobile,
      to: data.targetMobile,
      timestamp: new Date(),
    });
  } else {
    console.log(`Target ${data.targetMobile} not found`);
  }
}

async function handleCandidate(data, ws) {
  console.log(`Received ICE candidate from ${data.mobile} for ${data.targetMobile}`);
  if (clients[data.targetMobile]) {
    clients[data.targetMobile].send(JSON.stringify(data));
    console.log(`Sent ICE candidate from ${data.mobile} to ${data.targetMobile}`);

    await auditCollection.insertOne({
      type: 'candidate',
      from: data.mobile,
      to: data.targetMobile,
      timestamp: new Date(),
    });
  } else {
    console.log(`Target ${data.targetMobile} not found`);
  }
}

async function handleDisconnect(data, ws) {
  console.log(`User ${data.mobile} disconnected from ${data.targetMobile}`);
  if (clients[data.targetMobile]) {
    clients[data.targetMobile].send(JSON.stringify({ type: 'disconnect', from: data.mobile }));
    await auditCollection.insertOne({
      type: 'disconnect',
      from: data.mobile,
      to: data.targetMobile,
      timestamp: new Date(),
    });
  }
  await usersCollection.updateOne({ mobile: data.mobile }, { $set: { status: 'offline' } });
}

app.get('/', (req, res) => {
  res.send('WebRTC Signaling Server');
});

server.listen(3000, () => {
  console.log('Signaling Server is listening on port 3000');
});
