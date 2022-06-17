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

import { DataResolverFactory } from "./dataResolver";
import { HttpMethodOptions } from "./decorators";
import http from '@ohos.net.http';
import httpclient from '@ohos/httpclient';
import {OkhttpRequestConfig } from "./constants";

interface InternalResponse<T = any>  {
  result: T;
  responseCode: number;
  header: any;
}

export interface Response<T = any> extends InternalResponse<T> {
  message(): string;
  code(): number;
  isSuccessful(): boolean;
  body(): any;
}

const NON_HTTP_REQUEST_PROPERTY_NAME = "__nonHTTPRequestMethod__";

export const nonHTTPRequestMethod = (target: any, methodName: string) => {
  const descriptor = {
    value: true,
    writable: false,
  };
  Object.defineProperty(target[methodName], NON_HTTP_REQUEST_PROPERTY_NAME, descriptor);
};

export class BaseService {
  public __meta__: any;
  private _endpoint: string;
  private _httpClient: HttpClient;
  private _methodMap: Map<string, Function>;
  private _connectTimeout: number;
  private _readTimeout: number;

  @nonHTTPRequestMethod
  public clone() : any {
    var obj = Object.create(this);
    obj._httpClient = new HttpClient();
    return obj;
  }

  constructor(serviceBuilder: ServiceBuilder) {
    this._endpoint = serviceBuilder.endpoint;
    this._httpClient = new HttpClient();
    this._methodMap = new Map<string, Function>();
    this._connectTimeout = serviceBuilder.connectTimeout;
    this._readTimeout = serviceBuilder.readTimeout;

    const methodNames = this._getInstanceMethodNames();
    methodNames.forEach((methodName) => {
      this._methodMap[methodName] = this[methodName];
    });

    for (const methodName of methodNames) {
      const descriptor = {
        enumerable: true,
        configurable: true,
        get(): Function {
          const method = this._methodMap[methodName];
          const m1 = this.__meta__[methodName];
          const methodOriginalDescriptor = Object.getOwnPropertyDescriptor(method, NON_HTTP_REQUEST_PROPERTY_NAME);
          if (methodOriginalDescriptor && methodOriginalDescriptor.value === true) {
            return method;
          }
          return (...args: any[]) => {
            return this._wrap(methodName, args);
          };
        },
      };
      Object.defineProperty(this, methodName, descriptor);
    }
  }

  @nonHTTPRequestMethod
  public setEndpoint(endpoint: string): void {
    this._endpoint = endpoint;
  }

  @nonHTTPRequestMethod
  private _getInstanceMethodNames(): string[] {
    let properties: string[] = [];
    let obj = this;
    do {
      properties = properties.concat(Object.getOwnPropertyNames(obj));
      obj = Object.getPrototypeOf(obj);
    } while (obj);
    return properties.sort().filter((e, i, arr) => {
      return e !== arr[i + 1] && this[e] && typeof this[e] === "function";
    });
  }

  @nonHTTPRequestMethod
  private _wrap(methodName: string, args: any[]): Promise<Response> {
    const { url, method, headers, query, data } = this._resolveParameters(methodName, args);
    const config = this._makeConfig(methodName, url, method, headers, query, data);
    return this._httpClient.sendRequest(config);
  }

  @nonHTTPRequestMethod
  private _resolveParameters(methodName: string, args: any[]): any {
    const url = this._resolveUrl(methodName, args);
    const method = this._resolveHttpMethod(methodName);
    let headers = this._resolveHeaders(methodName, args);
    const query = this._resolveQuery(methodName, args);
    const data = this._resolveData(methodName, headers, args);
    if (headers["content-type"] && headers["content-type"].indexOf("multipart/form-data") !== -1) {
      //headers = { ...headers, ...(data as FormData).getHeaders() };
    }
    return { url, method, headers, query, data };
  }

