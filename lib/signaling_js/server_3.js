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
let userTargetDetailsCollection;
let clients = {};

client.connect().then(() => {
  console.log('Connected to MongoDB');
  const db = client.db('webrtc');
  usersCollection = db.collection('users');
  userContactsCollection = db.collection('user_contacts');
  callHistoryCollection = db.collection('call_history');
  sdpIceHistoryCollection = db.collection('sdp_ice_history');
  userTargetDetailsCollection = db.collection('user_target_details');
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
      case 'status_update':
        await handleStatusUpdate(data, ws);
        break;
      case 'initiate_call':
        await handleInitiateCall(data, ws);
        break;
      case 'add_target_user_details':
        await handleAddTargetUserDetails(data, ws);
        break;
      case 'get_target_user_details':
        await handleGetTargetUserDetails(data, ws);
        break;
      case 'sendNotification':
        await handleSendNotification(data, ws);
        break;
      case 'callAccepted':
        await handleCallAccepted(data, ws);
        break;
    }
  });

  ws.on('close', async () => {
    console.log('Client disconnected');
    for (let userId in clients) {
      if (clients[userId] === ws) {
        delete clients[userId];
        await usersCollection.updateOne({ _id: userId }, { $set: { status: 'offline' } });
        console.log(`User with mobile: ${userId} set to offline`);
        break;
      }
    }
  });
});



async function handleOffer(data, ws) {
  console.log(`Received offer from ${data.currentUserId} for ${data.targetUserId}`);
  if (clients[data.targetUserId]) {
    const callId = new ObjectId();
    await callHistoryCollection.insertOne({
      _id: callId,
      caller: data.currentUserId,
      callee: data.targetUserId,
      startTime: new Date(),
      status: 'ringing',
    });
    clients[data.targetUserId].send(JSON.stringify({ ...data, callId }));
    console.log(`Sent offer from ${data.currentUserId} to ${data.targetUserId}`);
  } else {
    console.log(`Target ${data.targetUserId} not found`);
  }
}

async function handleAnswer(data, ws) {
  console.log(`Received answer from ${data.currentUserId} for ${data.targetUserId}`);
  if (clients[data.targetUserId]) {
    clients[data.targetUserId].send(JSON.stringify(data));
    console.log(`Sent answer from ${data.currentUserId} to ${data.targetUserId}`);
    await callHistoryCollection.updateOne({ _id: ObjectId(data.callId) }, { $set: { status: 'connected' } });
  } else {
    console.log(`Target ${data.targetUserId} not found`);
  }
}

async function handleCandidate(data, ws) {
  console.log(`Received ICE candidate from ${data.currentUserId} for ${data.targetUserId}`);
  if (clients[data.targetUserId]) {
    clients[data.targetUserId].send(JSON.stringify(data));
    console.log(`Sent ICE candidate from ${data.currentUserId} to ${data.targetUserId}`);
    await sdpIceHistoryCollection.insertOne({
      callId: ObjectId.createFromHexString(data.targetUserId),
      currentUserId: data.currentUserId,
      iceCandidate: data.candidate,
      timestamp: new Date(),
    });
  } else {
    console.log(`Target ${data.targetUserId} not found`);
  }
}

async function handleDisconnect(data, ws) {
  console.log(`User ${data.currentUserId} disconnected from ${data.targetUserId}`);
  await callHistoryCollection.updateOne({ _id: ObjectId(data.callId) }, {
    $set: {
      endTime: new Date(),
      status: 'disconnected',
    }
  });
  if (clients[data.targetUserId]) {
    clients[data.targetUserId].send(JSON.stringify({ type: 'disconnect', from: data.currentUserId }));
  }
  await usersCollection.updateOne({ _id: data.currentUserId }, { $set: { status: 'offline' } });
}

async function handleCancel(data, ws) {
  console.log(`Call from ${data.currentUserId} to ${data.targetUserId} was canceled`);
  if (data.callId) {
    await callHistoryCollection.updateOne({ _id: ObjectId(data.callId) }, { $set: { status: 'canceled' } });
    if (clients[data.targetUserId]) {
      clients[data.targetUserId].send(JSON.stringify({ type: 'cancel', from: data.currentUserId }));
    }
  }
}

