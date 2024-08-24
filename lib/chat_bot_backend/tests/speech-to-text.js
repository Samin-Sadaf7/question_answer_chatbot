const request = require('supertest');
const express = require('express');
const fs = require('fs');
const path = require('path');
const app = require('../server.js'); 

describe('POST /audio/transcribe', () => {
  it('should transcribe an audio file', async () => {
    const audioFilePath = path.join(__dirname, 'Batman created by Bo.mp3');
    fs.writeFileSync(audioFilePath, 'Batman, created by Bob Kane and Bill Finger, first appeared in 1939.\
                                     Bruce Wayne, a wealthy Gotham City\
                                     philanthropist, becomes Batman after witnessing his parents\
                                     murder. Unlike many superheroes, Batman has no superpowers;\
                                     he relies on his intellect, detective skills, and advanced \
                                     technology. His iconic gadgets include the Batmobile and Batsuit.\
                                     Key allies include Alfred Pennyworth and Commissioner Gordon,\
                                     while his adversaries feature notable villains like the Joker and \
                                     Catwoman. Batman\'s stories delve into themes of justice and vengeance,\
                                     and he remains one of the most enduring and popular superheroes in comic\
                                     book history.');

    const response = await request(app)
      .post('/audio/transcribe')
      .attach('audio', audioFilePath) 
      .expect(200); 

    fs.unlinkSync(audioFilePath);

    expect(response.body).toHaveProperty('success', true);
    expect(response.body).toHaveProperty('transcription');
  });

});
