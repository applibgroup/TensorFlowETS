/**
 * @license
 * Copyright 2020 Google LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0 (the License);
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an AS IS BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 * =============================================================================
 */

import {Atan2, KernelConfig} from '@ohos/tfjs-core';
import {createSimpleBinaryKernelImpl} from '../utils/binary_impl';
import {binaryKernelFunc} from '../utils/binary_utils';

export const atan2Impl = createSimpleBinaryKernelImpl(
    (aValue, bValue) => Math.atan2(aValue as number, bValue as number));

export const atan2 = binaryKernelFunc(Atan2, atan2Impl);

export const atan2Config: KernelConfig = {
  kernelName: Atan2,
  backendName: 'cpu',
  kernelFunc: atan2,
};
