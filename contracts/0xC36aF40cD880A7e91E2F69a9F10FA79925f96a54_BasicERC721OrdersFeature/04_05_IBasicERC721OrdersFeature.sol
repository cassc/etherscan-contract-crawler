// SPDX-License-Identifier: Apache-2.0
/*

  Copyright 2022 Element.Market Intl.

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

pragma solidity ^0.8.15;


interface IBasicERC721OrdersFeature {

    /// @param data1 [96 bits(ethAmount) + 160 bits(maker)]
    /// @param data2 [32 bits(listingTime) + 32 bits(expiryTime) + 32 bits(unused) + 160 bits(taker)]
    /// @param data3 [64 bits(nonce) + 8 bits(v) + 24 bits(unused) + 160 bits(nftAddress)]
    /// @param fee1 [96 bits(ethAmount) + 160 bits(recipient)]
    /// @param fee2 [96 bits(ethAmount) + 160 bits(recipient)]
    struct BasicOrderParameter {
        uint256 data1;
        uint256 data2;
        uint256 data3;
        uint256 nftId;
        uint256 fee1;
        uint256 fee2;
        bytes32 r;
        bytes32 s;
    }

    function fillBasicERC721Order(BasicOrderParameter calldata parameter) external payable;

    /// @param parameter1 [8 bits(revertIfIncomplete) + 88 bits(unused) + 160 bits(nftAddress)]
    /// @param parameter2 [80 bits(taker part1) + 16 bits(feePercentage1) + 160 bits(feeRecipient1)]
    /// @param parameter3 [80 bits(taker part2) + 16 bits(feePercentage2) + 160 bits(feeRecipient2)]
    struct BasicOrderParameters {
        uint256 parameter1;
        uint256 parameter2;
        uint256 parameter3;
    }

    /// @param extra [96 bits(ethAmount) + 64 bits(nonce) + 8 bits(v) + 24 bits(unused)
    ///               + 32 bits(listingTime) + 32 bits(expiryTime)]
    struct BasicOrderItem {
        address maker;
        uint256 extra;
        uint256 nftId;
        bytes32 r;
        bytes32 s;
    }

    function fillBasicERC721Orders(BasicOrderParameters calldata parameters, BasicOrderItem[] calldata orders) external payable;
}