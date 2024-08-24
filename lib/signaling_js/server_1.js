require('dotenv').config();
const express = require('express');
const http = require('http');
const WebSocket = require('ws');
const { MongoClient, ObjectId } = require('mongodb');

const app = express();
const server = http.createServer(app);
const wss = new WebSocket.Server({ server });

const uri = process.env.MONGODB_URI || 'mongodb://localhost:27017/';
const client = new MongoClient(uri);

let usersCollection;
let userContactsCollection;
let callHistoryCollection;
let sdpIceHistoryCollection;
let clients = {};

client.connect().then(() => {
  console.log('Connected to MongoDB');
  const db = client.db('webrtc');
  usersCollection = db.collection('users');
  userContactsCollection = db.collection('user_contacts');
  callHistoryCollection = db.collection('call_history');
  sdpIceHistoryCollection = db.collection('sdp_ice_history');
}).catch(err => console.error('MongoDB connection error:', err));

wss.on('connection', (ws) => {
  console.log('New client connected');

  ws.on('message', async (message) => {
    const data = JSON.parse(message);
    switch (data.type) {
      case 'register':
        await handleRegister(data, ws);
        break;
      case 'offer':
        await handleOffer(data, ws);
        break;
      case 'answer':
        await handleAnswer(data, ws);
        break;
      case 'candidate':
        await handleCandidate(data, ws);
        break;
      case 'disconnect':
        await handleDisconnect(data, ws);
        break;
      case 'cancel':
        await handleCancel(data, ws);
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

async function handleRegister(data, ws) {
  const existingUser = await usersCollection.findOne({ mobile: data.mobile });
  if (!existingUser) {
    await usersCollection.insertOne({
      mobile: data.mobile,
      status: 'online',
      registeredAt: new Date(),
    });
    const result = await usersCollection.insertOne({
      mobile: data.mobile,
      status: 'online',
      registeredAt: new Date(),
    });
    const userId = result.insertedId;
    ws.send(JSON.stringify({ type: 'registered', success: true, userId }));
    console.log(`User registered with mobile: ${data.mobile}`);
  } else {
    const userId = existingUser._id;
    await usersCollection.updateOne({ mobile: data.mobile }, { $set: { status: 'online' } });
    ws.send(JSON.stringify({ type: 'registered', success: true, userId }));
    console.log(`User authenticated and set to online: ${data.mobile}, ID: ${userId}`);
  }
  clients[data.mobile] = ws;
}

async function handleOffer(data, ws) {
  console.log(`Received offer from ${data.mobile} for ${data.targetMobile}`);
  if (clients[data.targetMobile]) {
    const callId = new ObjectId();
    await callHistoryCollection.insertOne({
      _id: callId,
      caller: data.mobile,
      callee: data.targetMobile,
      startTime: new Date(),
      status: 'ringing',
    });
    clients[data.targetMobile].send(JSON.stringify({ ...data, callId }));
    console.log(`Sent offer from ${data.mobile} to ${data.targetMobile}`);
  } else {
    console.log(`Target ${data.targetMobile} not found`);
  }
}

async function handleAnswer(data, ws) {
  console.log(`Received answer from ${data.mobile} for ${data.targetMobile}`);
  if (clients[data.targetMobile]) {
    clients[data.targetMobile].send(JSON.stringify(data));
    console.log(`Sent answer from ${data.mobile} to ${data.targetMobile}`);
    await callHistoryCollection.updateOne({ _id: ObjectId(data.callId) }, { $set: { status: 'connected' } });
  } else {
    console.log(`Target ${data.targetMobile} not found`);
  }
}

async function handleCandidate(data, ws) {
  console.log(`Received ICE candidate from ${data.mobile} for ${data.targetMobile}`);
  if (clients[data.targetMobile]) {
    clients[data.targetMobile].send(JSON.stringify(data));
    console.log(`Sent ICE candidate from ${data.mobile} to ${data.targetMobile}`);
    await sdpIceHistoryCollection.insertOne({
      callId: ObjectId(data.callId),
      mobile: data.mobile,
      iceCandidate: data.candidate,
      timestamp: new Date(),
    });
  } else {
    console.log(`Target ${data.targetMobile} not found`);
  }
}

async function handleDisconnect(data, ws) {
  console.log(`User ${data.mobile} disconnected from ${data.targetMobile}`);
  await callHistoryCollection.updateOne({ _id: ObjectId(data.callId) }, {
    $set: {
      endTime: new Date(),
      status: 'disconnected',
    }
  });
  if (clients[data.targetMobile]) {
    clients[data.targetMobile].send(JSON.stringify({ type: 'disconnect', from: data.mobile }));
  }
  await usersCollection.updateOne({ mobile: data.mobile }, { $set: { status: 'offline' } });
}

async function handleCancel(data, ws) {
  console.log(`Call from ${data.mobile} to ${data.targetMobile} was canceled`);
  if (data.callId) {
    await callHistoryCollection.updateOne({ _id: ObjectId(data.callId) }, { $set: { status: 'canceled' } });
    if (clients[data.targetMobile]) {
      clients[data.targetMobile].send(JSON.stringify({ type: 'cancel', from: data.mobile }));
    }
  }
}

app.get('/', (req, res) => {
  res.send('WebRTC Signaling Server');
});

server.listen(3000, () => {
  console.log('Signaling Server is listening on port 3000');
});
