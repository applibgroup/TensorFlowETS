import testNapi from "libhello.so"
import * as tf from "@ohos/tfjs"
import router from '@system.router'
// import * as tf from "@ohos/tfjs-js"
import { IMAGENET_CLASSES } from '../common/imagenet_classes';
import image from '@ohos.multimedia.image';
import resourceManager from '@ohos.resourceManager';

const MOBILENET_MODEL_PATH =
  // tslint:disable-next-line:max-line-length
  'https://tfhub.dev/google/tfjs-model/imagenet/mobilenet_v2_100_224/classification/3/default/1';

const IMAGE_SIZE = 224;
const TOPK_PREDICTIONS = 10;


let mobilenet;
const mobilenetDemo = async () => {
  console.info('Loading model...');

  // mobilenet = await tf.loadGraphModel(MOBILENET_MODEL_PATH, { fromTFHub: true });
  console.info('Loading model... mobilenet ' + mobilenet);

  // Warmup the model. This isn't necessary, but makes the first prediction
  // faster. Call `dispose` to release the WebGL memory allocated for the return
  // value of `predict`.
  mobilenet.predict(tf.zeros([1, IMAGE_SIZE, IMAGE_SIZE, 3])).dispose();

  console.info('warmup done...');

  // Make a prediction through the locally hosted cat.jpg.
  predict('');
};

const getResourceArray = async () => {
  console.info('getResourceArray...');

  let resArray: Uint8Array = await getResFromMedia();
};

const getResFromMedia = async (): Promise<Uint8Array> => {
  var res: Resource = $r("app.media.cat");
  let resId = res.id;
  let resType = res.type;
  let manager = await resourceManager.getResourceManager();
  let value = await manager.getMedia(resId).then(data => {
    // let arrayBuffer: ArrayBuffer = data.buffer.slice(data.byteOffset, data.byteLength + data.byteOffset);
    return data;
  }).catch(err => {
    console.info('Resource fetch error...');
    return null;
  })
  return value;
}

/**
 * Given an image element, makes a prediction through mobilenet returning the
 * probabilities of the top K classes.
 */
async function predict(imgElement) {
  console.info('Predicting...');

  // The first start time includes the time it takes to extract the image
  // from the HTML and preprocess it, in additon to the predict() call.
  const startTime1 = Date.now(); // performance.now();
  // The second start time excludes the extraction and preprocessing and
  // includes only the predict() call.
  let startTime2;
  var res: Resource = $r("app.media.cat");
  let resId = res.id;
  let resType = res.type;
  resourceManager.getResourceManager().then(result => {
    result.getMedia(resId).then(data => {
      let arrayBuffer: ArrayBuffer = data.buffer.slice(data.byteOffset, data.byteLength + data.byteOffset);
    }).catch(err => {
      console.info('Resource fetch error...');
    })
  })
  let resArray: Uint8Array = await getResFromMedia();

  const logits = tf.tidy(() => {
    // tf.browser.fromPixels() returns a Tensor from an image element.
    var pixelData
    pixelData.width = IMAGE_SIZE
    pixelData.height = IMAGE_SIZE
    pixelData.data = resArray
    const img = tf.cast(tf.browser.fromPixels(pixelData), 'float32');

    const offset = tf.scalar(127.5);
    // Normalize the image from [0, 255] to [-1, 1].
    /*const normalized = img.sub(offset).div(offset);

    // Reshape to a single-element batch so we can pass it to predict.
   const batched = normalized.reshape([1, IMAGE_SIZE, IMAGE_SIZE, 3]);

    startTime2 = Date.now(); // performance.now();
    // Make a prediction through mobilenet.
    return mobilenet.predict(batched);*/
  });

  // Convert logits to probabilities and class names.
  const classes = await getTopKClasses(logits, TOPK_PREDICTIONS);
  const totalTime1 = Date.now() - startTime1;
  const totalTime2 = Date.now() - startTime2;
  console.info(`Done in ${Math.floor(totalTime1)} ms ` +
  `(not including preprocessing: ${Math.floor(totalTime2)} ms)`);

  // Show the classes in the DOM.
  showResults(imgElement, classes);
}


/**
 * Computes the probabilities of the topK classes given logits by computing
 * softmax to get probabilities and then sorting the probabilities.
 * @param logits Tensor representing the logits from MobileNet.
 * @param topK The number of top predictions to show.
 */
export async function getTopKClasses(logits, topK) {
  const values = await logits.data();

  const valuesAndIndices = [];
  for (let i = 0; i < values.length; i++) {
    valuesAndIndices.push({ value: values[i], index: i });
  }
  valuesAndIndices.sort((a, b) => {
    return b.value - a.value;
  });
  const topkValues = new Float32Array(topK);
  const topkIndices = new Int32Array(topK);
  for (let i = 0; i < topK; i++) {
    topkValues[i] = valuesAndIndices[i].value;
    topkIndices[i] = valuesAndIndices[i].index;
  }

  const topClassesAndProbs = [];
  for (let i = 0; i < topkIndices.length; i++) {
    topClassesAndProbs.push({
      className: IMAGENET_CLASSES[topkIndices[i]],
      probability: topkValues[i]
    })
  }
  return topClassesAndProbs;
}

function showResults(imgElement, classes) {
  for (let i = 0; i < classes.length; i++) {
    console.info('showResults className' + classes[i].className);
    console.info('showResults className' + classes[i].probability.toFixed(3));
  }
}

@Entry
@Component
struct Index {
  @State message: string = 'Models'
  @State b: boolean = true

  build() {
    Row() {
      Column() {
        Text(this.message)
          .fontSize(50)
          .fontWeight(FontWeight.Bold)
        Button("XOR") // Predicts XOR
          .onClick(() => {
            router.push({ uri: 'pages/Xor' })
          }).margin('25px')
        Button("Color Contrast") // Predicts the text color given the background
          .onClick(()=>{
            router.push({ uri: 'pages/ColorContrast' })
        }).margin('25px')
        Button("Abalone Age") // Predicts the age of Abalone given the physical data
          .onClick(() => {
            router.push({ uri: 'pages/Abalone' })
          })
      }
      .width('100%')
    }
    .height('100%')
  }
}
