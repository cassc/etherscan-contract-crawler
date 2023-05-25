/*

  Copyright 2021 dYdX Trading Inc.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/**
 * @title I_ExchangeProxy
 * @author dYdX
 *
 * Interface for interacting with exchanges.
 */
interface I_ExchangeProxy {

  // ============ State-Changing Functions ============

  /**
    * @notice Make a call to an exchange via proxy.
    *
    * @param  proxyExchangeData  Bytes data for the trade, specific to the exchange proxy implementation.
    */
  function proxyExchange(
    bytes calldata proxyExchangeData
  )
    external
    payable;
}