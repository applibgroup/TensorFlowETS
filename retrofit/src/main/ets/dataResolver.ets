/*
 * Copyright (c) 2021 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import { DATA_CONTENT_TYPES } from "./constants";

export class BaseDataResolver {
  public resolve(headers: any, data: any): any {
    throw new Error("Can not call this method in BaseDataResolver.");
  }
}

export class JsonResolver extends BaseDataResolver {
  constructor() {
    super();
  }

  public resolve(headers: any, data: any): any {
    return data;
  }
}

export class TextXmlResolver extends BaseDataResolver {
  constructor() {
    super();
  }

  public resolve(headers: any, data: any): any {
    return data;
  }
}

const dataResolverMap: Map<string, typeof BaseDataResolver> = new Map<string, typeof BaseDataResolver>();
dataResolverMap.set("application/json", JsonResolver);
dataResolverMap.set("text/xml", TextXmlResolver);

export class DataResolverFactory {
  public createDataResolver(contentType: string): BaseDataResolver {
    const contentTypeLowCased = contentType.toLowerCase();
    for (const dataContentType of DATA_CONTENT_TYPES) {
      if (contentTypeLowCased.includes(dataContentType)) {
        const resolverCls = this._getDataResolverCls(dataContentType);
        return new resolverCls();
      }
    }
    return new (this._getDataResolverCls("application/json"))();
  }

  private _getDataResolverCls(dataContentType: string): typeof BaseDataResolver {
    return dataResolverMap.get(dataContentType) || JsonResolver;
  }
}
