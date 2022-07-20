import * as tf from "@ohos/tfjs"
import router from '@system.router'
import * as train_x from "./../../../resources/base/media/train_x.json";
import * as train_y from "./../../../resources/base/media/train_y.json";
import * as test_x from "./../../../resources/base/media/test_x.json";
import * as test_y from "./../../../resources/base/media/test_y.json";

/* The Abalone Shell model is the model which predicts the number of rings a shell has given the physical
measurements of the abalone shell. The input consists of 10 data points such as length, diameter,
height, weight, etc. The model consists of two hidden layers both with 50 units, and one output layer
 with one unit.
The training and test data are stored in .json files in an array format which are present in the
resources , we import these array and convert it into a tensor. We'll then use these tensors to train model.
The training data consists of 3132 x 10 array and the test data consists of 1045 x 10 array.
After training the model by pressing train, we can check the mean square error (mse) of prediction
on test data. This values lets us know how well our model is doing the prediction. For 10 epochs,
the mse was ~ 7.25 and for 50 epoch the mse was 4.733. By increasing the epoch we can get better
prediction */

@Entry
@Component
struct Xor {
  @State message: string = 'Abalone Rings'

  @State error: string = 'Test Error: '
  @State model: tf.Sequential = tf.sequential();

  build() {
    Row() {
      Column() {
        Text(this.message)
          .fontSize(50)
          .fontWeight(FontWeight.Bold)
        Row() {
          Button("Train")
            .onClick(() => {
              const arr_x = JSON.parse(JSON.stringify(train_x));
              const arr_y = JSON.parse(JSON.stringify(train_y));
              // arr[1]
              var xt = []
              var yt = []
              for (let i = 0;i < 3132; i++) {
                xt[i] = [];
                yt[i] = arr_y[i];
                for (let j = 0;j < 10; j++) {
                  xt[i][j] = arr_x[i][j]
                }
              }
              var xtrain = tf.tensor(xt);
              var ytrain = tf.tensor(yt);
              this.model.add(tf.layers.dense({ units: 50, activation: 'sigmoid', inputShape: [10] }));
              this.model.add(tf.layers.dense({ units: 50, activation: 'sigmoid' }));
              this.model.add(tf.layers.dense({ units: 1 }));
              var learning_rate = 0.05
              this.model.compile({optimizer: tf.train.sgd(learning_rate),loss: 'meanSquaredError', metrics: ['acc'] }); //optimizer: tf.train.sgd(learning_rate)
              const history = this.model.fit(xtrain, ytrain, { epochs: 10, batchSize: 50,callbacks: tf.callbacks.earlyStopping({ monitor: "val_acc" }),})
              // Takes ~ 13 seconds per epoch
              console.log("fit is over")

            }).margin('25px')
          Button("Test") //Press to predict after training
            .onClick(() => {
              const arr_x = JSON.parse(JSON.stringify(test_x));
              const arr_y = JSON.parse(JSON.stringify(test_y));
              //              console.log(arr_x[10][0])
              var xt = []
              var yt = []
              for (let i = 0;i < 1045; i++) {
                yt[i] = [];
                yt[i][0] = arr_y[i];
                xt[i] = [];
                for (let j = 0;j < 10; j++) {
                  xt[i][j] = arr_x[i][j]
                }
              }

              var xtest = tf.tensor(xt);
              var ytest = tf.tensor(yt);
              const ypred = this.model.predict(xtest) as tf.Tensor;
              //              const values = ypred.dataSync();
              //              const arr = Array.from(values);
              var mse = tf.losses.meanSquaredError(ytest, ypred);
              const values = mse.dataSync();
              const arr = Array.from(values);
              this.error = 'Test Error: ' + arr[0].toFixed(3)
            }).margin('25px')
        }

        Text(this.error)
          .fontSize(25)
          .fontWeight(FontWeight.Bold)
        Button("Back")
          .onClick(() => {
            router.back();
          })
          .margin(40)
      }
      .width('100%')
    }
    .height('100%')
  }
}