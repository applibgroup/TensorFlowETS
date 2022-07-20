import * as tf from "@ohos/tfjs"
import router from '@system.router'
@Entry
@Component
struct Xor {
  @State message: string = 'XOR'
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
            console.log("Xor")
            const xtrain = tf.tensor2d([[0, 0], [0, 1], [1, 0], [1, 1]]);
            const ytrain = tf.tensor2d([[1,0], [0,1], [0,1], [1,0]]);
            this.model.add(tf.layers.dense({ units: 3, activation: 'sigmoid', inputShape: [2] }));
            this.model.add(tf.layers.dense({ units: 2, activation: 'softmax' }));
            var learning_rate = 0.1
            this.model.compile({loss: 'categoricalCrossentropy', optimizer: tf.train.adam(learning_rate)});
            const history = this.model.fit(xtrain, ytrain, { epochs: 500 })
            console.log("fit is over")

          }).margin('25px')
        Button("Test") //Press to predict after training
          .onClick(() => {
              const xtest = tf.tensor2d([[0, 0], [0, 1], [1, 0], [1, 1]]);
              const ytrain = tf.tensor2d([[1,0], [0,1], [0,1], [1,0]]);
              const p = this.model.predict(xtest) as tf.Tensor;
              const values = p.dataSync();
              const arr = Array.from(values);
              this.input =  "Input: [0, 0], [0, 1], [1, 0], [1, 1]"
              let o = ""
              for(let i=0;i<4;i++){
                if(arr[i*2]>arr[i*2+1]){
                  o += "[0] ";
                }
                else{
                  o += "[1] ";
                }
              }
              this.output = "Output: "+o;
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