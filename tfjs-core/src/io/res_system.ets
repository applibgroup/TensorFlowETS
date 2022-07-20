/**
 * @license
 * Copyright 2018 Google LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 * =============================================================================
 */

import * as tf from '@ohos/tfjs';
import fileio from '@ohos.fileio';

import '../flags';
import {env} from '../environment';
import {Buffer} from 'buffer';

import {assert} from '../util';
import {arrayBufferToBase64String, base64StringToArrayBuffer, getModelArtifactsForJSON,
  getModelArtifactsInfoForJSON, concatenateArrayBuffers, typedArrayToBuffer} from './io_utils';
import {IORouter, IORouterRegistry} from './router_registry';
import {IOHandler, ModelArtifacts, ModelJSON, SaveResult, WeightsManifestConfig, WeightsManifestEntry} from './types';

// import * as fs from 'fs';
// import {dirname, join, resolve} from 'path';
// import {promisify} from '@ohos/util';
/*import promisify from '@ohos.util';

const stat = promisify(fs.stat);
const writeFile = promisify(fs.writeFile);
const readFile = promisify(fs.readFile);
const mkdir = promisify(fs.mkdir);*/

function doesNotExistHandler(name: string): (e: Error) =>
never {
  return e => {
    throw new Error(`${name} ${e.message} does not exist: loading failed`);
  };
}

export class NodeFileSystem implements IOHandler {
  static readonly URL_SCHEME = '/common';

  protected readonly path: string|string[];

  readonly MODEL_JSON_FILENAME = 'model.json';
  readonly WEIGHTS_BINARY_FILENAME = 'weights.bin';
  readonly MODEL_BINARY_FILENAME = 'tensorflowjs.pb';

  /**
   * Constructor of the NodeFileSystem IOHandler.
   * @param path A single path or an Array of paths.
   *   For saving: expects a single path pointing to an existing or nonexistent
   *     directory. If the directory does not exist, it will be
   *     created.
   *   For loading:
   *     - If the model has JSON topology (e.g., `tf.Model`), a single path
   *       pointing to the JSON file (usually named `model.json`) is expected.
   *       The JSON file is expected to contain `modelTopology` and/or
   *       `weightsManifest`. If `weightManifest` exists, the values of the
   *       weights will be loaded from relative paths (relative to the directory
   *       of `model.json`) as contained in `weightManifest`.
   *     - If the model has binary (protocol buffer GraphDef) topology,
   *       an Array of two paths is expected: the first path should point to the
   *       .pb file and the second path should point to the weight manifest
   *       JSON file.
   */
  constructor(path: string|string[]) {
    if (Array.isArray(path)) {
      tf.util.assert(
          path.length === 2,
          () => 'file paths must have a length of 2, ' +
              `(actual length is ${path.length}).`);
      this.path = path.map(p => p);
    } else {
      this.path = path;
    }
  }

