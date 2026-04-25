import axios from "axios";

const IDENTITY_URL =
  import.meta.env.VITE_IDENTITY_SERVICE_URL || "http://localhost:4001";
const EVENT_URL = import.meta.env.VITE_EVENT_SERVICE_URL || "http://localhost:4002";
const BOOKING_URL =
  import.meta.env.VITE_BOOKING_SERVICE_URL || "http://localhost:4003";
const CHATBOT_URL =
  import.meta.env.VITE_CHATBOT_SERVICE_URL || "http://localhost:4004";

export const identityApi = axios.create({
  baseURL: IDENTITY_URL
});

export const eventApi = axios.create({
  baseURL: EVENT_URL
});

export const bookingApi = axios.create({
  baseURL: BOOKING_URL
});

export const chatbotApi = axios.create({
  baseURL: CHATBOT_URL
});

export const setAuthToken = (token) => {
  const header = token ? `Bearer ${token}` : "";
  identityApi.defaults.headers.common.Authorization = header;
  bookingApi.defaults.headers.common.Authorization = header;
  eventApi.defaults.headers.common.Authorization = header;
};
