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

export enum RequestMethod {
  OPTIONS = "OPTIONS",
  GET = "GET",
  HEAD = "HEAD",
  POST = "POST",
  PUT = "PUT",
  DELETE = "DELETE",
  TRACE = "TRACE",
  CONNECT = "CONNECT"
}

export interface OkhttpRequestConfig<D = any> {
  url?: string;
  method?: typeof RequestMethod;
  baseURL?: string;
  headers?: any;
  params?: any;
  data?: D;
  withCredentials?: boolean;
  responseType?: string;
  maxContentLength?: number;
  validateStatus?: ((status: number) => boolean) | null;
  maxBodyLength?: number;
  maxRedirects?: number;
  decompress?: boolean;
  insecureHTTPParser?: boolean;
  transformRequest?: OkhttpRequestTransformer | OkhttpRequestTransformer[];
  transformResponse?: OkhttpResponseTransformer | OkhttpResponseTransformer[];
  connectTimeout?: number;
  readTimeout?: number;
}

export type OkhttpResponseType = 'arraybuffer'
  | 'blob'
  | 'document'
  | 'json'
  | 'text'
  | 'stream';

export const DATA_CONTENT_TYPES = [
  "application/x-www-form-urlencoded",
  "multipart/form-data",
  "application/json",
  "text/xml"
];

export enum OkhttpContentType {
  urlencoded = "application/x-www-form-urlencoded",
  multipart = "multipart/form-data",
  json = "application/json",
  xml = "text/xml",
}

export interface OkhttpTransformer {
  (data: any, headers?: any): any;
}

export interface OkhttpRequestTransformer {
  (data: any, headers?: any): any;
}

export interface OkhttpResponseTransformer {
  (data: any, headers?: any): any;
}