/*
  Copyright 2019-2023 StarkWare Industries Ltd.

  Licensed under the Apache License, Version 2.0 (the "License").
  You may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  https://www.starkware.co/open-source-license/

  Unless required by applicable law or agreed to in writing,
  software distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions
  and limitations under the License.
*/
// SPDX-License-Identifier: Apache-2.0.
pragma solidity ^0.6.12;

contract StarknetBridgeConstants {
    // The selector of the deposit handler in L2.
    uint256 constant DEPOSIT_SELECTOR =
        1285101517810983806491589552491143496277809242732141897358598292095611420389;
    uint256 constant TRANSFER_FROM_STARKNET = 0;
    uint256 constant UINT256_PART_SIZE_BITS = 128;
    uint256 constant UINT256_PART_SIZE = 2**UINT256_PART_SIZE_BITS;
    string constant GOVERNANCE_TAG = "STARKWARE_DEFAULT_GOVERNANCE_INFO";
}