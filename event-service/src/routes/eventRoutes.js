const express = require("express");
const { create, list, detail, reserve } = require("../controllers/eventController");
const { requireAuth, requireAdmin, requireServiceToken } = require("../middleware/authMiddleware");

const router = express.Router();

router.get("/", list);
router.get("/:id", detail);
router.post("/", requireAuth, requireAdmin, create);

// Internal endpoint used by booking-service to reserve seats.
router.post("/:id/reserve", requireServiceToken, reserve);

module.exports = router;