  async save(modelArtifacts: tf.io.ModelArtifacts): Promise<tf.io.SaveResult> {
    if (Array.isArray(this.path)) {
      throw new Error('Cannot perform saving to multiple paths.');
    }

    await this.createOrVerifyDirectory();

    if (modelArtifacts.modelTopology instanceof ArrayBuffer) {
      throw new Error(
          'NodeFileSystem.save() does not support saving model topology ' +
          'in binary format yet.');
      // TODO(cais, nkreeger): Implement this. See
      //   https://github.com/tensorflow/tfjs/issues/343
    } else {
      // const weightsBinPath = join(this.path, this.WEIGHTS_BINARY_FILENAME);
      const weightsBinPath = this.path + this.WEIGHTS_BINARY_FILENAME;
      const weightsManifest = [{
        paths: [this.WEIGHTS_BINARY_FILENAME],
        weights: modelArtifacts.weightSpecs
      }];
      const modelJSON: tf.io.ModelJSON = {
        modelTopology: modelArtifacts.modelTopology,
        weightsManifest,
        format: modelArtifacts.format,
        generatedBy: modelArtifacts.generatedBy,
        convertedBy: modelArtifacts.convertedBy
      };
      if (modelArtifacts.trainingConfig != null) {
        modelJSON.trainingConfig = modelArtifacts.trainingConfig;
      }
      if (modelArtifacts.signature != null) {
        modelJSON.signature = modelArtifacts.signature;
      }
      if (modelArtifacts.userDefinedMetadata != null) {
        modelJSON.userDefinedMetadata = modelArtifacts.userDefinedMetadata;
      }
      // const modelJSONPath = join(this.path, this.MODEL_JSON_FILENAME);
      const modelJSONPath = this.path + this.MODEL_JSON_FILENAME;
      let fd = fileio.openSync(modelJSONPath, 0o100 | 0o2, 0o666);
      let num = await fileio.write(fd, JSON.stringify(modelJSON), 'utf8');
      //await writeFile(modelJSONPath, JSON.stringify(modelJSON), 'utf8');

      let fd1 = fileio.openSync(weightsBinPath, 0o100 | 0o2, 0o666);
      let num1 = await fileio.write(fd1, Buffer.from(modelArtifacts.weightData), 'utf8');
      /*await writeFile(
          weightsBinPath, Buffer.from(modelArtifacts.weightData), 'binary');*/

      return {
        // TODO(cais): Use explicit tf.io.ModelArtifactsInfo type below once it
        // is available.
        // tslint:disable-next-line:no-any
        modelArtifactsInfo: getModelArtifactsInfoForJSON(modelArtifacts) as any
      };
    }
  }
  async load(): Promise<tf.io.ModelArtifacts> {
    return Array.isArray(this.path) ? this.loadBinaryModel() :
                                      this.loadJSONModel();
  }

  protected async loadBinaryModel(): Promise<tf.io.ModelArtifacts> {
    const topologyPath = this.path[0];
    const weightManifestPath = this.path[1];
    const topology =
        await fileio.stat(topologyPath); //.catch(doesNotExistHandler('Topology Path'));
    const weightManifest =
        await fileio.stat(weightManifestPath)
            .catch(doesNotExistHandler('Weight Manifest Path'));

    // `this.path` can be either a directory or a file. If it is a file, assume
    // it is model.json file.
    if (!topology.isFile()) {
      throw new Error('File specified for topology is not a file!');
    }
    if (!weightManifest.isFile()) {
      throw new Error('File specified for the weight manifest is not a file!');
    }

    let fd = fileio.openSync(this.path[0], 0o2);
    let buf = new ArrayBuffer(4096);
    let res = await fileio.read(fd, buf);
    const modelTopology = buf;
    // const modelTopology = await readFile(this.path[0]);
    let fd1 = fileio.openSync(this.path[1], 0o2);
    let buf1 = new ArrayBuffer(4096);
    let res1 = await fileio.read(fd1, buf1);
    const weightsManifest = JSON.parse(arrayBufferToBase64String(buf1));
    // const weightsManifest = JSON.parse(await readFile(this.path[1], 'utf8'));

    const modelArtifacts: tf.io.ModelArtifacts = {
      modelTopology,
    };
    const [weightSpecs, weightData] =
        await this.loadWeights(weightsManifest, this.path[1]);

    modelArtifacts.weightSpecs = weightSpecs;
    modelArtifacts.weightData = weightData;

    return modelArtifacts;
  }

  protected async loadJSONModel(): Promise<ModelArtifacts> {
    console.info("res loadJSONModel " + this.path);
//    const path = "./common" + this.path + "_model.json"as string;

    let myData = await import("./common/" + this.path + "/model.json");
    // let myData = await import('@ohos/tfjs-models/models/abalone/model.json');
    console.info("myData " + myData);

    let data = JSON.parse((JSON.stringify(myData)));
    console.info(data.format);

    const modelTopology = data.modelTopology;
    if (modelTopology == null) {
      console.info("myData modelTopology null ");
      return;
    }
    const weightsManifest = data.weightsManifest;
    if (weightsManifest == null) {
      console.info("myData weightsManifest null ");
      return;
    }

    return getModelArtifactsForJSON(
      data,
      (weightsManifest) => this.loadWeightsAsArrayBuffer(weightsManifest));
  }

