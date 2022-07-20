import * as tf from "@ohos/tfjs"
import router from '@system.router'

import * as train_features from "./../../../resources/base/media/train_features.json";
import * as train_targets from "./../../../resources/base/media/train_targets.json";
import * as test_features from "./../../../resources/base/media/test_features.json";
import * as test_targets from "./../../../resources/base/media/test_targets.json";

@Entry
@Component
struct Iris {
  @State message: string = 'Classification using Iris Dataset'

  @State error: string = 'Test loss: '
  @State model: tf.Sequential = tf.sequential();
  build() {
    Row() {
      Column() {
        Text(this.message)
          .fontSize(50)
          .fontWeight(FontWeight.Bold)
        Row(){
          Button("Train")
            .onClick(async() => {
              const arr_x = JSON.parse(JSON.stringify(train_features));
              const arr_y = JSON.parse(JSON.stringify(train_targets));
              // arr[1]
              var xt = []
              var yt = []
              for(let i=0;i<120;i++){
                xt[i] = [];
                yt[i] = [];
                for(let j=0;j<4;j++){
                  xt[i][j] = arr_x[i][j]
                  if(j<3){
                    yt[i][j] = arr_y[i][j]
                  }
                }
              }
              var xtrain = tf.tensor(xt);
              // console.log(xtrain.dataSync())
              var ytrain = tf.tensor(yt);
              // console.log(ytrain.dataSync().toString())

              const start = Date.now();
              try {
                this.model.add(tf.layers.dense({ units: 10, activation: 'sigmoid', inputShape: [4] }));
                this.model.add(tf.layers.dense({ units: 3, activation: 'softmax' }));
                var learning_rate = 0.001
                this.model.compile({optimizer: tf.train.adam(learning_rate),loss: 'categoricalCrossentropy', metrics: ['acc'] });
                const history = await this.model.fit(xtrain, ytrain, {
                  epochs: 1000,
                  batchSize: 20,
                  callbacks: tf.callbacks.earlyStopping({ monitor: 'val_acc' }),
                })
              }
              catch(err){
                console.log(err.toString())
              }
              const duration = Date.now() - start;
              console.log("Time taken: "+ (duration/1000).toString() + "seconds")
              console.log("fit is over")
              // Each epoch took around 0.15 seconds

            }).margin('25px')
          Button("Test")//Press to predict after training
            .onClick(() => {
              const arr_x = JSON.parse(JSON.stringify(test_features));
              const arr_y = JSON.parse(JSON.stringify(test_targets));

              var xt = []
              var yt = []
              for(let i=0;i<20;i++){
                yt[i] = [];
                xt[i] = [];
                for(let j=0;j<4;j++){
                  xt[i][j] = arr_x[i][j]
                  if(j<3){
                    yt[i][j] = arr_y[i][j]
                  }
                }
              }

              var xtest = tf.tensor(xt);
              var ytest = tf.tensor(yt);
              const ypred = this.model.predict(xtest) as tf.Tensor;
              var mse =  tf.losses.absoluteDifference(ytest,ypred);
              const val = mse.dataSync()
              const arr = Array.from(val);
              console.log("loss is: " + arr.toString());
              try {

              } catch (err) {
                console.log(err)
              }
              //              const values = ypred.dataSync();
              //              const arr = Array.from(values);
//              var mse =  tf.losses.softmaxCrossEntropy(ytest,ypred);
//              const values = mse.dataSync();
//              const arr = Array.from(values);
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