const crypto = require("node:crypto");
const {initializeApp} = require("firebase-admin/app");
const {getAuth} = require("firebase-admin/auth");
const {getFirestore, Timestamp} = require("firebase-admin/firestore");
const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {defineSecret} = require("firebase-functions/params");

initializeApp();

const adminLoginSecret = defineSecret("ADMIN_LOGIN_SECRET");
const adminUsername = "uwuict";
const adminUid = "ayurvediccare-admin-uwuict";
const isFunctionsEmulator = process.env.FUNCTIONS_EMULATOR === "true";
const maxAttempts = 5;
const attemptWindowMs = 15 * 60 * 1000;
const lockoutMs = 15 * 60 * 1000;

function constantTimeEquals(first, second) {
  const firstBuffer = Buffer.from(first, "utf8");
  const secondBuffer = Buffer.from(second, "utf8");
  return firstBuffer.length === secondBuffer.length &&
    crypto.timingSafeEqual(firstBuffer, secondBuffer);
}

function isValidSecret(suppliedSecret) {
  if (isFunctionsEmulator) {
    return constantTimeEquals(suppliedSecret, "00000");
  }

  const expectedSecret = adminLoginSecret.value();
  if (Buffer.byteLength(expectedSecret, "utf8") < 32) {
    throw new HttpsError(
        "failed-precondition",
        "Admin login secret is not configured securely.",
    );
  }
  return constantTimeEquals(suppliedSecret, expectedSecret);
}

function rateLimitDocument(ip) {
  const key = crypto.createHash("sha256").update(ip).digest("hex");
  return getFirestore().collection("adminLoginAttempts").doc(key);
}

async function assertNotLocked(reference) {
  const snapshot = await reference.get();
  const lockedUntil = snapshot.get("lockedUntil");
  if (lockedUntil instanceof Timestamp && lockedUntil.toMillis() > Date.now()) {
    throw new HttpsError(
        "resource-exhausted",
        "Too many attempts. Try again later.",
    );
  }
}

async function recordFailure(reference) {
  await getFirestore().runTransaction(async (transaction) => {
    const snapshot = await transaction.get(reference);
    const now = Date.now();
    const windowStart = snapshot.get("windowStart")?.toMillis() ?? 0;
    const previousAttempts = windowStart + attemptWindowMs > now ?
      snapshot.get("attempts") ?? 0 : 0;
    const attempts = previousAttempts + 1;
    transaction.set(reference, {
      attempts,
      windowStart: Timestamp.fromMillis(
          windowStart + attemptWindowMs > now ? windowStart : now,
      ),
      lockedUntil: attempts >= maxAttempts ?
        Timestamp.fromMillis(now + lockoutMs) : null,
    });
  });
}

async function getOrCreateAdminUser() {
  const auth = getAuth();
  let user;
  try {
    user = await auth.getUser(adminUid);
  } catch (error) {
    if (error.code !== "auth/user-not-found") throw error;
    user = await auth.createUser({
      uid: adminUid,
      displayName: adminUsername,
      disabled: false,
    });
  }

  if (user.customClaims?.admin !== true) {
    await auth.setCustomUserClaims(adminUid, {...user.customClaims, admin: true});
  }
  return auth.createCustomToken(adminUid, {admin: true});
}

exports.adminLogin = onCall(
    {
      region: "us-central1",
      secrets: isFunctionsEmulator ? [] : [adminLoginSecret],
    },
    async (request) => {
      const ip = request.rawRequest.ip || "unknown";
      const attemptsReference = rateLimitDocument(ip);
      await assertNotLocked(attemptsReference);

      const suppliedUsername =
        typeof request.data?.username === "string" ?
          request.data.username.trim() : "";
      const suppliedSecret =
        typeof request.data?.secret === "string" ?
          request.data.secret : "";

      const validCredentials =
        constantTimeEquals(suppliedUsername, adminUsername) &&
        isValidSecret(suppliedSecret);
      if (!validCredentials) {
        await recordFailure(attemptsReference);
        throw new HttpsError("unauthenticated", "Invalid admin credentials.");
      }

      await attemptsReference.delete();
      return {customToken: await getOrCreateAdminUser()};
    },
);
