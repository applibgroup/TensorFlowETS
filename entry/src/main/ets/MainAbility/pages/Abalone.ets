import * as tf from "@ohos/tfjs"
import router from '@system.router'

import * as train_x from "./../../../resources/base/media/train_x.json";
import * as train_y from "./../../../resources/base/media/train_y.json";
import * as test_x from "./../../../resources/base/media/test_x.json";
import * as test_y from "./../../../resources/base/media/test_y.json";

@Entry
@Component
struct Xor {
  @State message: string = 'Color Contrast'

  @State error: string = 'Test Error: '
  @State model: tf.Sequential = tf.sequential();
  build() {
    Row() {
      Column() {
        Text(this.message)
          .fontSize(50)
          .fontWeight(FontWeight.Bold)
        Row(){
          Button("Train")
            .onClick(() => {
              const arr_x = JSON.parse(JSON.stringify(train_x));
              const arr_y = JSON.parse(JSON.stringify(train_y));
              // arr[1]
              var xt = []
              var yt = []
              for(let i=0;i<3132;i++){
                xt[i] = [];
                yt[i] = arr_y[i];
                for(let j=0;j<10;j++){
                  xt[i][j] = arr_x[i][j]
                }
              }
              var xtrain = tf.tensor(xt);
              var ytrain = tf.tensor(yt);
              this.model.add(tf.layers.dense({ units: 50, activation: 'sigmoid', inputShape: [10] }));
              this.model.add(tf.layers.dense({ units: 50, activation: 'sigmoid' }));
              this.model.add(tf.layers.dense({ units: 1}));
              var learning_rate = 0.05
              this.model.compile({optimizer: tf.train.sgd(learning_rate),loss: 'meanSquaredError', metrics: ['acc'] }); //optimizer: tf.train.sgd(learning_rate)
              const history = this.model.fit(xtrain, ytrain, { epochs: 10, batchSize: 50,callbacks: tf.callbacks.earlyStopping({ monitor: "val_acc" }),})
              // Takes ~ 13 seconds per epoch
              console.log("fit is over")

            }).margin('25px')
          Button("Test")//Press to predict after training
            .onClick(() => {
              const arr_x = JSON.parse(JSON.stringify(test_x));
              const arr_y = JSON.parse(JSON.stringify(test_y));
              //              console.log(arr_x[10][0])
              var xt = []
              var yt = []
              for(let i=0;i<1045;i++){
                yt[i] = [];
                yt[i][0]=arr_y[i];
                xt[i] = [];
                for(let j=0;j<10;j++){
                  xt[i][j] = arr_x[i][j]
                }
              }

              var xtest = tf.tensor(xt);
              var ytest = tf.tensor(yt);
              const ypred = this.model.predict(xtest) as tf.Tensor;
              //              const values = ypred.dataSync();
              //              const arr = Array.from(values);
              var mse =  tf.losses.meanSquaredError(ytest,ypred);
              const values = mse.dataSync();
              const arr = Array.from(values);
              this.error = 'Test Error: '+ arr[0].toFixed(3)
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