  @nonHTTPRequestMethod
  private _makeConfig(methodName: string, url: string, method: typeof http.RequestMethod, headers: any, query: any, data: any)
  : OkhttpRequestConfig {
    let config: OkhttpRequestConfig = {
      url,
      method,
      headers,
      params: query,
      data,
    };
    // response type
    if (this.__meta__[methodName].responseType) {
      config.responseType = this.__meta__[methodName].responseType;
    }
    // request transformer
    if (this.__meta__[methodName].requestTransformer) {
      config.transformRequest = this.__meta__[methodName].requestTransformer;
    }
    // response transformer
    if (this.__meta__[methodName].responseTransformer) {
      config.transformResponse = this.__meta__[methodName].responseTransformer;
    }
    // request connect Timeout
    config.connectTimeout = this.__meta__[methodName].connectTimeout || this._connectTimeout;

    // request read Timeout
    config.readTimeout = this.__meta__[methodName].readTimeout || this._readTimeout;
    // mix in config set by @Config
    config = {
      ...config,
      ...this.__meta__[methodName].config,
    };
    return config;
  }


  @nonHTTPRequestMethod
  private _resolveUrl(methodName: string, args: any[]): string {
    const meta = this.__meta__;
    const endpoint = this._endpoint;
    const basePath = meta.basePath;
    const path = meta[methodName].path;
    const pathParams = meta[methodName].pathParams;
    const options = meta[methodName].options || {};
    let urlArgIndex = -1;
    if (meta[methodName].urlIndex !== undefined) {
      urlArgIndex = meta[methodName].urlIndex;
    }
    let url = this.makeURL(endpoint, basePath, path, options);
    for (const pos in pathParams) {
      if (pathParams[pos]) {
        url = url.replace(new RegExp(`\{${pathParams[pos]}}`), args[pos]);
      }
    }
    if (urlArgIndex != -1) {
      url = args[urlArgIndex];
    }
    return url;
  }

  @nonHTTPRequestMethod
  private makeURL(endpoint: string, basePath: string, path: string, options: HttpMethodOptions): string {
    const isAbsoluteURL = /^([a-z][a-z\d\+\-\.]*:)?\/\//i.test(path);
    if (isAbsoluteURL) {
      return path;
    }
    if (options.ignoreBasePath) {
      return [endpoint, path].join("");
    }
    return [endpoint, basePath, path].join("");
  }

  @nonHTTPRequestMethod
  private _resolveHttpMethod(methodName: string): typeof http.RequestMethod {
    const meta = this.__meta__;
    return meta[methodName].method;
  }

  @nonHTTPRequestMethod
  private _resolveHeaders(methodName: string, args: any[]): any {
    const meta = this.__meta__;
    const headers = meta[methodName].headers || {};
    const headerParams = meta[methodName].headerParams;
    for (const pos in headerParams) {
      if (headerParams[pos]) {
        headers[headerParams[pos]] = args[pos];
      }
    }
    const headerMapIndex = meta[methodName].headerMapIndex;
    if (headerMapIndex >= 0) {
      for (const key in args[headerMapIndex]) {
        if (args[headerMapIndex][key]) {
          headers[key] = args[headerMapIndex][key];
        }
      }
    }
    return headers;
  }

  @nonHTTPRequestMethod
  private _resolveQuery(methodName: string, args: any[]): any {
    const meta = this.__meta__;
    const query = meta[methodName].query || {};
    const queryParams = meta[methodName].queryParams;
    for (const pos in queryParams) {
      if (queryParams[pos]) {
        query[queryParams[pos]] = args[pos];
      }
    }
    const queryMapIndex = meta[methodName].queryMapIndex;
    if (queryMapIndex >= 0) {
      for (const key in args[queryMapIndex]) {
        if (args[queryMapIndex][key]) {
          query[key] = args[queryMapIndex][key];
        }
      }
    }
    return query;
  }