async function handleStatusUpdate(data, ws) {
  console.log(`Received status update from ${data.userId}: ${data.status}`);
  await usersCollection.updateOne({ _id: data.userId }, { $set: { status: data.status } });
  console.log(`User ${data.userId} status updated to ${data.status}`);
  clients[data.userId] = ws;
}

async function handleInitiateCall(data, ws) {
  console.log(`Initiating call from ${data.currentUserId} to ${data.targetUserId}`);
  if (clients[data.targetUserId]) {
    const callId = new ObjectId();
    await callHistoryCollection.insertOne({
      _id: callId,
      caller: data.currentUserId,
      callee: data.targetUserId,
      startTime: new Date(),
      status: 'initiated',
    });
    clients[data.targetUserId].send(JSON.stringify({ type: 'incoming_call', from: data.currentUserId, callId }));
    console.log(`Sent call initiation from ${data.currentUserId} to ${data.targetUserId}`);
  } else {
    console.log(`Target ${data.targetUserId} not found or offline`);
    ws.send(JSON.stringify({ type: 'call_failed', reason: 'Target user not found or offline' }));
  }
}
async function handleAddTargetUserDetails(data, ws) {
  try {
    // Find the target user by mobile number
    const targetUser = await usersCollection.findOne({ mobile: data.targetUserMobile });

    if (targetUser) {
      // Insert the target user details into the collection
      const response = await userTargetDetailsCollection.insertOne({
        currentUserId: data.currentUserId,
        targetUserId: targetUser._id, // Use the found targetUserId
        targetUserName: data.targetUserName,
        targetUserMobile: data.targetUserMobile,
        timestamp: new Date(),
      });

      const savedDetails = await userTargetDetailsCollection.findOne({ _id: response.insertedId })

      console.log("Added Target Details", savedDetails);

      // const savedDetails = result.ops[0]; // The saved document

      // Send success response with the saved details
      ws.send(JSON.stringify({
        type: 'target_user_details_added',
        success: true,
        details: savedDetails,
      }));

      console.log(`Target user details added for currentUserId: ${data.currentUserId}`);
    } else {
      // If the target user is not found, send a failure response
      ws.send(JSON.stringify({
        type: 'target_user_details_added',
        success: false,
        message: 'Target user not found',
      }));

      console.log(`Target user not found for mobile number: ${data.targetUserMobile}`);
    }
  } catch (error) {
    console.error('Error adding target user details:', error);

    // Send error response
    ws.send(JSON.stringify({
      type: 'target_user_details_added',
      success: false,
      error: error.message,
    }));
  }
}


async function handleGetTargetUserDetails(data, ws) {
  try {
    const details = await userTargetDetailsCollection.findOne({
      currentUserId: data.currentUserId,
      targetUserId: data.targetUserId,
    });

    if (details) {
      ws.send(JSON.stringify({
        type: 'target_user_details',
        success: true,
        details,
      }));
      console.log(`Retrieved target user details for currentUserId: ${data.currentUserId}`);
    } else {
      ws.send(JSON.stringify({
        type: 'target_user_details',
        success: false,
        message: 'Details not found',
      }));
    }
  } catch (error) {
    console.error('Error retrieving target user details:', error);
    ws.send(JSON.stringify({
      type: 'target_user_details',
      success: false,
      error: error.message,
    }));
  }
}

async function handleSendNotification(data, ws) {
  console.log("notificationData ->", data);
  const id = ObjectId.createFromHexString(data.toUser);
  let response = await usersCollection.findOne({ _id: id });
  console.log('targetDetails', response);
  if (response) {
    // clients[response.mobile].send(JSON.stringify(data));
    console.log("Sending notification to target user");

    clients[data.toUser].send(JSON.stringify({
      type: 'receiveNotification',
      toUser: data.toUser,
      fromUser: data.fromUser,
    }));
  }
}

async function handleCallAccepted(data, ws) {
  console.log("call accepted");
  clients[data.fromUser].send(JSON.stringify({
    type: 'callAccepted',
    toUser: data.toUser,
    fromUser: data.fromUser,
  }));
}

app.get('/', (req, res) => {
  res.send('WebRTC Signaling Server');
});

server.listen(3000, () => {
  console.log('Signaling Server is listening on port 3000');
});
