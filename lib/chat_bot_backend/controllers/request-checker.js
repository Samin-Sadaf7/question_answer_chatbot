const checkRequest = (req, res) => {
    const { param } = req.params;
    const { message } = req.body;
  
    if (!message) {
      return res.status(400).json({ error: 'Invalid JSON' });
    }
  
    res.json({ response: `Received: ${message} with URL param: ${param}` });
  };

  module.exports = { checkRequest};