  protected async loadJSONModell(): Promise<ModelArtifacts> {
    console.info("res loadJSONModel " + this.path);
//    const path = "./common" + this.path + "_model.json"as string;
    return new Promise((resolve, reject) => {
      import("./common/" + this.path + "/model.json").then(({default: myData}) => {
        console.info("myData " + myData);
        console.info("./common/" + this.path + "/model.json")
        Promise.resolve(JSON.parse((JSON.stringify(myData))))
          .then(data => {
            /*console.info(data);
            console.info(data.modelTopology);*/
            console.info(data.format);

            const modelTopology = data.modelTopology;
            if (modelTopology == null) {
              console.info("myData modelTopology null ");
              reject(new Error(`modelTopology field is missing from file `));
              return;
            }
            const weightsManifest = data.weightsManifest;
            if (weightsManifest == null) {
              console.info("myData weightsManifest null ");
              reject(new Error(`weightManifest field is missing from file `));
              return;
            }
            /*const modelArtifactsPromise = getModelArtifactsForJSON(
              data, (weightsManifest) => this.loadWeights(weightsManifest));
            resolve(modelArtifactsPromise);*/

            return getModelArtifactsForJSON(
              data,
              (weightsManifest) => this.loadWeightsAsArrayBuffer(weightsManifest));
          })
      });
    });
  }

  private async loadWeights(
    weightsManifest: WeightsManifestConfig,
    pathoffile: string): Promise<[WeightsManifestEntry[], ArrayBuffer]> {
    console.info("loadWeights");
    const weightSpecs: WeightsManifestEntry[] = [];
    const paths: string[] = [];
    const buffers: ArrayBuffer[] = [];
    for (const entry of weightsManifest) {
      console.info("loadWeights for loop");
      weightSpecs.push(...entry.weights);
      paths.push(...entry.paths);
    }
    /*for (const group of weightsManifest) {
      for (const path of group.paths) {
        console.info("loadWeights for loop path " + path);
        const weightFilePath = "./../common/weights.bin";
        let fd = fileio.openSync('./../common/weights.bin', 0o2);
        let buf = new ArrayBuffer(4096);
        fileio.readSync(fd, buf);
        buffers.push(buf);
      }
    }*/

    console.info("Perform JSON to array buffer");
    /*import('./../common/weights.json').then(({default: myData}) => { // JSON to ArrayBuffer
      console.info("JSON to array buffer " + myData);
      const arrBuffer = new Uint8Array(JSON.parse(JSON.stringify(myData))).buffer
      console.info("loadWeights arrBuffer " + arrBuffer);

      const arrBuffer1 = typedArrayToBuffer(new Uint8Array(JSON.parse(JSON.stringify(myData))))
      console.info("loadWeights arrBuffer1 " + arrBuffer1);

      // JSON.parse(String.fromCharCode.apply(null, new Uint8Array(myData)));
      console.info("arrBuffer return");
      return [weightSpecs, arrBuffer];
      // return [weightSpecs, concatenateArrayBuffers(buffers)];
    });*/

    // let jsonOfWeights = await import('./../common/weights.json');
    // let jsonOfWeights = await import('@ohos/tfjs-models/models/abalone/weights.json');
    let jsonOfWeights = await import("./common/" + this.path + "_weights.json");
    let jsonObj = JSON.parse(JSON.stringify(jsonOfWeights))
    let jsonArray = []
    for (var item in jsonObj) {
      jsonArray.push(item);
    }
    console.info("loadWeights jsonArray count " + jsonArray.length);
    // const arrBuffer = new Uint8Array(JSON.parse(JSON.stringify(jsonOfWeights))).buffer
    // the json which we converted  used Float32Array to convert the binary file,
    // So to get back the buffer we should use floar32array
    const arrBuffer = new Float32Array(jsonArray).buffer
    console.info("loadWeights jsonOfWeights arrBuffer " + arrBuffer);
    return [weightSpecs, arrBuffer];
    // return [weightSpecs, concatenateArrayBuffers(buffers)];
  }

