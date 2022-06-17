/// <amd-module name="@ohos/tfjs-core/dist/public/chained_ops/equal" />
import { Rank, TensorLike } from '../../types';
declare module '../../tensor' {
    interface Tensor<R extends Rank = Rank> {
        equal<T extends Tensor>(b: Tensor | TensorLike): T;
    }
}
