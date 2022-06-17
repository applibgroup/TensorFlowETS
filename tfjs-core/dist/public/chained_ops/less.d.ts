/// <amd-module name="@ohos/tfjs-core/dist/public/chained_ops/less" />
import { Rank, TensorLike } from '../../types';
declare module '../../tensor' {
    interface Tensor<R extends Rank = Rank> {
        less<T extends Tensor>(b: Tensor | TensorLike): T;
    }
}
