// Copyright (c) 2018 ml5
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

import * as tf from "@ohos/tfjs";
import * as tfvis from "@ohos/tfjs-vis";
import imageClassifier from "./ImageClassifier/";
import KNNClassifier from "./KNNClassifier/";

import { version } from "../package.json";
import p5Utils from "./utils/p5Utils";
import communityStatement from "./utils/community";
import * as testingUtils from "./utils/testingUtils";

const withPreload = {
  imageClassifier,
  kmeans,
};

// call community statement on load
(() => {
  communityStatement();
})();

export default Object.assign({ p5Utils }, preloadRegister(withPreload), {
  KNNClassifier,
  communityStatement,
  ...imageUtils,
  tf,
  tfvis,
  version,
  testingUtils
});
