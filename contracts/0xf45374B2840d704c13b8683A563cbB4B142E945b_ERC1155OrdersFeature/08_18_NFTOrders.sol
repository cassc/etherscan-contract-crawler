// SPDX-License-Identifier: Apache-2.0
/*

  Modifications Copyright 2022 Element.Market
  Copyright 2021 ZeroEx Intl.

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

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../fixins/FixinEIP712.sol";
import "../../fixins/FixinTokenSpender.sol";
import "../../vendor/IEtherToken.sol";
import "../../vendor/IFeeRecipient.sol";
import "../libs/LibSignature.sol";
import "../libs/LibNFTOrder.sol";


/// @dev Abstract base contract inherited by ERC721OrdersFeature and NFTOrders
abstract contract NFTOrders is FixinEIP712, FixinTokenSpender {

    using LibNFTOrder for LibNFTOrder.NFTBuyOrder;

    /// @dev Native token pseudo-address.
    address constant internal NATIVE_TOKEN_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    /// @dev The WETH token contract.
    IEtherToken internal immutable WETH;
    /// @dev The implementation address of this feature.
    address internal immutable _implementation;

    /// @dev The magic return value indicating the success of a `receiveZeroExFeeCallback`.
    bytes4 private constant FEE_CALLBACK_MAGIC_BYTES = IFeeRecipient.receiveZeroExFeeCallback.selector;

    constructor(IEtherToken weth) {
        require(address(weth) != address(0), "WETH_ADDRESS_ERROR");
        WETH = weth;
        // Remember this feature's original address.
        _implementation = address(this);
    }

    event TakerDataEmitted(
        bytes32 orderHash,
        bytes takerData
    );

    struct SellParams {
        uint128 sellAmount;
        uint256 tokenId;
        bool unwrapNativeToken;
        address taker;
        address currentNftOwner;
        bytes takerData;
    }

    struct BuyParams {
        uint128 buyAmount;
        uint256 ethAvailable;
        address taker;
        bytes takerData;
    }

    // Core settlement logic for selling an NFT asset.
    function _sellNFT(
        LibNFTOrder.NFTBuyOrder memory buyOrder,
        LibSignature.Signature memory signature,
        SellParams memory params
    ) internal returns (uint256 erc20FillAmount, bytes32 orderHash) {
        LibNFTOrder.OrderInfo memory orderInfo = _getOrderInfo(buyOrder);
        orderHash = orderInfo.orderHash;

        // Check that the order can be filled.
        _validateBuyOrder(buyOrder, signature, orderInfo, params.taker, params.tokenId, params.takerData);

        // Check amount.
        if (params.sellAmount > orderInfo.remainingAmount) {
            revert("_sellNFT/EXCEEDS_REMAINING_AMOUNT");
        }

        // Update the order state.
        _updateOrderState(buyOrder.asNFTSellOrder(), orderInfo.orderHash, params.sellAmount);

        // Calculate erc20 pay amount.
        erc20FillAmount = (params.sellAmount == orderInfo.orderAmount) ?
            buyOrder.erc20TokenAmount : buyOrder.erc20TokenAmount * params.sellAmount / orderInfo.orderAmount;

        if (params.unwrapNativeToken) {
            // The ERC20 token must be WETH for it to be unwrapped.
            require(buyOrder.erc20Token == WETH, "_sellNFT/ERC20_TOKEN_MISMATCH_ERROR");

            // Transfer the WETH from the maker to the Exchange Proxy
            // so we can unwrap it before sending it to the seller.
            // TODO: Probably safe to just use WETH.transferFrom for some
            //       small gas savings
            _transferERC20TokensFrom(WETH, buyOrder.maker, address(this), erc20FillAmount);

            // Unwrap WETH into ETH.
            WETH.withdraw(erc20FillAmount);

            // Send ETH to the seller.
            _transferEth(payable(params.taker), erc20FillAmount);
        } else {
            // Transfer the ERC20 token from the buyer to the seller.
            _transferERC20TokensFrom(buyOrder.erc20Token, buyOrder.maker, params.taker, erc20FillAmount);
        }

        // Transfer the NFT asset to the buyer.
        // If this function is called from the
        // `onNFTReceived` callback the Exchange Proxy
        // holds the asset. Otherwise, transfer it from
        // the seller.
        _transferNFTAssetFrom(buyOrder.nft, params.currentNftOwner, buyOrder.maker, params.tokenId, params.sellAmount);

        // The buyer pays the order fees.
        _payFees(buyOrder.asNFTSellOrder(), buyOrder.maker, params.sellAmount, orderInfo.orderAmount, false);

        // Emit TakerData Event.
        if (params.takerData.length > 0x20) {
            _emitEventTakerData(orderHash, params.takerData);
        }
    }

    // Core settlement logic for buying an NFT asset.
    function _buyNFT(
        LibNFTOrder.NFTSellOrder memory sellOrder,
        LibSignature.Signature memory signature,
        uint128 buyAmount
    ) internal returns (uint256 erc20FillAmount, bytes32 orderHash) {
        LibNFTOrder.OrderInfo memory orderInfo = _getOrderInfo(sellOrder);
        orderHash = orderInfo.orderHash;

        // Check that the order can be filled.
        _validateSellOrder(sellOrder, signature, orderInfo, msg.sender);

        // Check amount.
        if (buyAmount > orderInfo.remainingAmount) {
            revert("_buyNFT/EXCEEDS_REMAINING_AMOUNT");
        }

        // Update the order state.
        _updateOrderState(sellOrder, orderInfo.orderHash, buyAmount);

        // Calculate erc20 pay amount.
        erc20FillAmount = (buyAmount == orderInfo.orderAmount) ?
            sellOrder.erc20TokenAmount : _ceilDiv(sellOrder.erc20TokenAmount * buyAmount, orderInfo.orderAmount);

        // Transfer the NFT asset to the buyer (`msg.sender`).
        _transferNFTAssetFrom(sellOrder.nft, sellOrder.maker, msg.sender, sellOrder.nftId, buyAmount);

        if (address(sellOrder.erc20Token) == NATIVE_TOKEN_ADDRESS) {
            // Transfer ETH to the seller.
            _transferEth(payable(sellOrder.maker), erc20FillAmount);

            // Fees are paid from the EP's current balance of ETH.
            _payFees(sellOrder, address(this), buyAmount, orderInfo.orderAmount, true);
        } else {
            // Transfer ERC20 token from the buyer to the seller.
            _transferERC20TokensFrom(sellOrder.erc20Token, msg.sender, sellOrder.maker, erc20FillAmount);

            // The buyer pays fees.
            _payFees(sellOrder, msg.sender, buyAmount, orderInfo.orderAmount, false);
        }
    }

    function _buyNFTEx(
        LibNFTOrder.NFTSellOrder memory sellOrder,
        LibSignature.Signature memory signature,
        BuyParams memory params
    ) internal returns (uint256 erc20FillAmount, bytes32 orderHash) {
        LibNFTOrder.OrderInfo memory orderInfo = _getOrderInfo(sellOrder);
        orderHash = orderInfo.orderHash;

        // Check that the order can be filled.
        _validateSellOrder(sellOrder, signature, orderInfo, params.taker);

        // Check amount.
        if (params.buyAmount > orderInfo.remainingAmount) {
            revert("_buyNFTEx/EXCEEDS_REMAINING_AMOUNT");
        }

        // Update the order state.
        _updateOrderState(sellOrder, orderInfo.orderHash, params.buyAmount);

        // Dutch Auction
        if (sellOrder.expiry >> 252 == 1) {
            uint256 count = (sellOrder.expiry >> 64) & 0xffffffff;
            if (count > 0) {
                _resetDutchAuctionTokenAmountAndFees(sellOrder, count);
            }
        }

        // Calculate erc20 pay amount.
        erc20FillAmount = (params.buyAmount == orderInfo.orderAmount) ?
            sellOrder.erc20TokenAmount : _ceilDiv(sellOrder.erc20TokenAmount * params.buyAmount, orderInfo.orderAmount);

        // Transfer the NFT asset to the buyer.
        _transferNFTAssetFrom(sellOrder.nft, sellOrder.maker, params.taker, sellOrder.nftId, params.buyAmount);

        uint256 ethAvailable = params.ethAvailable;
        if (address(sellOrder.erc20Token) == NATIVE_TOKEN_ADDRESS) {
            uint256 totalPaid = erc20FillAmount + _calcTotalFeesPaid(sellOrder.fees, params.buyAmount, orderInfo.orderAmount);
            if (ethAvailable < totalPaid) {
                // Transfer WETH from the buyer to this contract.
                uint256 withDrawAmount = totalPaid - ethAvailable;
                _transferERC20TokensFrom(WETH, msg.sender, address(this), withDrawAmount);

                // Unwrap WETH into ETH.
                WETH.withdraw(withDrawAmount);
            }

            // Transfer ETH to the seller.
            _transferEth(payable(sellOrder.maker), erc20FillAmount);

            // Fees are paid from the EP's current balance of ETH.
            _payFees(sellOrder, address(this), params.buyAmount, orderInfo.orderAmount, true);
        } else if (sellOrder.erc20Token == WETH) {
            uint256 totalFeesPaid = _calcTotalFeesPaid(sellOrder.fees, params.buyAmount, orderInfo.orderAmount);
            if (ethAvailable > totalFeesPaid) {
                uint256 depositAmount = ethAvailable - totalFeesPaid;
                if (depositAmount < erc20FillAmount) {
                    // Transfer WETH from the buyer to this contract.
                    _transferERC20TokensFrom(WETH, msg.sender, address(this), (erc20FillAmount - depositAmount));
                } else {
                    depositAmount = erc20FillAmount;
                }

                // Wrap ETH.
                WETH.deposit{value: depositAmount}();

                // Transfer WETH to the seller.
                _transferERC20Tokens(WETH, sellOrder.maker, erc20FillAmount);

                // Fees are paid from the EP's current balance of ETH.
                _payFees(sellOrder, address(this), params.buyAmount, orderInfo.orderAmount, true);
            } else {
                // Transfer WETH from the buyer to the seller.
                _transferERC20TokensFrom(WETH, msg.sender, sellOrder.maker, erc20FillAmount);

                if (ethAvailable > 0) {
                    if (ethAvailable < totalFeesPaid) {
                        // Transfer WETH from the buyer to this contract.
                        uint256 value = totalFeesPaid - ethAvailable;
                        _transferERC20TokensFrom(WETH, msg.sender, address(this), value);

                        // Unwrap WETH into ETH.
                        WETH.withdraw(value);
                    }

                    // Fees are paid from the EP's current balance of ETH.
                    _payFees(sellOrder, address(this), params.buyAmount, orderInfo.orderAmount, true);
                } else {
                    // The buyer pays fees using WETH.
                    _payFees(sellOrder, msg.sender, params.buyAmount, orderInfo.orderAmount, false);
                }
            }
        } else {
            // Transfer ERC20 token from the buyer to the seller.
            _transferERC20TokensFrom(sellOrder.erc20Token, msg.sender, sellOrder.maker, erc20FillAmount);

            // The buyer pays fees.
            _payFees(sellOrder, msg.sender, params.buyAmount, orderInfo.orderAmount, false);
        }

        // Emit TakerData Event.
        if (params.takerData.length > 0x20) {
            _emitEventTakerData(orderHash, params.takerData);
        }
    }

    function _emitEventTakerData(bytes32 orderHash, bytes memory takerData) internal {
        uint256 startPoint;
        uint256 endPoint;
        assembly {
            let data0 := mload(add(takerData, 0x20))
            // data0 == [4 bytes(magic bytes) + 24 bytes(unused) + 2 bytes(endPoint) + 2 bytes(startPoint)]
            if eq(shr(224, data0), 0xfeefeefe) {
                startPoint := and(data0, 0xffff)
                endPoint := and(shr(16, data0), 0xffff)
            }
        }

        if (startPoint >= endPoint || (endPoint + 0x20) > takerData.length) {
            return;
        }

        bytes memory data;
        bytes32 dataBefore;
        assembly {
            data := add(add(takerData, 0x20), startPoint)
            dataBefore := mload(data)
            mstore(data, sub(endPoint, startPoint))
        }

        emit TakerDataEmitted(orderHash, data);

        assembly {
            mstore(data, dataBefore)
        }
    }

    function _validateSellOrder(
        LibNFTOrder.NFTSellOrder memory sellOrder,
        LibSignature.Signature memory signature,
        LibNFTOrder.OrderInfo memory orderInfo,
        address taker
    ) internal view {
        // Taker must match the order taker, if one is specified.
        require(sellOrder.taker == address(0) || sellOrder.taker == taker, "_validateOrder/ONLY_TAKER");

        // Check that the order is valid and has not expired, been cancelled,
        // or been filled.
        require(orderInfo.status == LibNFTOrder.OrderStatus.FILLABLE, "_validateOrder/ORDER_NOT_FILL");

        // Check the signature.
        _validateOrderSignature(orderInfo.orderHash, signature, sellOrder.maker);
    }

    function _validateBuyOrder(
        LibNFTOrder.NFTBuyOrder memory buyOrder,
        LibSignature.Signature memory signature,
        LibNFTOrder.OrderInfo memory orderInfo,
        address taker,
        uint256 tokenId,
        bytes memory takerData
    ) internal view {
        // The ERC20 token cannot be ETH.
        require(address(buyOrder.erc20Token) != NATIVE_TOKEN_ADDRESS, "_validateBuyOrder/TOKEN_MISMATCH");

        // Taker must match the order taker, if one is specified.
        require(buyOrder.taker == address(0) || buyOrder.taker == taker, "_validateBuyOrder/ONLY_TAKER");

        // Check that the order is valid and has not expired, been cancelled,
        // or been filled.
        require(orderInfo.status == LibNFTOrder.OrderStatus.FILLABLE, "_validateOrder/ORDER_NOT_FILL");

        // Check that the asset with the given token ID satisfies the properties
        // specified by the order.
        _validateOrderProperties(buyOrder, tokenId, takerData);

        // Check the signature.
        _validateOrderSignature(orderInfo.orderHash, signature, buyOrder.maker);
    }

    function _resetDutchAuctionTokenAmountAndFees(LibNFTOrder.NFTSellOrder memory order, uint256 count) internal view {
        require(count <= 100000000, "COUNT_OUT_OF_SIDE");

        uint256 listingTime = (order.expiry >> 32) & 0xffffffff;
        uint256 denominator = ((order.expiry & 0xffffffff) - listingTime) * 100000000;
        uint256 multiplier = (block.timestamp - listingTime) * count;

        // Reset erc20TokenAmount
        uint256 amount = order.erc20TokenAmount;
        order.erc20TokenAmount = amount - amount * multiplier / denominator;

        // Reset fees
        for (uint256 i = 0; i < order.fees.length; i++) {
            amount = order.fees[i].amount;
            order.fees[i].amount = amount - amount * multiplier / denominator;
        }
    }

    function _resetEnglishAuctionTokenAmountAndFees(
        LibNFTOrder.NFTSellOrder memory sellOrder,
        uint256 buyERC20Amount,
        uint256 fillAmount,
        uint256 orderAmount
    ) internal pure {
        uint256 sellOrderFees = _calcTotalFeesPaid(sellOrder.fees, fillAmount, orderAmount);
        uint256 sellTotalAmount = sellOrderFees + sellOrder.erc20TokenAmount;
        if (buyERC20Amount != sellTotalAmount) {
            uint256 spread = buyERC20Amount - sellTotalAmount;
            uint256 sum;

            // Reset fees
            if (sellTotalAmount > 0) {
                for (uint256 i = 0; i < sellOrder.fees.length; i++) {
                    uint256 diff = spread * sellOrder.fees[i].amount / sellTotalAmount;
                    sellOrder.fees[i].amount += diff;
                    sum += diff;
                }
            }

            // Reset erc20TokenAmount
            sellOrder.erc20TokenAmount += spread - sum;
        }
    }

    function _ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // ceil(a / b) = floor((a + b - 1) / b)
        return (a + b - 1) / b;
    }

    function _calcTotalFeesPaid(LibNFTOrder.Fee[] memory fees, uint256 fillAmount, uint256 orderAmount) private pure returns (uint256 totalFeesPaid) {
        if (fillAmount == orderAmount) {
            for (uint256 i = 0; i < fees.length; i++) {
                totalFeesPaid += fees[i].amount;
            }
        } else {
            for (uint256 i = 0; i < fees.length; i++) {
                totalFeesPaid += fees[i].amount * fillAmount / orderAmount;
            }
        }
        return totalFeesPaid;
    }

    function _payFees(
        LibNFTOrder.NFTSellOrder memory order,
        address payer,
        uint128 fillAmount,
        uint128 orderAmount,
        bool useNativeToken
    ) internal returns (uint256 totalFeesPaid) {
        for (uint256 i = 0; i < order.fees.length; i++) {
            LibNFTOrder.Fee memory fee = order.fees[i];

            uint256 feeFillAmount = (fillAmount == orderAmount) ? fee.amount : fee.amount * fillAmount / orderAmount;

            if (useNativeToken) {
                // Transfer ETH to the fee recipient.
                _transferEth(payable(fee.recipient), feeFillAmount);
            } else {
                if (feeFillAmount > 0) {
                    // Transfer ERC20 token from payer to recipient.
                    _transferERC20TokensFrom(order.erc20Token, payer, fee.recipient, feeFillAmount);
                }
            }

            // Note that the fee callback is _not_ called if zero
            // `feeData` is provided. If `feeData` is provided, we assume
            // the fee recipient is a contract that implements the
            // `IFeeRecipient` interface.
            if (fee.feeData.length > 0) {
                // Invoke the callback
                bytes4 callbackResult = IFeeRecipient(fee.recipient).receiveZeroExFeeCallback(
                    useNativeToken ? NATIVE_TOKEN_ADDRESS : address(order.erc20Token),
                    feeFillAmount,
                    fee.feeData
                );

                // Check for the magic success bytes
                require(callbackResult == FEE_CALLBACK_MAGIC_BYTES, "_payFees/CALLBACK_FAILED");
            }

            // Sum the fees paid
            totalFeesPaid += feeFillAmount;
        }
        return totalFeesPaid;
    }

    function _validateOrderProperties(LibNFTOrder.NFTBuyOrder memory order, uint256 tokenId, bytes memory takerData) internal view {
        // If no properties are specified, check that the given
        // `tokenId` matches the one specified in the order.
        if (order.nftProperties.length == 0) {
            require(tokenId == order.nftId, "_validateProperties/TOKEN_ID_ERR");
        } else {
            // Validate each property
            for (uint256 i = 0; i < order.nftProperties.length; i++) {
                LibNFTOrder.Property memory property = order.nftProperties[i];
                // `address(0)` is interpreted as a no-op. Any token ID
                // will satisfy a property with `propertyValidator == address(0)`.
                if (address(property.propertyValidator) != address(0)) {
                    // Call the property validator and throw a descriptive error
                    // if the call reverts.
                    try property.propertyValidator.validateProperty(order.nft, tokenId, property.propertyData, takerData) {
                    } catch (bytes memory /* reason */) {
                        revert("PROPERTY_VALIDATION_FAILED");
                    }
                }
            }
        }
    }

    /// @dev Validates that the given signature is valid for the
    ///      given maker and order hash. Reverts if the signature
    ///      is not valid.
    /// @param orderHash The hash of the order that was signed.
    /// @param signature The signature to check.
    /// @param maker The maker of the order.
    function _validateOrderSignature(bytes32 orderHash, LibSignature.Signature memory signature, address maker) internal virtual view;

    /// @dev Transfers an NFT asset.
    /// @param token The address of the NFT contract.
    /// @param from The address currently holding the asset.
    /// @param to The address to transfer the asset to.
    /// @param tokenId The ID of the asset to transfer.
    /// @param amount The amount of the asset to transfer. Always
    ///        1 for ERC721 assets.
    function _transferNFTAssetFrom(address token, address from, address to, uint256 tokenId, uint256 amount) internal virtual;

    /// @dev Updates storage to indicate that the given order
    ///      has been filled by the given amount.
    /// @param order The order that has been filled.
    /// @param orderHash The hash of `order`.
    /// @param fillAmount The amount (denominated in the NFT asset)
    ///        that the order has been filled by.
    function _updateOrderState(LibNFTOrder.NFTSellOrder memory order, bytes32 orderHash, uint128 fillAmount) internal virtual;

    /// @dev Get the order info for an NFT sell order.
    /// @param nftSellOrder The NFT sell order.
    /// @return orderInfo Info about the order.
    function _getOrderInfo(LibNFTOrder.NFTSellOrder memory nftSellOrder) internal virtual view returns (LibNFTOrder.OrderInfo memory);

    /// @dev Get the order info for an NFT buy order.
    /// @param nftBuyOrder The NFT buy order.
    /// @return orderInfo Info about the order.
    function _getOrderInfo(LibNFTOrder.NFTBuyOrder memory nftBuyOrder) internal virtual view returns (LibNFTOrder.OrderInfo memory);
}