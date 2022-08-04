// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2022 Coinbase Inc.
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

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "@0x/contracts-zero-ex/contracts/src/fixins/FixinERC1155Spender.sol";
import "@0x/contracts-zero-ex/contracts/src/features/libs/LibNFTOrder.sol";
import "@0x/contracts-zero-ex/contracts/src/features/libs/LibSignature.sol";

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155Holder.sol";

/// @dev Wrapper for ERC721OrdersFeature and ERC1155OrdersFeature  to route purchase to target.
/// Don't send any ETH or ERC20-token to this contract
contract ZeroExV4NftWrapper is ERC721Holder, ERC1155Holder, FixinERC1155Spender {

    // Proxy contract https://github.com/0xProject/protocol/blob/refactor/nft-orders/contracts/zero-ex/contracts/src/ZeroEx.sol
    address internal immutable zeroExGateway = 0xDef1C0ded9bec7F1a1670819833240f027b25EfF; 

    constructor() public {}

    /// @dev Transfers an ERC721 asset from `maker` to `recipient`.
    /// @param sellOrder The ERC721 sell order.
    /// @param signature The order signature.
    /// @param callbackData If this parameter is non-zero, invokes
    ///        `zeroExERC721OrderCallback` on `msg.sender` after
    ///        the ERC721 asset has been transferred to `msg.sender`
    ///        but before transferring the ERC20 tokens to the seller.
    ///        Native tokens acquired during the callback can be used
    ///        to fill the order.
    /// @param recipient address to transfer ERC721 asset.
    function buyERC721For(
      LibNFTOrder.ERC721Order calldata sellOrder,
      LibSignature.Signature  calldata signature,
      bytes memory callbackData,
      address recipient
    ) external payable {

        // buyERC721(ERC721Order, Signature, bytes) selector -> 0xfbee349d
        (bool success, bytes memory returnData) =  zeroExGateway.call{value: msg.value}(abi.encodeWithSelector(0xfbee349d, sellOrder, signature, callbackData));
        require(success, string(returnData));

       // Transfer ERC721 asset to target
       IERC721(address(sellOrder.erc721Token)).safeTransferFrom(address(this), recipient, sellOrder.erc721TokenId);
    }

    /// @dev Buys an ERC1155 asset by filling the given order.
    /// @param sellOrder The ERC1155 sell order.
    /// @param signature The order signature.
    /// @param erc1155BuyAmount The amount of the ERC1155 asset
    ///        to buy.
    /// @param callbackData If this parameter is non-zero, invokes
    ///        `zeroExERC1155OrderCallback` on `msg.sender` after
    ///        the ERC1155 asset has been transferred to `msg.sender`
    ///        but before transferring the ERC20 tokens to the seller.
    ///        Native tokens acquired during the callback can be used
    ///        to fill the order
    /// @param recipient address to transfer ERC1155 asset.
    function buyERC1155For(
        LibNFTOrder.ERC1155Order memory sellOrder,
        LibSignature.Signature memory signature,
        uint128 erc1155BuyAmount,
        bytes memory callbackData,
        address recipient
    ) external payable {
        
        // buyERC1155(ERC1155Order, signature, uint128, bytes) selector -> 0x7cdb54d8 
        (bool success, bytes memory returnData) =  zeroExGateway.call{value: msg.value}(abi.encodeWithSelector(0x7cdb54d8, sellOrder, signature, erc1155BuyAmount, callbackData));
        require(success, string(returnData));

       // Transfer ERC721 asset to target
       _transferERC1155AssetFrom(sellOrder.erc1155Token, address(this), recipient, sellOrder.erc1155TokenId, erc1155BuyAmount);

    }
}