  private async loadWeightsAsArrayBuffer(
      weightsManifest: WeightsManifestConfig): Promise<[WeightsManifestEntry[], ArrayBuffer]> {
    // const dirName = dirname(path);
    const buffers: ArrayBuffer[] = [];
    const weightSpecs: WeightsManifestEntry[] = [];
    const bytelen=await import("./common/"+this.path+"/bytelen.json")
    for (const group of weightsManifest) {
      for (const path of group.paths) {
        /*const weightFilePath = join(dirName, path);
        const buffer = await readFile(weightFilePath)
                           .catch(doesNotExistHandler('Weight file'));*/
        const weightFilePath = "/common/"+this.path+"/"+path;
        let fd = fileio.openSync(weightFilePath, 0o2);
        let buf = new ArrayBuffer(bytelen[path]);
        await fileio.read(fd, buf)
          .catch(doesNotExistHandler('Weight file'));
        buffers.push(buf);
      }
      weightSpecs.push(...group.weights);
    }
    // return [weightSpecs, base64StringToArrayBuffer(buffers)];
    return [weightSpecs, concatenateArrayBuffers(buffers)];
  }

  /**
   * For each item in `this.path`, creates a directory at the path or verify
   * that the path exists as a directory.
   */
  protected async createOrVerifyDirectory() {
    const paths = Array.isArray(this.path) ? this.path : [this.path];
    for (const path of paths) {
      try {
        await fileio.mkdir(path);
      } catch (e) {
        if (e.code === 'EEXIST') {
          if ((await fileio.stat(path)).isFile()) {
            throw new Error(
                `Path ${path} exists as a file. The path must be ` +
                `nonexistent or point to a directory.`);
          }
          // else continue, the directory exists
        } else {
          throw e;
        }
      }
    }
  }
}

export const nodeFileSystemRouter = (url: string|string[]) => {
  if (Array.isArray(url)) {
    if (url.every(
            urlElement => urlElement.startsWith(NodeFileSystem.URL_SCHEME))) {
      return new NodeFileSystem(url.map(
          urlElement => urlElement.slice(NodeFileSystem.URL_SCHEME.length)));
    } else {
      return null;
    }
  } else {
    if (url.startsWith(NodeFileSystem.URL_SCHEME)) {
      return new NodeFileSystem(url.slice(NodeFileSystem.URL_SCHEME.length));
    } else {
      return null;
    }
  }
};
// Registration of `nodeFileSystemRouter` is done in index.ts.

/**
 * Factory function for Node.js native file system IO Handler.
 *
 * @param path A single path or an Array of paths.
 *   For saving: expects a single path pointing to an existing or nonexistent
 *     directory. If the directory does not exist, it will be
 *     created.
 *   For loading:
 *     - If the model has JSON topology (e.g., `tf.Model`), a single path
 *       pointing to the JSON file (usually named `model.json`) is expected.
 *       The JSON file is expected to contain `modelTopology` and/or
 *       `weightsManifest`. If `weightManifest` exists, the values of the
 *       weights will be loaded from relative paths (relative to the directory
 *       of `model.json`) as contained in `weightManifest`.
 *     - If the model has binary (protocol buffer GraphDef) topology,
 *       an Array of two paths is expected: the first path should point to the
 *        .pb file and the second path should point to the weight manifest
 *       JSON file.
 */
export function fileSystem(path: string|string[]): NodeFileSystem {
  return new NodeFileSystem(path);
}

export const resSystemRouter: IORouter = (path: string|string[]) => {
    if (!Array.isArray(path) && path.startsWith(NodeFileSystem.URL_SCHEME)) {
      console.info("resSystemRouter " + path.slice(NodeFileSystem.URL_SCHEME.length));
      return fileSystem(
      path.slice(NodeFileSystem.URL_SCHEME.length));
    } else {
      console.info("resSystemRouter returning nulll");
      return null;
    }
};
IORouterRegistry.registerLoadRouter(resSystemRouter);