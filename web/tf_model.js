// web/tf_model.js
let _modelPromise = null;

function loadPetModel() {
  if (!_modelPromise) {
    // If you converted a Keras model with tensorflowjs, this is a LayersModel
    _modelPromise = tf.loadLayersModel('web/web_model/model.json');
  }
  return _modelPromise;
}

// Helper: turn dataURL into a tensor of shape [1, 224, 224, 3] in [0,1]
async function dataUrlToTensor(dataUrl) {
  const img = new Image();
  img.src = dataUrl;
  await img.decode();

  const canvas = document.createElement('canvas');
  canvas.width = 224;
  canvas.height = 224;
  const ctx = canvas.getContext('2d');
  ctx.drawImage(img, 0, 0, 224, 224);

  // From pixels -> float32 tensor
  const t = tf.tidy(() => {
    const pixels = tf.browser.fromPixels(canvas);          // [224,224,3], uint8
    const float = pixels.toFloat().div(255.0);             // normalize 0..1
    return float.expandDims(0);                             // [1,224,224,3]
  });
  return t;
}

// Softmax + argmax
function topFromLogits(logits1D) {
  let topIdx = 0;
  let max = logits1D[0];
  for (let i = 1; i < logits1D.length; i++) {
    if (logits1D[i] > max) { max = logits1D[i]; topIdx = i; }
  }
  // softmax prob of the top class
  const emax = Math.exp(max);
  const denom = logits1D.reduce((s, v) => s + Math.exp(v), 0);
  return { topIndex: topIdx, topProb: denom ? (emax / denom) : 0.0 };
}

// Exposed to Dart
window.predictFromBase64 = async function (dataUrl) {
  const model = await loadPetModel();
  const input = await dataUrlToTensor(dataUrl);

  const out = tf.tidy(() => model.predict(input)); // logits tensor
  const logits = Array.from(await out.data());     // flatten to JS array
  tf.dispose([out, input]);

  const { topIndex, topProb } = topFromLogits(logits);
  return { topIndex, topProb };
};
