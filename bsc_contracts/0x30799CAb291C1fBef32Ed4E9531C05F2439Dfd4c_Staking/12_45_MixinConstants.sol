// SPDX-License-Identifier: Apache 2.0
/*

  Original work Copyright 2019 ZeroEx Intl.
  Modified work Copyright 2020-2022 Rigo Intl.

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

pragma solidity >=0.8.0 <0.9.0;

abstract contract MixinConstants {
    // 100% in parts-per-million.
    uint32 internal constant _PPM_DENOMINATOR = 10**6;

    bytes32 internal constant _NIL_POOL_ID = 0x0000000000000000000000000000000000000000000000000000000000000000;

    address internal constant _NIL_ADDRESS = 0x0000000000000000000000000000000000000000;

    uint256 internal constant _MIN_TOKEN_VALUE = 10**18;
}