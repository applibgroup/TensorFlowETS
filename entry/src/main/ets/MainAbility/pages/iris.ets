import * as tf from "@ohos/tfjs"
import router from '@system.router'
import { IRIS_CLASSES,IRIS_NUM_CLASSES,IRIS_DATA } from '../common/iris_data';

let model = tf.sequential();

function convertToTensors(data, targets, testSplit) {
  const numExamples = data.length;
  if (numExamples !== targets.length) {
    throw new Error('data and split have different numbers of examples');
  }

  // Randomly shuffle `data` and `targets`.
  const indices = [];
  for (let i = 0; i < numExamples; ++i) {
    indices.push(i);
  }
  tf.util.shuffle(indices);

  const shuffledData = [];
  const shuffledTargets = [];
  for (let i = 0; i < numExamples; ++i) {
    shuffledData.push(data[indices[i]]);
    shuffledTargets.push(targets[indices[i]]);
  }

  // Split the data into a training set and a tet set, based on `testSplit`.
  const numTestExamples = Math.round(numExamples * testSplit);
  const numTrainExamples = numExamples - numTestExamples;

  const xDims = shuffledData[0].length;

  // Create a 2D `tf.Tensor` to hold the feature data.
  const xs = tf.tensor2d(shuffledData, [numExamples, xDims]);

  // Create a 1D `tf.Tensor` to hold the labels, and convert the number label
  // from the set {0, 1, 2} into one-hot encoding (.e.g., 0 --> [1, 0, 0]).
  const ys = tf.oneHot(tf.tensor1d(shuffledTargets).dataSync(), IRIS_NUM_CLASSES);

  // Split the data into training and test sets, using `slice`.
  const xTrain = tf.slice(xs,[0, 0], [numTrainExamples, xDims]);
  const xTest = tf.slice(xs,[numTrainExamples, 0], [numTestExamples, xDims]);
  const yTrain = tf.slice(ys,[0, 0], [numTrainExamples, IRIS_NUM_CLASSES]);
  const yTest = tf.slice(ys,[0, 0], [numTestExamples, IRIS_NUM_CLASSES]);
  return [xTrain, yTrain, xTest, yTest];
}

function getIrisData(testSplit) {
  return tf.tidy(() => {
    const dataByClass = [];
    const targetsByClass = [];
    for (let i = 0; i < IRIS_CLASSES.length; ++i) {
      dataByClass.push([]);
      targetsByClass.push([]);
    }
    for (const example of IRIS_DATA) {
      const target = example[example.length - 1];
      const data = example.slice(0, example.length - 1);
      dataByClass[target].push(data);
      targetsByClass[target].push(target);
    }

    const xTrains = [];
    const yTrains = [];
    const xTests = [];
    const yTests = [];
    for (let i = 0; i < IRIS_CLASSES.length; ++i) {
      const [xTrain, yTrain, xTest, yTest] =
      convertToTensors(dataByClass[i], targetsByClass[i], testSplit);
      xTrains.push(xTrain);
      yTrains.push(yTrain);
      xTests.push(xTest);
      yTests.push(yTest);
    }

    const concatAxis = 0;
    return [
      tf.concat(xTrains, concatAxis), tf.concat(yTrains, concatAxis),
      tf.concat(xTests, concatAxis), tf.concat(yTests, concatAxis)
    ];
  });
}

async function train(xTrain, yTrain, xTest, yTest){
  console.log("Training Started")
  model.add(tf.layers.dense({ units: 10, activation: 'relu', inputShape: [xTrain.shape[1]]}));
  model.add(tf.layers.dense({ units: 10, activation: 'relu'}));
  model.add(tf.layers.dense({ units: 3, activation: 'softmax' }));
  model.compile({optimizer: tf.train.adam(0.05), loss: 'categoricalCrossentropy', metrics: ['accuracy'],});
  const history = await model.fit(xTrain, yTrain, {epochs: 50, validationData: [xTest, yTest],}).then(info => {
 console.log('Train accuracy: '+String(info.history['acc']));console.log('Val accuracy: '+String(info.history['val_acc']))});
  console.log("Training complete")
}

@Entry
@Component
struct Iris {
  @State message: string = 'IRIS Model'
  @State input: string = 'Input'
  @State output: string = 'Output'
  build() {
    Row() {
      Column() {
        Text(this.message)
          .fontSize(50)
          .fontWeight(FontWeight.Bold)
        Row() {
          Button("Train")
            .onClick(() => {
              const [xTrain, yTrain, xTest, yTest] = getIrisData(0.15);
              train(xTrain, yTrain, xTest, yTest)
              const ytp = model.predict(xTrain) as tf.Tensor;
              const yvp = model.predict(xTest) as tf.Tensor;
              const train_res = tf.losses.absoluteDifference(yTrain, ytp);
              const val_res = tf.losses.absoluteDifference(yTest, yvp);
              this.input =  "train_loss: " + train_res.dataSync();
              this.output = "val_loss: " + val_res.dataSync();
            }).margin('5px')
          Button("Predict")//Press to predict after training
            .onClick(() => {
              console.log("Predict")
              const inputData = [6, 3, 5, 2];
              const input = tf.tensor2d([inputData], [1, 4]);

              // Call `model.predict` to get the prediction output as probabilities for
              // the Iris flower categories.

              const predictOut = model.predict(input) as tf.Tensor;
              const winner = IRIS_CLASSES[tf.argMax(predictOut,-1).dataSync()[0]];
              this.input =  "Input: [6, 3, 5, 2]"
              this.output = "Output: "+ winner;
            }).margin('25px')
        }
        Text(this.input)
          .fontSize(20)
          .fontWeight(FontWeight.Normal)
        Text(this.output)
          .fontSize(20)
          .fontWeight(FontWeight.Normal)
        Button("Back")
          .onClick(()=>{
            console.log("back")
            router.back();
          })
          .margin(40)
      }
      .width('100%')
    }
    .height('100%')
  }
}
