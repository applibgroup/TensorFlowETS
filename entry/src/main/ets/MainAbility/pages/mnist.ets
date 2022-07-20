import * as tf from "@ohos/tfjs"
import router from '@system.router'

import * as train_x from "./../../../resources/base/media/mnist_train_features.json";
import * as train_y from "./../../../resources/base/media/mnist_train_targets.json";
import * as test_x from "./../../../resources/base/media/mnist_test_features.json";
import * as test_y from "./../../../resources/base/media/mnist_test_targets.json";
/* These json files are generated using mnist dataset in Google colab
   In the link
   https://colab.research.google.com/drive/1WuOygFjyp8K-r8PP1pvdCGdpSg9X7fTe?usp=sharing*/

let model = tf.sequential();

@Entry
@Component
struct Xor {
  @State message: string = 'Mnist'
  @State error: string = 'Test Error: '
  build() {
    Row() {
      Column() {
        Text(this.message)
          .fontSize(50)
          .fontWeight(FontWeight.Bold)
        Row(){
          Button("Train")
            .onClick(async() => {
              const arr_x = JSON.parse(JSON.stringify(train_x));
              const arr_y = JSON.parse(JSON.stringify(train_y));
              // arr[1]
              var xt = []
              var yt = []
              // Traning dataset has 100 images of size (28x28)
              for(let i=0;i<100;i++){
                xt[i] = [];
                yt[i] = arr_y[i];
                for(let j=0;j<28;j++){
                  xt[i][j] = [];
                  for(let k=0; k<28; k++){
                    xt[i][j][k] = [];
                    for(let l=0; l<1; l++){
                      xt[i][j][k][l] = arr_x[i][j][k][l]
                    }
                  }
                }
              }
              var xtrain = tf.tensor(xt);
              var ytrain = tf.tensor(yt);

              // input is a 28x28 pixels image
              // 32 is the number of filters - (3,3) size of the filter
              model.add(tf.layers.conv2d({ filters: 32, kernelSize: [3,3], inputShape: [28, 28, 1]}));
              model.add(tf.layers.reLU());
              // normalizes the activations in the previous layer after the convolutional phase
              // transformation maintains the mean activation close to 0 std close to 1
              // the scale of each dimension remains the same
              // reduces running-time of training significantly
              model.add(tf.layers.batchNormalization());
              model.add(tf.layers.conv2d({ filters: 32, kernelSize: [3,3] }))
              model.add(tf.layers.reLU());
              model.add(tf.layers.maxPooling2d({ poolSize: [2,2] }))
              model.add(tf.layers.batchNormalization());
              model.add(tf.layers.conv2d({ filters: 64, kernelSize: [3,3] }))
              model.add(tf.layers.reLU());
              model.add(tf.layers.batchNormalization());
              model.add(tf.layers.conv2d({ filters: 64, kernelSize: [3,3] }))
              model.add(tf.layers.reLU());
              model.add(tf.layers.maxPooling2d({ poolSize: [2,2] }))
              model.add(tf.layers.flatten())
              model.add(tf.layers.batchNormalization())
              model.add(tf.layers.dense({ units: 512 }))
              model.add(tf.layers.reLU());
              model.add(tf.layers.batchNormalization())
              // regularization helps to avoid over-fitting
              //model.add(tf.layers.dropout({ rate: 0.3 }))
              model.add(tf.layers.dense({ units: 10, activation: 'softmax' }))
              model.compile({optimizer: tf.train.adam(),loss: 'categoricalCrossentropy', metrics: ['accuracy'] })
              console. log("model fitting started")
              const start = Date.now();
              try {
                const history = await model.fit(xtrain, ytrain, {
                  batchSize: 128,
                  epochs: 5,
                  callbacks: tf.callbacks.earlyStopping({ monitor: "val_acc" }),
                  verbose: 1 })
              } catch(err) {
                console.log("Error: " + err)
              }
              // The model takes around 11 hours to train in DevEco Studio
              // for 100 images of size 28x28 of MNIST Dataset
              const duration = Date.now() - start;
              console.log("Time taken: "+ (duration/1000).toString() + "seconds")
              console.log("fit is over")

            }).margin('25px')
          Button("Test")//Press to Test after training
            .onClick(() => {
              const arr_x = JSON.parse(JSON.stringify(test_x));
              const arr_y = JSON.parse(JSON.stringify(test_y));

              var xt = []
              var yt = []
              // Testing dataset has 10 images of size (28x28)
              for(let i=0;i<10;i++){
                xt[i] = [];
                yt[i] = arr_y[i];
                for(let j=0;j<28;j++){
                  xt[i][j] = [];
                  for(let k=0; k<28; k++){
                    xt[i][j][k] = [];
                    for(let l=0; l<1; l++){
                      xt[i][j][k][l] = arr_x[i][j][k][l]
                    }
                  }
                }
              }

              var xtest = tf.tensor(xt);
              var ytest = tf.tensor(yt);
              const ypred = model.predict(xtest) as tf.Tensor;
              var mse =  tf.losses.absoluteDifference(ytest,ypred);
              const val = mse.dataSync()
              const arr = Array.from(val);
              console.log("loss is: " + arr.toString());

              this.error = 'Test Loss: '+ arr[0].toFixed(3)

            }).margin('25px')
        }
        Text(this.error)
          .fontSize(25)
          .fontWeight(FontWeight.Bold)
        Button("Back")
          .onClick(()=>{
            router.back();
          })
          .margin(40)
      }
      .width('100%')
    }
    .height('100%')
  }
}