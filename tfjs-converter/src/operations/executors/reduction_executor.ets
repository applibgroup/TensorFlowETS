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

import {Tensor, Tensor1D, Tensor2D} from '@ohos/tfjs-core';
// tslint:disable-next-line: no-imports-from-dist
import * as tfOps from '@ohos/tfjs-core/src/ops/ops_for_converter';

import {NamedTensorsMap} from '../../data/types';
import {ExecutionContext} from '../../executor/execution_context';
import {InternalOpExecutor, Node} from '../types';

import {getParamValue} from './utils';

export const executeOp: InternalOpExecutor =
    (node: Node, tensorMap: NamedTensorsMap,
     context: ExecutionContext): Tensor[] => {
      switch (node.op) {
        case 'Max': {
          const axis =
              getParamValue('axis', node, tensorMap, context) as number[];
          const keepDims =
              getParamValue('keepDims', node, tensorMap, context) as boolean;
          return [tfOps.max(
              getParamValue('x', node, tensorMap, context) as Tensor, axis,
              keepDims)];
        }
        case 'Mean': {
          const axis =
              getParamValue('axis', node, tensorMap, context) as number[];
          const keepDims =
              getParamValue('keepDims', node, tensorMap, context) as boolean;
          return [tfOps.mean(
              getParamValue('x', node, tensorMap, context) as Tensor, axis,
              keepDims)];
        }
        case 'Min': {
          const axis =
              getParamValue('axis', node, tensorMap, context) as number[];
          const keepDims =
              getParamValue('keepDims', node, tensorMap, context) as boolean;
          return [tfOps.min(
              getParamValue('x', node, tensorMap, context) as Tensor, axis,
              keepDims)];
        }
        case 'Sum': {
          const axis =
              getParamValue('axis', node, tensorMap, context) as number[];
          const keepDims =
              getParamValue('keepDims', node, tensorMap, context) as boolean;
          return [tfOps.sum(
              getParamValue('x', node, tensorMap, context) as Tensor, axis,
              keepDims)];
        }
        case 'All': {
          const axis =
              getParamValue('axis', node, tensorMap, context) as number[];
          const keepDims =
              getParamValue('keepDims', node, tensorMap, context) as boolean;
          return [tfOps.all(
              getParamValue('x', node, tensorMap, context) as Tensor, axis,
              keepDims)];
        }
        case 'Any': {
          const axis =
              getParamValue('axis', node, tensorMap, context) as number[];
          const keepDims =
              getParamValue('keepDims', node, tensorMap, context) as boolean;
          return [tfOps.any(
              getParamValue('x', node, tensorMap, context) as Tensor, axis,
              keepDims)];
        }
        case 'ArgMax': {
          const axis =
              getParamValue('axis', node, tensorMap, context) as number;
          return [tfOps.argMax(
              getParamValue('x', node, tensorMap, context) as Tensor, axis)];
        }
        case 'ArgMin': {
          const axis =
              getParamValue('axis', node, tensorMap, context) as number;
          return [tfOps.argMin(
              getParamValue('x', node, tensorMap, context) as Tensor, axis)];
        }
        case 'Prod': {
          const axis =
              getParamValue('axis', node, tensorMap, context) as number[];
          const keepDims =
              getParamValue('keepDims', node, tensorMap, context) as boolean;
          return [tfOps.prod(
              getParamValue('x', node, tensorMap, context) as Tensor, axis,
              keepDims)];
        }
        case 'Cumprod': {
          const axis =
              getParamValue('axis', node, tensorMap, context) as number;
          const exclusive =
              getParamValue('exclusive', node, tensorMap, context) as boolean;
          const reverse =
              getParamValue('reverse', node, tensorMap, context) as boolean;
          return [tfOps.cumprod(
              getParamValue('x', node, tensorMap, context) as Tensor, axis,
              exclusive, reverse)];
        }
        case 'Cumsum': {
          const axis =
              getParamValue('axis', node, tensorMap, context) as number;
          const exclusive =
              getParamValue('exclusive', node, tensorMap, context) as boolean;
          const reverse =
              getParamValue('reverse', node, tensorMap, context) as boolean;
          return [tfOps.cumsum(
              getParamValue('x', node, tensorMap, context) as Tensor, axis,
              exclusive, reverse)];
        }
        case 'Bincount':
          const x = getParamValue('x', node, tensorMap, context) as Tensor1D;
          const weights =
              getParamValue('weights', node, tensorMap, context) as Tensor1D;
          const size =
              getParamValue('size', node, tensorMap, context) as number;

          return [tfOps.bincount(x, weights, size)];
        case 'DenseBincount': {
          const x = getParamValue('x', node, tensorMap, context) as Tensor1D |
              Tensor2D;
          const weights =
              getParamValue('weights', node, tensorMap, context) as Tensor1D |
              Tensor2D;
          const size =
              getParamValue('size', node, tensorMap, context) as number;

          const binaryOutput =
              getParamValue('binaryOutput', node, tensorMap, context) as
              boolean;

          return [tfOps.denseBincount(x, weights, size, binaryOutput)];
        }
        default:
          throw TypeError(`Node type ${node.op} is not implemented`);
      }
    };

export const CATEGORY = 'reduction';
