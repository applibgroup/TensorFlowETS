import * as tf from "@ohos/tfjs"
import router from '@system.router';

@Entry
@Component
struct AbaloneLoad {
  @State message: string = 'Abalone Load'
  @State input: string = 'Input'
  @State output: string = 'Output'
  //  @State model: tf.LayersModel = tf.loadLayersModel("../../../resources/base/media/Abalone_Model/model.json");
  build() {
    Row() {
      Column() {
        Text(this.message)
          .fontSize(50)
          .fontWeight(FontWeight.Bold)
        Row(){
          Button("Load")
            .onClick(async() => {
              console.log("Started loading the model");
              const model = await tf.loadLayersModel('/common/abalone');
              // common directory is present in tfjs-core/src/io - place the weights and model .json files there in the format of "yourmodelname_weights.json" and "yourmodelname_model.json"
              const result = model.predict(
              tf.tensor2d([[0, 0.625, 0.495, 0.165, 1.262, 0.507, 0.318, 0.39]])) as tf.Tensor;
              console.log(
                'The actual test abalone age is 10, prediction from the model is ' +
                result.dataSync())
              this.input = 'The actual test abalone age is 10'
              this.output = 'prediction from the model is '+ result.dataSync();
              console.log("Loaded the model");
            }).margin('25px')
          Button("Test") //Press to predict after training
            .onClick(() => {
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