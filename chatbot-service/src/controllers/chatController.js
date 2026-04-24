const { fetchEventById } = require("../services/eventClient");
const { buildReply } = require("../services/chatService");

const chat = async (req, res, next) => {
  try {
    const { message, eventId } = req.body;
    const parsedEventId = Number(eventId);

    if (!message || !parsedEventId) {
      return res.status(400).json({ message: "message and valid eventId are required" });
    }

    const event = await fetchEventById(parsedEventId);
    const reply = buildReply(String(message), event);

    return res.json({ reply });
  } catch (error) {
    if (error.type === "EVENT_NOT_FOUND") {
      return res.status(404).json({ message: "Event not found" });
    }
    if (error.type === "EVENT_SERVICE_UNAVAILABLE") {
      return res.status(503).json({ message: "Event service is unavailable" });
    }
    return next(error);
  }
};

module.exports = { chat };
