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

import {IFFT, IFFTInputs, KernelConfig, TensorInfo} from '@ohos/tfjs-core';

import {MathBackendWebGL} from '../backend_webgl';

import {fftImpl} from './FFT_impl';

export function ifft(args: {inputs: IFFTInputs, backend: MathBackendWebGL}):
    TensorInfo {
  const {inputs, backend} = args;
  const {input} = inputs;

  return fftImpl(input, true /* inverse */, backend);
}

export const ifftConfig: KernelConfig = {
  kernelName: IFFT,
  backendName: 'webgl',
  kernelFunc: ifft
};