  @nonHTTPRequestMethod
  private _resolveData(methodName: string, headers: any, args: any[]): any {
    const meta = this.__meta__;
    const bodyIndex = meta[methodName].bodyIndex;
    const fields = meta[methodName].fields || {};
    const parts = meta[methodName].parts || {};
    const fieldMapIndex = meta[methodName].fieldMapIndex;
    const gqlQuery = meta[methodName].gqlQuery;
    const gqlOperationName = meta[methodName].gqlOperationName;
    const gqlVariablesIndex = meta[methodName].gqlVariablesIndex;

    let data: any = {};

    // @Body
    if (bodyIndex >= 0) {
      if (Array.isArray(args[bodyIndex])) {
        data = args[bodyIndex];
      } else {
        if (typeof args[bodyIndex] != "object")
          data = args[bodyIndex].toString();
        else
          data = { ...data, ...args[bodyIndex] };
      }
    }

    // @Field
    if (Object.keys(fields).length > 0) {
      const reqData = {};
      for (const pos in fields) {
        if (fields[pos]) {
          reqData[fields[pos]] = args[pos];
        }
      }
      data = { ...data, ...reqData };
    }

    // @FieldMap
    if (fieldMapIndex >= 0) {
      const reqData = {};
      for (const key in args[fieldMapIndex]) {
        if (args[fieldMapIndex][key]) {
          reqData[key] = args[fieldMapIndex][key];
        }
      }
      data = { ...data, ...reqData };
    }

    // @MultiPart
    if (Object.keys(parts).length > 0) {
      const reqData = {};
      for (const pos in parts) {
        if (parts[pos]) {
          reqData[parts[pos]] = args[pos];
        }
      }
      data = { ...data, ...reqData };
    }

    // @GraphQL
    if (gqlQuery) {
      data.query = gqlQuery;
      if (gqlOperationName) {
        data.operationName = gqlOperationName;
      }
      // @GraphQLVariables
      if (gqlVariablesIndex >= 0) {
        data.variables = args[gqlVariablesIndex];
      }
    }

    const contentType = headers["content-type"] || "application/json";
    const dataResolverFactory = new DataResolverFactory();
    const dataResolver = dataResolverFactory.createDataResolver(contentType);
    return dataResolver.resolve(headers, data);
  }
}

export class ServiceBuilder {
  private _endpoint: string = "";
  private _connectTimeout: number;
  private _readTimeout: number;

  public build<T>(service: new (builder: ServiceBuilder) => T): T {
    return new service(this);
  }

  public setEndpoint(endpoint: string): ServiceBuilder {
    this._endpoint = endpoint;
    return this;
  }

  public setConnectTimeout(timeout: number): ServiceBuilder {
    this._connectTimeout = timeout;
    return this;
  }

  public setReadTimeout(timeout: number): ServiceBuilder {
    this._readTimeout = timeout;
    return this;
  }

  get endpoint(): string {
    return this._endpoint;
  }

  get connectTimeout(): number {
    return this._connectTimeout;
  }

  get readTimeout(): number {
    return this._readTimeout;
  }
}

class HttpClient {
  private httpClient: any;

  constructor() {
    this.httpClient = http.createHttp();
  }

  public async sendRequest(config: OkhttpRequestConfig): Promise<Response> {
    try {
      let options: any = {
        method: config.method,
        header: config.headers,
      };
      var requestObj = new httpclient.Request();
      requestObj.url = this.buildURL(config.url,config.params);
      if(null!=config.headers){
        requestObj.headers = config.headers;
      }
      var okhttpclient = new httpclient.HttpClient.Builder().setConnectTimeout(config.connectTimeout).setReadTimeout(config.readTimeout).build();
      let body =config.data;
      if(body) {
          body = httpclient.RequestBody.create(body);
      }
      requestObj.request(config.method,body);
      let resp = await okhttpclient.newCall(requestObj).execute();
      let header = resp.response.header
      let isJson : boolean  = header['Content-Type'] && (header['Content-Type'].includes("application/json") || header['Content-Type'].includes("application/json; charset=utf-8"));
      let internalResp = resp.response.result;
      if(isJson && resp.response.result){
        internalResp =  JSON.parse(resp.response.result);
      }
      let message = '', isSuccessful = false;
      if(resp.response.responseCode >= 200 && resp.response.responseCode < 300) {
        message = 'Response.success()';
        isSuccessful = true;
      } else {
        message = 'Response.error()';
      }
      var response: Response = {
        "result": internalResp,
        "responseCode": resp.response.responseCode,
        "header": header,
        code: () => resp.response.responseCode,
        isSuccessful: () => isSuccessful,
        message: () => message,
        body: () => internalResp
      };
      return new Promise<Response>((res, rej) => {
        res(this.forceCast<Response>(response));
      });
    } catch (err) {
      throw err;
    }
  }

  buildURL(url, params) {
    if (!params) {
      return url;
    }
    var parts = [];
    var serializedParams;
    for (var key in params) {
      if (params.hasOwnProperty(key)) {
        parts.push(key + '=' + params[key]);
      }
    }
    serializedParams = parts.join('&');
    if (serializedParams) {
      return url += (url.indexOf('?') === -1 ? '?' : '&') + serializedParams;
    }
    return url;
  }

  forceCast<T>(input: any): T {
    return input;
  }
}