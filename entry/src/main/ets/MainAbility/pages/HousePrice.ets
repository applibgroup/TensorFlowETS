import * as tf from "@ohos/tfjs"
import * as house_data from "./../../../resources/base/media/house.json";

@Entry
@Component
struct Xor {
  @State message: string = 'Boston House Price Prediction'
  @State error: string = 'Test Error: '
  @State mse_error: string = 'Mean Square Error: '
  @State mape_error: string = 'Mean Absolute % Error: '
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
              const arr = JSON.parse(JSON.stringify(house_data));
              // arr[1]
              var xt = []
              var yt = []
              for(let i=0;i<380;i++){
                xt[i] = [];
                yt[i] = arr[i][13];
                for(let j=0;j<13;j++){
                  xt[i][j] = arr[i][j]
                }
              }
              var xtrain = tf.tensor(xt);
              var ytrain = tf.tensor(yt);
              this.model.add(tf.layers.dense({
                inputShape: [13],
                units: 13,
              }));
              this.model.add(tf.layers.batchNormalization());
              this.model.add(tf.layers.activation({activation: 'relu'}));
              this.model.add(tf.layers.dense({
                units: 26,
              }));
              this.model.add(tf.layers.batchNormalization())
              this.model.add(tf.layers.activation({activation: 'relu'}))
              this.model.add(tf.layers.dropout({ rate: 0.25 }))
              this.model.add(tf.layers.dense({
                units: 13,
              }));
              this.model.add(tf.layers.activation({activation: 'relu'}))
              this.model.add(tf.layers.dense({ units: 1}));
              this.model.add(tf.layers.activation({activation: 'relu'}))
              this.model.compile({
                optimizer: tf.train.adam(),
                loss: 'meanSquaredError' ,
                metrics: ['acc']
              });
              this.model.summary()
              const history = this.model.fit(xtrain, ytrain, { epochs: 100, batchSize: 39,callbacks: {onEpochEnd: async (epoch, logs) => {
                console.info(epoch.toString(), logs.loss);
                console.info(logs.loss.toString());
              }},})
              // Takes ~ 6 seconds per epoch
              console.log("fit is over")

            }).margin('25px')
          Button("Test")//Press to predict after training
            .onClick(() => {
              const arr_data = JSON.parse(JSON.stringify(house_data));
              //              console.log(arr_x[10][0])
              var xt = []
              var yt = []
              for(let i=0;i<70;i++){
                yt[i] = [];
                yt[i][0]=arr_data[i+381][13];
                xt[i] = [];
                for(let j=0;j<13;j++){
                  xt[i][j] = arr_data[i+381][j]
                }
              }

              var xtest = tf.tensor(xt);
              var ytest = tf.tensor(yt);
              const ypred = this.model.predict(xtest) as tf.Tensor;
              //              const values = ypred.dataSync();
              //              const arr = Array.from(values);
              var mse =  tf.losses.meanSquaredError(ytest,ypred);
              var mape = tf.metrics.meanAbsolutePercentageError(ytest,ypred);
              const values = mse.dataSync();
              const values1 = mape.dataSync();
              const arr = Array.from(values);
              const arr1 = Array.from(values1);
              this.mse_error = 'Mean Square Error: ' + arr[0].toFixed(3) ;
              this.mape_error = 'Mean Absolute % Error: ' + arr1[0].toFixed(3);
//              console.log(arr1[1].toString());
            }).margin('25px')
        }
        Text(this.error)
          .fontSize(25)
          .fontWeight(FontWeight.Bold)
          .margin('25px')
        Text(this.mse_error)
          .fontSize(25)
          .fontWeight(FontWeight.Bold)
          .margin('25px')
        Text(this.mape_error)
          .fontSize(25)
          .fontWeight(FontWeight.Bold)
          .margin('25px')
      }
      .width('100%')
    }
    .height('100%')
  }
}