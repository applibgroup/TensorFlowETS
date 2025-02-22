/**
 * @license
 * Copyright 2020 Google LLC. All Rights Reserved.
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
import {backend_util, KernelConfig, KernelFunc, MaxPool3DGrad, MaxPool3DGradAttrs, MaxPool3DGradInputs, TensorInfo} from '@ohos/tfjs-core';

import {MathBackendWebGL} from '../backend_webgl';
import {MaxPool3DBackpropProgram} from '../max_pool_backprop_gpu';
import {Pool3DProgram} from '../pool_gpu';

export function maxPool3DGrad(args: {
  inputs: MaxPool3DGradInputs,
  backend: MathBackendWebGL,
  attrs: MaxPool3DGradAttrs
}): TensorInfo {
  const {inputs, backend, attrs} = args;
  const {dy, input} = inputs;
  const x = input;
  const {filterSize, strides, pad, dimRoundingMode} = attrs;
  const dilations: [number, number, number] = [1, 1, 1];

  const convInfo = backend_util.computePool3DInfo(
      x.shape as [number, number, number, number, number], filterSize, strides,
      dilations, pad, dimRoundingMode);

  const maxPool3dPositionsProgram =
      new Pool3DProgram(convInfo, 'max', true /* get positions */);
  const maxPool3dPositions =
      backend.runWebGLProgram(maxPool3dPositionsProgram, [x], x.dtype);
  const maxPoolBackpropProgram = new MaxPool3DBackpropProgram(convInfo);
  const result = backend.runWebGLProgram(
      maxPoolBackpropProgram, [dy, maxPool3dPositions], x.dtype);
  backend.disposeIntermediateTensorInfo(maxPool3dPositions);
  return result;
}

export const maxPool3DGradConfig: KernelConfig = {
  kernelName: MaxPool3DGrad,
  backendName: 'webgl',
  kernelFunc: maxPool3DGrad as {} as KernelFunc
};
