const MODEL = process.env.GEMINI_MODEL || 'gemini-3.5-flash';

async function generateReply(history) {
  const url = `https://generativelanguage.googleapis.com/v1beta/models/${MODEL}:generateContent?key=${process.env.GEMINI_API_KEY}`;

  const response = await fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      systemInstruction: {
        parts: [{ text: 'You are a helpful, concise personal assistant inside a mobile app.' }]
      },
      contents: history.map((message) => ({
        role: message.role,
        parts: [{ text: message.content }]
      }))
    })
  });

  if (!response.ok) {
    const errorBody = await response.text();
    throw new Error(`Gemini request failed (${response.status}): ${errorBody}`);
  }

  const data = await response.json();
  const text = data.candidates?.[0]?.content?.parts?.map((part) => part.text).join('') ?? '';
  if (!text) {
    throw new Error('Gemini returned an empty response.');
  }
  return text;
}

module.exports = { generateReply };
