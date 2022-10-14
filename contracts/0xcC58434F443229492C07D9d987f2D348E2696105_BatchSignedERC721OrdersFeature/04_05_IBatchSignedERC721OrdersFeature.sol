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


interface IBatchSignedERC721OrdersFeature {

    /// @param fee [16 bits(platformFeePercentage) + 16 bits(royaltyFeePercentage) + 160 bits(royaltyFeeRecipient)].
    /// @param items [96 bits(erc20TokenAmount) + 160 bits(nftId)].
    struct BasicCollection {
        address nftAddress;
        bytes32 fee;
        bytes32[] items;
    }

    struct OrderItem {
        uint256 erc20TokenAmount;
        uint256 nftId;
    }

    /// @param fee [16 bits(platformFeePercentage) + 16 bits(royaltyFeePercentage) + 160 bits(royaltyFeeRecipient)].
    struct Collection {
        address nftAddress;
        bytes32 fee;
        OrderItem[] items;
    }

    struct BatchSignedERC721Orders {
        address maker;
        uint256 listingTime;
        uint256 expiryTime;
        uint256 startNonce;
        address erc20Token;
        address platformFeeRecipient;
        BasicCollection[] basicCollections;
        Collection[] collections;
        uint256 hashNonce;
    }

    /// @param data1 [56 bits(startNonce) + 8 bits(v) + 32 bits(listingTime) + 160 bits(maker)]
    /// @param data2 [64 bits(taker part1) + 32 bits(expiryTime) + 160 bits(erc20Token)]
    /// @param data3 [96 bits(taker part2) + 160 bits(platformFeeRecipient)]
    struct BatchSignedERC721OrderParameter {
        uint256 data1;
        uint256 data2;
        uint256 data3;
        bytes32 r;
        bytes32 s;
    }

    function fillBatchSignedERC721Order(BatchSignedERC721OrderParameter calldata parameter, bytes calldata collections) external payable;

    /// @param data1 [56 bits(startNonce) + 8 bits(v) + 32 bits(listingTime) + 160 bits(maker)]
    /// @param data2 [64 bits(taker part1) + 32 bits(expiryTime) + 160 bits(erc20Token)]
    /// @param data3 [96 bits(taker part2) + 160 bits(platformFeeRecipient)]
    struct BatchSignedERC721OrderParameters {
        uint256 data1;
        uint256 data2;
        uint256 data3;
        bytes32 r;
        bytes32 s;
        bytes collections;
    }

    /// @param additional1 [96 bits(withdrawETHAmount) + 160 bits(erc20Token)]
    /// @param additional2 [8 bits(revertIfIncomplete) + 88 bits(unused) + 160 bits(royaltyFeeRecipient)]
    function fillBatchSignedERC721Orders(
        BatchSignedERC721OrderParameters[] calldata parameters,
        uint256 additional1,
        uint256 additional2
    ) external payable;
}