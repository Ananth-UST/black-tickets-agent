const requireAuth = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization || "";
    if (!authHeader.startsWith("Bearer ")) {
      return res.status(401).json({ message: "Missing token" });
    }

    const validateResponse = await fetch(
      `${process.env.IDENTITY_SERVICE_URL}/auth/validate`,
      {
        method: "GET",
        headers: { Authorization: authHeader }
      }
    );

    if (!validateResponse.ok) {
      return res.status(401).json({ message: "Invalid token" });
    }

    const data = await validateResponse.json();
    req.user = data.user;
    return next();
  } catch (error) {
    return next(error);
  }
};

const requireAdmin = (req, res, next) => {
  if (!req.user || req.user.role !== "admin") {
    return res.status(403).json({ message: "Admin role required" });
  }
  return next();
};

module.exports = { requireAuth, requireAdmin };
