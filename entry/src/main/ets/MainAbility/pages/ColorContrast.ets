import * as tf from "@ohos/tfjs"
import router from '@system.router'
@Entry
@Component
struct Xor {
  @State message: string = 'Color Contrast'
  @State input: string = 'Input'
  @State output: string = 'Output'
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
              const xtrain = tf.tensor([[0.03, 0.7,0.5], [0.16, 0.09,0.2], [0.5, 0.5,1.0]]);
              const ytrain = tf.tensor([[1,0], [0,1], [0,1]]);

              this.model.add(tf.layers.dense({ units: 3, activation: 'sigmoid', inputShape: [3] }));
              this.model.add(tf.layers.dense({ units: 2, activation: 'softmax' }));
              var learning_rate = 0.1
              this.model.compile({loss: 'categoricalCrossentropy', optimizer: tf.train.adam(learning_rate)});
              const history = this.model.fit(xtrain, ytrain, { epochs: 1000 })
              console.log("fit is over")


            }).margin('25px')
          Button("Test")//Press to predict after training
            .onClick(() => {
              const xt = tf.tensor([[0.9, 0.4, 0.0]])
              const p = this.model.predict(xt) as tf.Tensor;
              const values = p.dataSync();
              const arr = Array.from(values);
              var o = [];
              o[0] = arr[0].toFixed(3);
              o[1] = arr[1].toFixed(3);
              this.input = "Input- R:0.9, G:0.4, B:0.0";
              this.output = "Output- Black:"+o[0]+", White:" + o[1];
            }).margin('25px')
        }
        Text(this.input)
          .fontSize(25)
          .fontWeight(FontWeight.Bold)
        Text(this.output)
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