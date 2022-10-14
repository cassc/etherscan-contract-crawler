// SPDX-License-Identifier: Apache-2.0
/*

  Copyright 2022 Element.Market

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

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


interface IPropertyValidator {

    /// @dev Checks that the given ERC721/ERC1155 asset satisfies the properties encoded in `propertyData`.
    ///      Should revert if the asset does not satisfy the specified properties.
    /// @param tokenAddress The ERC721/ERC1155 token contract address.
    /// @param tokenId The ERC721/ERC1155 tokenId of the asset to check.
    /// @param propertyData Encoded properties or auxiliary data needed to perform the check.
    function validateProperty(address tokenAddress, uint256 tokenId, bytes calldata propertyData, bytes calldata takerData) external view;
}

/// @dev A library for validating signatures.
library LibSignature {

    /// @dev Allowed signature types.
    enum SignatureType {
        EIP712,
        PRESIGNED
    }

    /// @dev Encoded EC signature.
    struct Signature {
        // How to validate the signature.
        SignatureType signatureType;
        // EC Signature data.
        uint8 v;
        // EC Signature data.
        bytes32 r;
        // EC Signature data.
        bytes32 s;
    }
}

library LibNFTOrder {

    enum OrderStatus {
        INVALID,
        FILLABLE,
        UNFILLABLE,
        EXPIRED
    }

    struct Property {
        IPropertyValidator propertyValidator;
        bytes propertyData;
    }

    struct Fee {
        address recipient;
        uint256 amount;
        bytes feeData;
    }

    struct NFTSellOrder {
        address maker;
        address taker;
        uint256 expiry;
        uint256 nonce;
        IERC20 erc20Token;
        uint256 erc20TokenAmount;
        Fee[] fees;
        address nft;
        uint256 nftId;
    }

    // All fields except `nftProperties` align
    // with those of NFTSellOrder
    struct NFTBuyOrder {
        address maker;
        address taker;
        uint256 expiry;
        uint256 nonce;
        IERC20 erc20Token;
        uint256 erc20TokenAmount;
        Fee[] fees;
        address nft;
        uint256 nftId;
        Property[] nftProperties;
    }

    // All fields except `erc1155TokenAmount` align
    // with those of NFTSellOrder
    struct ERC1155SellOrder {
        address maker;
        address taker;
        uint256 expiry;
        uint256 nonce;
        IERC20 erc20Token;
        uint256 erc20TokenAmount;
        Fee[] fees;
        address erc1155Token;
        uint256 erc1155TokenId;
        // End of fields shared with NFTOrder
        uint128 erc1155TokenAmount;
    }

    // All fields except `erc1155TokenAmount` align
    // with those of NFTBuyOrder
    struct ERC1155BuyOrder {
        address maker;
        address taker;
        uint256 expiry;
        uint256 nonce;
        IERC20 erc20Token;
        uint256 erc20TokenAmount;
        Fee[] fees;
        address erc1155Token;
        uint256 erc1155TokenId;
        Property[] erc1155TokenProperties;
        // End of fields shared with NFTOrder
        uint128 erc1155TokenAmount;
    }

    struct OrderInfo {
        bytes32 orderHash;
        OrderStatus status;
        // `orderAmount` is 1 for all ERC721Orders, and
        // `erc1155TokenAmount` for ERC1155Orders.
        uint128 orderAmount;
        // The remaining amount of the ERC721/ERC1155 asset
        // that can be filled for the order.
        uint128 remainingAmount;
    }
}

interface IElementExCheckerFeature {

    struct ERC20CheckInfo {
        uint256 balance;            // 买家ERC20余额或ETH余额
        uint256 allowance;          // erc20.allowance(taker, elementEx)。erc20若为ETH，固定返回true
        bool balanceCheck;          // check `balance >= erc20TotalAmount`
        bool allowanceCheck;        // check `allowance >= erc20TotalAmount`，如果是NATIVE_ADDRESS默认返回true
        bool listingTimeCheck;      // check `block.timestamp >= listingTime`
        bool takerCheck;            // check `order.taker == taker || order.taker == address(0)`
    }

    struct ERC721CheckInfo {
        bool ecr721TokenIdCheck;    // 检查买家与卖家的的`ecr721TokenId`是否匹配. ecr721TokenId相等，或者满足properties条件.
        bool erc721OwnerCheck;      // 检查卖家是否是该ecr721TokenId的拥有者
        bool erc721ApprovedCheck;   // 721授权检查
        bool listingTimeCheck;      // check `block.timestamp >= listingTime`
        bool takerCheck;            // check `order.taker == taker || order.taker == address(0)`
    }

    struct ERC721SellOrderCheckInfo {
        bool success;               // 所有的检查通过时为true，只要有一项检查未通过时为false
        uint256 hashNonce;
        bytes32 orderHash;
        bool makerCheck;            // check `maker != address(0)`
        bool takerCheck;            // check `taker != ElementEx`
        bool listingTimeCheck;      // check `listingTime < expireTime`
        bool expireTimeCheck;       // check `expireTime > block.timestamp`
        bool extraCheck;            // 荷兰拍模式下，extra必须小于等于100000000
        bool nonceCheck;            // 检查订单nonce，通过检查返回true(即：订单未成交也未取消)，未通过检查返回false
        bool feesCheck;             // fee地址不能是0x地址，并且如果有回调，fee地址必须是合约地址
        bool erc20AddressCheck;     // erc20地址检查。不能为address(0)，且该地址为NATIVE_ADDRESS，或者为一个合约地址
        bool erc721AddressCheck;    // erc721地址检查，erc721合约需要实现IERC721标准
        bool erc721OwnerCheck;      // 检查maker是否是该nftId的拥有者
        bool erc721ApprovedCheck;   // 721授权检查
        uint256 erc20TotalAmount;   // erc20TotalAmount = `order.erc20TokenAmount` + totalFeesAmount
    }

    struct ERC721BuyOrderCheckInfo {
        bool success;               // 所有的检查通过时为true，只要有一项检查未通过时为false
        uint256 hashNonce;
        bytes32 orderHash;
        bool makerCheck;            // check `maker != address(0)`
        bool takerCheck;            // check `taker != ElementEx`
        bool listingTimeCheck;      // check `listingTime < expireTime`
        bool expireTimeCheck;       // check `expireTime > block.timestamp`
        bool nonceCheck;            // 检查订单nonce，通过检查返回true(即：订单未成交也未取消)，未通过检查返回false
        bool feesCheck;             // fee地址不能是0x地址，并且如果有回调，fee地址必须是合约地址
        bool propertiesCheck;       // 属性检查。若`order.nftProperties`不为空,则`nftId`必须为0，并且property地址必须是address(0)或合约地址
        bool erc20AddressCheck;     // erc20地址检查。该地址必须为一个合约地址，不能是NATIVE_ADDRESS，不能为address(0)
        bool erc721AddressCheck;    // erc721地址检查。erc721合约需要实现IERC721标准
        uint256 erc20TotalAmount;   // erc20TotalAmount = `order.erc20TokenAmount` + totalFeesAmount
        uint256 erc20Balance;       // 买家ERC20余额
        uint256 erc20Allowance;     // 买家ERC20授权额度
        bool erc20BalanceCheck;     // check `erc20Balance >= erc20TotalAmount`
        bool erc20AllowanceCheck;   // check `erc20Allowance >= erc20TotalAmount`
    }

    struct ERC1155SellOrderCheckInfo {
        bool success;               // 所有的检查通过时为true，只要有一项检查未通过时为false
        uint256 hashNonce;
        bytes32 orderHash;
        uint256 erc1155RemainingAmount; // 1155支持部分成交，remainingAmount返回订单剩余的数量
        uint256 erc1155Balance;     // erc1155.balanceOf(order.maker, order.erc1155TokenId)
        bool makerCheck;            // check `maker != address(0)`
        bool takerCheck;            // check `taker != ElementEx`
        bool listingTimeCheck;      // check `listingTime < expireTime`
        bool expireTimeCheck;       // check `expireTime > block.timestamp`
        bool extraCheck;            // 荷兰拍模式下，extra必须小于等于100000000
        bool nonceCheck;            // 检查订单nonce
        bool remainingAmountCheck;  // check `erc1155RemainingAmount > 0`
        bool feesCheck;             // fee地址不能是0x地址，并且如果有回调，fee地址必须是合约地址
        bool erc20AddressCheck;     // erc20地址检查。不能为address(0)，且该地址为NATIVE_ADDRESS，或者为一个合约地址
        bool erc1155AddressCheck;   // erc1155地址检查，erc1155合约需要实现IERC1155标准
        bool erc1155BalanceCheck;   // check `erc1155Balance >= order.erc1155TokenAmount`
        bool erc1155ApprovedCheck;  // check `erc1155.isApprovedForAll(order.maker, elementEx)`
        uint256 erc20TotalAmount;   // erc20TotalAmount = `order.erc20TokenAmount` + totalFeesAmount
    }

    struct ERC1155SellOrderTakerCheckInfo {
        uint256 erc20Balance;       // 买家ERC20余额或ETH余额
        uint256 erc20Allowance;     // erc20.allowance(taker, elementEx)。erc20若为ETH，固定返回true
        uint256 erc20WillPayAmount; // 1155支持部分成交，`erc20WillPayAmount`为部分成交所需的总费用
        bool balanceCheck;          // check `erc20Balance >= erc20WillPayAmount
        bool allowanceCheck;        // check `erc20Allowance >= erc20WillPayAmount
        bool buyAmountCheck;        // 1155支持部分成交，购买的数量不能大于订单剩余的数量，即：`erc1155BuyAmount <= erc1155RemainingAmount`
        bool listingTimeCheck;      // check `block.timestamp >= listingTime`
        bool takerCheck;            // check `order.taker == taker || order.taker == address(0)`
    }

    struct ERC1155BuyOrderCheckInfo {
        bool success;               // 所有的检查通过时为true，只要有一项检查未通过时为false
        uint256 hashNonce;
        bytes32 orderHash;
        uint256 erc1155RemainingAmount; // 1155支持部分成交，remainingAmount返回剩余未成交的数量
        bool makerCheck;            // check `maker != address(0)`
        bool takerCheck;            // check `taker != ElementEx`
        bool listingTimeCheck;      // check `listingTime < expireTime`
        bool expireTimeCheck;       // check `expireTime > block.timestamp`
        bool nonceCheck;            // 检查订单nonce
        bool remainingAmountCheck;  // check `erc1155RemainingAmount > 0`
        bool feesCheck;             // fee地址不能是0x地址，并且如果有回调，fee地址必须是合约地址
        bool propertiesCheck;       // 属性检查。若order.erc1155Properties不为空,则`order.erc1155TokenId`必须为0，并且property地址必须是address(0)或合约地址
        bool erc20AddressCheck;     // erc20地址检查。该地址必须为一个合约地址，不能是NATIVE_ADDRESS，不能为address(0)
        bool erc1155AddressCheck;   // erc1155地址检查，erc1155合约需要实现IERC1155标准
        uint256 erc20TotalAmount;   // erc20TotalAmount = `order.erc20TokenAmount` + totalFeesAmount
        uint256 erc20Balance;       // 买家ERC20余额
        uint256 erc20Allowance;     // 买家ERC20授权额度
        bool erc20BalanceCheck;     // check `erc20Balance >= erc20TotalAmount`
        bool erc20AllowanceCheck;   // check `erc20AllowanceCheck >= erc20TotalAmount`
    }

    struct ERC1155BuyOrderTakerCheckInfo {
        uint256 erc1155Balance;     // erc1155.balanceOf(taker, erc1155TokenId)
        bool ecr1155TokenIdCheck;   // 检查买家与卖家的的`ecr1155TokenId`是否匹配. ecr1155TokenId，或者满足properties条件.
        bool erc1155BalanceCheck;   // check `erc1155SellAmount <= erc1155Balance`
        bool erc1155ApprovedCheck;  // check `erc1155.isApprovedForAll(taker, elementEx)`
        bool sellAmountCheck;       // check `erc1155SellAmount <= erc1155RemainingAmount`，即：卖出的数量不能大于订单剩余的数量
        bool listingTimeCheck;      // check `block.timestamp >= listingTime`
        bool takerCheck;            // check `order.taker == taker || order.taker == address(0)`
    }

    /// 注意：taker在这里指买家，当taker为address(0)时，忽略`takerCheckInfo`，
    ///      当买家不为address(0)时，takerCheckInfo返回taker相关检查信息.
    function checkERC721SellOrder(LibNFTOrder.NFTSellOrder calldata order, address taker)
        external
        view
        returns (ERC721SellOrderCheckInfo memory info, ERC20CheckInfo memory takerCheckInfo);

    /// 注意：taker在这里指买家，当taker为address(0)时，忽略`takerCheckInfo`，
    ///      当taker不为address(0)时，takerCheckInfo返回taker相关检查信息.
    function checkERC721SellOrderEx(
        LibNFTOrder.NFTSellOrder calldata order,
        address taker,
        LibSignature.Signature calldata signature
    )
        external
        view
        returns (ERC721SellOrderCheckInfo memory info, ERC20CheckInfo memory takerCheckInfo, bool validSignature);

    /// 注意：taker在这里指卖家，当taker为address(0)时，忽略`takerCheckInfo`，
    ///      当taker不为address(0)时，takerCheckInfo返回ERC721相关检查信息.
    function checkERC721BuyOrder(LibNFTOrder.NFTBuyOrder calldata order, address taker, uint256 erc721TokenId)
        external
        view
        returns (ERC721BuyOrderCheckInfo memory info, ERC721CheckInfo memory takerCheckInfo);

    /// 注意：taker在这里指卖家，当taker为address(0)时，忽略`takerCheckInfo`，
    ///      当taker不为address(0)时，takerCheckInfo返回ERC721相关检查信息.
    function checkERC721BuyOrderEx(
        LibNFTOrder.NFTBuyOrder calldata order,
        address taker,
        uint256 erc721TokenId,
        LibSignature.Signature calldata signature
    )
        external
        view
        returns (ERC721BuyOrderCheckInfo memory info, ERC721CheckInfo memory takerCheckInfo, bool validSignature);

    /// 注意：
    ///     1.taker在这里指买家，当taker为address(0)时，忽略`takerCheckInfo`，当taker不为address(0)时，takerCheckInfo返回taker相关检查信息.
    ///     2.1155支持部分成交，erc1155BuyAmount指taker购买的数量，taker为address(0)时，该字段忽略
    function checkERC1155SellOrder(LibNFTOrder.ERC1155SellOrder calldata order, address taker, uint128 erc1155BuyAmount)
        external
        view
        returns (ERC1155SellOrderCheckInfo memory info, ERC1155SellOrderTakerCheckInfo memory takerCheckInfo);

    /// 注意：
    ///     1.taker在这里指买家，当taker为address(0)时，忽略`takerCheckInfo`，当taker不为address(0)时，takerCheckInfo返回taker相关检查信息.
    ///     2.1155支持部分成交，erc1155BuyAmount指taker购买的数量，taker为address(0)时，该字段忽略
    function checkERC1155SellOrderEx(
        LibNFTOrder.ERC1155SellOrder calldata order,
        address taker,
        uint128 erc1155BuyAmount,
        LibSignature.Signature calldata signature
    )
        external
        view
        returns (ERC1155SellOrderCheckInfo memory info, ERC1155SellOrderTakerCheckInfo memory takerCheckInfo, bool validSignature);

    /// 注意：
    ///     1.taker在这里指卖家，当taker为address(0)时，忽略`takerCheckInfo`，当taker不为address(0)时，takerCheckInfo返回ERC1155相关检查信息.
    ///     2.1155支持部分成交，erc1155SellAmount指taker卖出的数量，taker为address(0)时，该字段忽略
    function checkERC1155BuyOrder(
        LibNFTOrder.ERC1155BuyOrder calldata order,
        address taker,
        uint256 erc1155TokenId,
        uint128 erc1155SellAmount
    )
        external
        view
        returns (ERC1155BuyOrderCheckInfo memory info, ERC1155BuyOrderTakerCheckInfo memory takerCheckInfo);

    /// 注意：
    ///     1.taker在这里指卖家，当taker为address(0)时，忽略`takerCheckInfo`，当taker不为address(0)时，takerCheckInfo返回ERC1155相关检查信息.
    ///     2.1155支持部分成交，erc1155SellAmount指taker卖出的数量，taker为address(0)时，该字段忽略
    function checkERC1155BuyOrderEx(
        LibNFTOrder.ERC1155BuyOrder calldata order,
        address taker,
        uint256 erc1155TokenId,
        uint128 erc1155SellAmount,
        LibSignature.Signature calldata signature
    )
        external
        view
        returns (ERC1155BuyOrderCheckInfo memory info, ERC1155BuyOrderTakerCheckInfo memory takerCheckInfo, bool validSignature);

    function validateERC721SellOrderSignature(LibNFTOrder.NFTSellOrder calldata order, LibSignature.Signature calldata signature)
        external
        view
        returns (bool valid);

    function validateERC721BuyOrderSignature(LibNFTOrder.NFTBuyOrder calldata order, LibSignature.Signature calldata signature)
        external
        view
        returns (bool valid);

    function getERC721SellOrderHash(LibNFTOrder.NFTSellOrder calldata order) external view returns (bytes32);

    function getERC721BuyOrderHash(LibNFTOrder.NFTBuyOrder calldata order) external view returns (bytes32);

    function isERC721OrderNonceFilled(address account, uint256 nonce) external view returns (bool filled);

    function isERC1155OrderNonceCancelled(address account, uint256 nonce) external view returns (bool filled);

    function getHashNonce(address maker) external view returns (uint256);

    function getERC1155SellOrderInfo(LibNFTOrder.ERC1155SellOrder calldata order)
        external
        view
        returns (LibNFTOrder.OrderInfo memory orderInfo);

    function getERC1155BuyOrderInfo(LibNFTOrder.ERC1155BuyOrder calldata order)
        external
        view
        returns (LibNFTOrder.OrderInfo memory orderInfo);

    function validateERC1155SellOrderSignature(LibNFTOrder.ERC1155SellOrder calldata order, LibSignature.Signature calldata signature)
        external
        view
        returns (bool valid);

    function validateERC1155BuyOrderSignature(LibNFTOrder.ERC1155BuyOrder calldata order, LibSignature.Signature calldata signature)
        external
        view
        returns (bool valid);
}