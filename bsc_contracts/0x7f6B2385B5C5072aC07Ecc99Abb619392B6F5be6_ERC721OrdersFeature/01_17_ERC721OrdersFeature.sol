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

import "../../fixins/FixinERC721Spender.sol";
import "../../storage/LibCommonNftOrdersStorage.sol";
import "../../storage/LibERC721OrdersStorage.sol";
import "../interfaces/IERC721OrdersFeature.sol";
import "./NFTOrders.sol";


/// @dev Feature for interacting with ERC721 orders.
contract ERC721OrdersFeature is IERC721OrdersFeature, FixinERC721Spender, NFTOrders {

    using LibNFTOrder for LibNFTOrder.NFTBuyOrder;

    /// @dev The magic return value indicating the success of a `onERC721Received`.
    bytes4 private constant ERC721_RECEIVED_MAGIC_BYTES = this.onERC721Received.selector;

    uint256 private constant ORDER_NONCE_MASK = (1 << 184) - 1;

    constructor(IEtherToken weth) NFTOrders(weth) {
    }

    /// @dev Sells an ERC721 asset to fill the given order.
    /// @param buyOrder The ERC721 buy order.
    /// @param signature The order signature from the maker.
    /// @param erc721TokenId The ID of the ERC721 asset being
    ///        sold. If the given order specifies properties,
    ///        the asset must satisfy those properties. Otherwise,
    ///        it must equal the tokenId in the order.
    /// @param unwrapNativeToken If this parameter is true and the
    ///        ERC20 token of the order is e.g. WETH, unwraps the
    ///        token before transferring it to the taker.
    function sellERC721(
        LibNFTOrder.NFTBuyOrder memory buyOrder,
        LibSignature.Signature memory signature,
        uint256 erc721TokenId,
        bool unwrapNativeToken,
        bytes memory takerData
    ) public override {
        _sellERC721(buyOrder, signature, erc721TokenId, unwrapNativeToken, msg.sender, msg.sender, takerData);
    }

    /// @dev Buys an ERC721 asset by filling the given order.
    /// @param sellOrder The ERC721 sell order.
    /// @param signature The order signature.
    function buyERC721(LibNFTOrder.NFTSellOrder memory sellOrder, LibSignature.Signature memory signature) public override payable {
        uint256 ethBalanceBefore;
        assembly { ethBalanceBefore := sub(selfbalance(), callvalue()) }

        _buyERC721(sellOrder, signature);

        if (address(this).balance != ethBalanceBefore) {
            // Refund
            _transferEth(payable(msg.sender), address(this).balance - ethBalanceBefore);
        }
    }

    function buyERC721Ex(
        LibNFTOrder.NFTSellOrder memory sellOrder,
        LibSignature.Signature memory signature,
        address taker,
        bytes memory takerData
    ) public override payable {
        uint256 ethBalanceBefore;
        assembly { ethBalanceBefore := sub(selfbalance(), callvalue()) }

        _buyERC721Ex(sellOrder, signature, taker, msg.value, takerData);

        if (address(this).balance != ethBalanceBefore) {
            // Refund
            _transferEth(payable(msg.sender), address(this).balance - ethBalanceBefore);
        }
    }

    /// @dev Cancel a single ERC721 order by its nonce. The caller
    ///      should be the maker of the order. Silently succeeds if
    ///      an order with the same nonce has already been filled or
    ///      cancelled.
    /// @param orderNonce The order nonce.
    function cancelERC721Order(uint256 orderNonce) public override {
        // Mark order as cancelled
        _setOrderStatusBit(msg.sender, orderNonce);
        emit ERC721OrderCancelled(msg.sender, orderNonce);
    }

    /// @dev Cancel multiple ERC721 orders by their nonces. The caller
    ///      should be the maker of the orders. Silently succeeds if
    ///      an order with the same nonce has already been filled or
    ///      cancelled.
    /// @param orderNonces The order nonces.
    function batchCancelERC721Orders(uint256[] calldata orderNonces) external override {
        for (uint256 i = 0; i < orderNonces.length; i++) {
            cancelERC721Order(orderNonces[i]);
        }
    }

    /// @dev Buys multiple ERC721 assets by filling the
    ///      given orders.
    /// @param sellOrders The ERC721 sell orders.
    /// @param signatures The order signatures.
    /// @param revertIfIncomplete If true, reverts if this
    ///        function fails to fill any individual order.
    /// @return successes An array of booleans corresponding to whether
    ///         each order in `orders` was successfully filled.
    function batchBuyERC721s(
        LibNFTOrder.NFTSellOrder[] memory sellOrders,
        LibSignature.Signature[] memory signatures,
        bool revertIfIncomplete
    ) public override payable returns (bool[] memory successes) {
        // Array length must match.
        uint256 length = sellOrders.length;
        require(length == signatures.length, "ARRAY_LENGTH_MISMATCH");

        successes = new bool[](length);
        uint256 ethBalanceBefore = address(this).balance - msg.value;

        if (revertIfIncomplete) {
            for (uint256 i = 0; i < length; i++) {
                // Will revert if _buyERC721 reverts.
                _buyERC721(sellOrders[i], signatures[i]);
                successes[i] = true;
            }
        } else {
            for (uint256 i = 0; i < length; i++) {
                // Delegatecall `buyERC721FromProxy` to swallow reverts while
                // preserving execution context.
                (successes[i], ) = _implementation.delegatecall(
                    abi.encodeWithSelector(this.buyERC721FromProxy.selector, sellOrders[i], signatures[i])
                );
            }
        }

        // Refund
       _transferEth(payable(msg.sender), address(this).balance - ethBalanceBefore);
    }

    function batchBuyERC721sEx(
        LibNFTOrder.NFTSellOrder[] memory sellOrders,
        LibSignature.Signature[] memory signatures,
        address[] calldata takers,
        bytes[] memory takerDatas,
        bool revertIfIncomplete
    ) public override payable returns (bool[] memory successes) {
        // All array length must match.
        uint256 length = sellOrders.length;
        require(length == signatures.length && length == takers.length && length == takerDatas.length, "ARRAY_LENGTH_MISMATCH");

        successes = new bool[](length);
        uint256 ethBalanceBefore = address(this).balance - msg.value;

        if (revertIfIncomplete) {
            for (uint256 i = 0; i < length; i++) {
                // Will revert if _buyERC721Ex reverts.
                _buyERC721Ex(sellOrders[i], signatures[i], takers[i], address(this).balance - ethBalanceBefore, takerDatas[i]);
                successes[i] = true;
            }
        } else {
            for (uint256 i = 0; i < length; i++) {
                // Delegatecall `buyERC721ExFromProxy` to swallow reverts while
                // preserving execution context.
                (successes[i], ) = _implementation.delegatecall(
                    abi.encodeWithSelector(this.buyERC721ExFromProxy.selector, sellOrders[i], signatures[i], takers[i],
                        address(this).balance - ethBalanceBefore, takerDatas[i])
                );
            }
        }

        // Refund
       _transferEth(payable(msg.sender), address(this).balance - ethBalanceBefore);
    }

    // @Note `buyERC721FromProxy` is a external function, must call from an external Exchange Proxy,
    //        but should not be registered in the Exchange Proxy.
    function buyERC721FromProxy(LibNFTOrder.NFTSellOrder memory sellOrder, LibSignature.Signature memory signature) external payable {
        require(_implementation != address(this), "MUST_CALL_FROM_PROXY");
        _buyERC721(sellOrder, signature);
    }

    // @Note `buyERC721ExFromProxy` is a external function, must call from an external Exchange Proxy,
    //        but should not be registered in the Exchange Proxy.
    function buyERC721ExFromProxy(LibNFTOrder.NFTSellOrder memory sellOrder, LibSignature.Signature memory signature, address taker, uint256 ethAvailable, bytes memory takerData) external payable {
        require(_implementation != address(this), "MUST_CALL_FROM_PROXY");
        _buyERC721Ex(sellOrder, signature, taker, ethAvailable, takerData);
    }

    /// @dev Matches a pair of complementary orders that have
    ///      a non-negative spread. Each order is filled at
    ///      their respective price, and the matcher receives
    ///      a profit denominated in the ERC20 token.
    /// @param sellOrder Order selling an ERC721 asset.
    /// @param buyOrder Order buying an ERC721 asset.
    /// @param sellOrderSignature Signature for the sell order.
    /// @param buyOrderSignature Signature for the buy order.
    /// @return profit The amount of profit earned by the caller
    ///         of this function (denominated in the ERC20 token
    ///         of the matched orders).
    function matchERC721Orders(
        LibNFTOrder.NFTSellOrder memory sellOrder,
        LibNFTOrder.NFTBuyOrder memory buyOrder,
        LibSignature.Signature memory sellOrderSignature,
        LibSignature.Signature memory buyOrderSignature
    ) public override returns (uint256 profit) {
        // The ERC721 tokens must match
        require(sellOrder.nft == buyOrder.nft, "ERC721_TOKEN_MISMATCH_ERROR");

        LibNFTOrder.OrderInfo memory sellOrderInfo = _getOrderInfo(sellOrder);
        LibNFTOrder.OrderInfo memory buyOrderInfo = _getOrderInfo(buyOrder);

        _validateSellOrder(sellOrder, sellOrderSignature, sellOrderInfo, buyOrder.maker);
        _validateBuyOrder(buyOrder, buyOrderSignature, buyOrderInfo, sellOrder.maker, sellOrder.nftId, "");

        // English Auction
        if (sellOrder.expiry >> 252 == 2) {
            _resetEnglishAuctionTokenAmountAndFees(sellOrder, buyOrder.erc20TokenAmount, 1, 1);
        }

        // Mark both orders as filled.
        _updateOrderState(sellOrder, sellOrderInfo.orderHash, 1);
        _updateOrderState(buyOrder.asNFTSellOrder(), buyOrderInfo.orderHash, 1);

        // The difference in ERC20 token amounts is the spread.
        uint256 spread = buyOrder.erc20TokenAmount - sellOrder.erc20TokenAmount;

        // Transfer the ERC721 asset from seller to buyer.
        _transferERC721AssetFrom(sellOrder.nft, sellOrder.maker, buyOrder.maker, sellOrder.nftId);

        // Handle the ERC20 side of the order:
        if (address(sellOrder.erc20Token) == NATIVE_TOKEN_ADDRESS && buyOrder.erc20Token == WETH) {
            // The sell order specifies ETH, while the buy order specifies WETH.
            // The orders are still compatible with one another, but we'll have
            // to unwrap the WETH on behalf of the buyer.

            // Step 1: Transfer WETH from the buyer to the EP.
            //         Note that we transfer `buyOrder.erc20TokenAmount`, which
            //         is the amount the buyer signaled they are willing to pay
            //         for the ERC721 asset, which may be more than the seller's
            //         ask.
            _transferERC20TokensFrom(WETH, buyOrder.maker, address(this), buyOrder.erc20TokenAmount);

            // Step 2: Unwrap the WETH into ETH. We unwrap the entire
            //         `buyOrder.erc20TokenAmount`.
            //         The ETH will be used for three purposes:
            //         - To pay the seller
            //         - To pay fees for the sell order
            //         - Any remaining ETH will be sent to
            //           `msg.sender` as profit.
            WETH.withdraw(buyOrder.erc20TokenAmount);

            // Step 3: Pay the seller (in ETH).
            _transferEth(payable(sellOrder.maker), sellOrder.erc20TokenAmount);

            // Step 4: Pay fees for the buy order. Note that these are paid
            //         in _WETH_ by the _buyer_. By signing the buy order, the
            //         buyer signals that they are willing to spend a total
            //         of `erc20TokenAmount` _plus_ fees, all denominated in
            //         the `erc20Token`, which in this case is WETH.
            _payFees(buyOrder.asNFTSellOrder(), buyOrder.maker, 1, 1, false);

            // Step 5: Pay fees for the sell order. The `erc20Token` of the
            //         sell order is ETH, so the fees are paid out in ETH.
            //         There should be `spread` wei of ETH remaining in the
            //         EP at this point, which we will use ETH to pay the
            //         sell order fees.
            uint256 sellOrderFees = _payFees(sellOrder, address(this), 1, 1, true);

            // Step 6: The spread less the sell order fees is the amount of ETH
            //         remaining in the EP that can be sent to `msg.sender` as
            //         the profit from matching these two orders.
            profit = spread - sellOrderFees;
            if (profit > 0) {
                _transferEth(payable(msg.sender), profit);
            }
        } else {
            // ERC20 tokens must match
            require(sellOrder.erc20Token == buyOrder.erc20Token, "ERC20_TOKEN_MISMATCH_ERROR");

            // Step 1: Transfer the ERC20 token from the buyer to the seller.
            //         Note that we transfer `sellOrder.erc20TokenAmount`, which
            //         is at most `buyOrder.erc20TokenAmount`.
            _transferERC20TokensFrom(buyOrder.erc20Token, buyOrder.maker, sellOrder.maker, sellOrder.erc20TokenAmount);

            // Step 2: Pay fees for the buy order. Note that these are paid
            //         by the buyer. By signing the buy order, the buyer signals
            //         that they are willing to spend a total of
            //         `buyOrder.erc20TokenAmount` _plus_ `buyOrder.fees`.
            _payFees(buyOrder.asNFTSellOrder(), buyOrder.maker, 1, 1, false);

            // Step 3: Pay fees for the sell order. These are paid by the buyer
            //         as well. After paying these fees, we may have taken more
            //         from the buyer than they agreed to in the buy order. If
            //         so, we revert in the following step.
            uint256 sellOrderFees = _payFees(sellOrder, buyOrder.maker, 1, 1, false);

            // Step 4: We calculate the profit as:
            //         profit = buyOrder.erc20TokenAmount - sellOrder.erc20TokenAmount - sellOrderFees
            //                = spread - sellOrderFees
            //         I.e. the buyer would've been willing to pay up to `profit`
            //         more to buy the asset, so instead that amount is sent to
            //         `msg.sender` as the profit from matching these two orders.
            profit = spread - sellOrderFees;
            if (profit > 0) {
                _transferERC20TokensFrom(buyOrder.erc20Token, buyOrder.maker, msg.sender, profit);
            }
        }

        _emitEventSellOrderFilled(
            sellOrder,
            buyOrder.maker,
            sellOrderInfo.orderHash
        );

        _emitEventBuyOrderFilled(
            buyOrder,
            sellOrder.maker,
            sellOrder.nftId,
            buyOrderInfo.orderHash
        );
    }

    /// @dev Matches pairs of complementary orders that have
    ///      non-negative spreads. Each order is filled at
    ///      their respective price, and the matcher receives
    ///      a profit denominated in the ERC20 token.
    /// @param sellOrders Orders selling ERC721 assets.
    /// @param buyOrders Orders buying ERC721 assets.
    /// @param sellOrderSignatures Signatures for the sell orders.
    /// @param buyOrderSignatures Signatures for the buy orders.
    /// @return profits The amount of profit earned by the caller
    ///         of this function for each pair of matched orders
    ///         (denominated in the ERC20 token of the order pair).
    /// @return successes An array of booleans corresponding to
    ///         whether each pair of orders was successfully matched.
    function batchMatchERC721Orders(
        LibNFTOrder.NFTSellOrder[] memory sellOrders,
        LibNFTOrder.NFTBuyOrder[] memory buyOrders,
        LibSignature.Signature[] memory sellOrderSignatures,
        LibSignature.Signature[] memory buyOrderSignatures
    ) public override returns (uint256[] memory profits, bool[] memory successes) {
        // All array length must match.
        uint256 length = sellOrders.length;
        require(length == buyOrders.length && length == sellOrderSignatures.length && length == buyOrderSignatures.length, "ARRAY_LENGTH_MISMATCH");

        profits = new uint256[](length);
        successes = new bool[](length);

        for (uint256 i = 0; i < length; i++) {
            bytes memory returnData;
            // Delegatecall `matchERC721Orders` to catch reverts while
            // preserving execution context.
            (successes[i], returnData) = _implementation.delegatecall(
                abi.encodeWithSelector(this.matchERC721Orders.selector, sellOrders[i], buyOrders[i],
                    sellOrderSignatures[i], buyOrderSignatures[i])
            );
            if (successes[i]) {
                // If the matching succeeded, record the profit.
                (uint256 profit) = abi.decode(returnData, (uint256));
                profits[i] = profit;
            }
        }
    }

    /// @dev Callback for the ERC721 `safeTransferFrom` function.
    ///      This callback can be used to sell an ERC721 asset if
    ///      a valid ERC721 order, signature and `unwrapNativeToken`
    ///      are encoded in `data`. This allows takers to sell their
    ///      ERC721 asset without first calling `setApprovalForAll`.
    /// @param operator The address which called `safeTransferFrom`.
    /// @param tokenId The ID of the asset being transferred.
    /// @param data Additional data with no specified format. If a
    ///        valid ERC721 order, signature and `unwrapNativeToken`
    ///        are encoded in `data`, this function will try to fill
    ///        the order using the received asset.
    /// @return success The selector of this function (0x150b7a02),
    ///         indicating that the callback succeeded.
    function onERC721Received(address operator, address /* from */, uint256 tokenId, bytes calldata data) external override returns (bytes4 success) {
        // Decode the order, signature, and `unwrapNativeToken` from
        // `data`. If `data` does not encode such parameters, this
        // will throw.
        (LibNFTOrder.NFTBuyOrder memory buyOrder, LibSignature.Signature memory signature, bool unwrapNativeToken)
            = abi.decode(data, (LibNFTOrder.NFTBuyOrder, LibSignature.Signature, bool));

        // `onERC721Received` is called by the ERC721 token contract.
        // Check that it matches the ERC721 token in the order.
        require(msg.sender == buyOrder.nft, "ERC721_TOKEN_MISMATCH_ERROR");

        // operator taker
        // address(this) owner (we hold the NFT currently)
        _sellERC721(buyOrder, signature, tokenId, unwrapNativeToken, operator, address(this), new bytes(0));

        return ERC721_RECEIVED_MAGIC_BYTES;
    }

    /// @dev Approves an ERC721 sell order on-chain. After pre-signing
    ///      the order, the `PRESIGNED` signature type will become
    ///      valid for that order and signer.
    /// @param order An ERC721 sell order.
    function preSignERC721SellOrder(LibNFTOrder.NFTSellOrder memory order) public override {
        require(order.maker == msg.sender, "ONLY_MAKER");

        uint256 hashNonce = LibCommonNftOrdersStorage.getStorage().hashNonces[order.maker];
        bytes32 orderHash = getERC721SellOrderHash(order);
        LibERC721OrdersStorage.getStorage().preSigned[orderHash] = (hashNonce + 1);

        emit ERC721SellOrderPreSigned(order.maker, order.taker, order.expiry, order.nonce,
            order.erc20Token, order.erc20TokenAmount, order.fees, order.nft, order.nftId);
    }

    /// @dev Approves an ERC721 buy order on-chain. After pre-signing
    ///      the order, the `PRESIGNED` signature type will become
    ///      valid for that order and signer.
    /// @param order An ERC721 buy order.
    function preSignERC721BuyOrder(LibNFTOrder.NFTBuyOrder memory order) public override {
        require(order.maker == msg.sender, "ONLY_MAKER");

        uint256 hashNonce = LibCommonNftOrdersStorage.getStorage().hashNonces[order.maker];
        bytes32 orderHash = getERC721BuyOrderHash(order);
        LibERC721OrdersStorage.getStorage().preSigned[orderHash] = (hashNonce + 1);

        emit ERC721BuyOrderPreSigned(order.maker, order.taker, order.expiry, order.nonce,
            order.erc20Token, order.erc20TokenAmount, order.fees, order.nft, order.nftId, order.nftProperties);
    }

    // Core settlement logic for selling an ERC721 asset.
    // Used by `sellERC721` and `onERC721Received`.
    function _sellERC721(
        LibNFTOrder.NFTBuyOrder memory buyOrder,
        LibSignature.Signature memory signature,
        uint256 erc721TokenId,
        bool unwrapNativeToken,
        address taker,
        address currentNftOwner,
        bytes memory takerData
    ) private {
        (, bytes32 orderHash) = _sellNFT(
            buyOrder,
            signature,
            SellParams(1, erc721TokenId, unwrapNativeToken, taker, currentNftOwner, takerData)
        );

        _emitEventBuyOrderFilled(
            buyOrder,
            taker,
            erc721TokenId,
            orderHash
        );
    }

    // Core settlement logic for buying an ERC721 asset.
    // Used by `buyERC721` and `batchBuyERC721s`.
    function _buyERC721(LibNFTOrder.NFTSellOrder memory sellOrder, LibSignature.Signature memory signature) internal {
        (, bytes32 orderHash) = _buyNFT(sellOrder, signature, 1);

        _emitEventSellOrderFilled(
            sellOrder,
            msg.sender,
            orderHash
        );
    }

    function _buyERC721Ex(
        LibNFTOrder.NFTSellOrder memory sellOrder,
        LibSignature.Signature memory signature,
        address taker,
        uint256 ethAvailable,
        bytes memory takerData
    ) internal {
        if (taker == address (0)) {
            taker = msg.sender;
        } else {
            require(taker != address(this), "_buy721Ex/TAKER_CANNOT_SELF");
        }
        (, bytes32 orderHash) = _buyNFTEx(sellOrder, signature, BuyParams(1, ethAvailable, taker, takerData));

        _emitEventSellOrderFilled(
            sellOrder,
            taker,
            orderHash
        );
    }

    function _emitEventSellOrderFilled(
        LibNFTOrder.NFTSellOrder memory sellOrder,
        address taker,
        bytes32 orderHash
    ) internal {
        Fee[] memory fees = new Fee[](sellOrder.fees.length);
        for (uint256 i; i < sellOrder.fees.length; ) {
            fees[i].recipient = sellOrder.fees[i].recipient;
            fees[i].amount = sellOrder.fees[i].amount;
            unchecked {
                sellOrder.erc20TokenAmount += fees[i].amount;
                ++i;
            }
        }

        emit ERC721SellOrderFilled(
            orderHash,
            sellOrder.maker,
            taker,
            sellOrder.nonce,
            sellOrder.erc20Token,
            sellOrder.erc20TokenAmount,
            fees,
            sellOrder.nft,
            sellOrder.nftId
        );
    }

    function _emitEventBuyOrderFilled(
        LibNFTOrder.NFTBuyOrder memory buyOrder,
        address taker,
        uint256 nftId,
        bytes32 orderHash
    ) internal {
        Fee[] memory fees = new Fee[](buyOrder.fees.length);
        for (uint256 i; i < buyOrder.fees.length; ) {
            fees[i].recipient = buyOrder.fees[i].recipient;
            fees[i].amount = buyOrder.fees[i].amount;
            unchecked {
                buyOrder.erc20TokenAmount += fees[i].amount;
                ++i;
            }
        }

        emit ERC721BuyOrderFilled(
            orderHash,
            buyOrder.maker,
            taker,
            buyOrder.nonce,
            buyOrder.erc20Token,
            buyOrder.erc20TokenAmount,
            fees,
            buyOrder.nft,
            nftId
        );
    }

    /// @dev Checks whether the given signature is valid for the
    ///      the given ERC721 sell order. Reverts if not.
    /// @param order The ERC721 sell order.
    /// @param signature The signature to validate.
    function validateERC721SellOrderSignature(LibNFTOrder.NFTSellOrder memory order, LibSignature.Signature memory signature) public override view {
        _validateOrderSignature(getERC721SellOrderHash(order), signature, order.maker);
    }

    /// @dev Checks whether the given signature is valid for the
    ///      the given ERC721 buy order. Reverts if not.
    /// @param order The ERC721 buy order.
    /// @param signature The signature to validate.
    function validateERC721BuyOrderSignature(LibNFTOrder.NFTBuyOrder memory order, LibSignature.Signature memory signature) public override view {
        _validateOrderSignature(getERC721BuyOrderHash(order), signature, order.maker);
    }

    /// @dev Validates that the given signature is valid for the
    ///      given maker and order hash. Reverts if the signature
    ///      is not valid.
    /// @param orderHash The hash of the order that was signed.
    /// @param signature The signature to check.
    /// @param maker The maker of the order.
    function _validateOrderSignature(bytes32 orderHash, LibSignature.Signature memory signature, address maker) internal override view {
        if (signature.signatureType == LibSignature.SignatureType.PRESIGNED) {
            require(LibERC721OrdersStorage.getStorage().preSigned[orderHash]
                == LibCommonNftOrdersStorage.getStorage().hashNonces[maker] + 1, "PRESIGNED_INVALID_SIGNER");
        } else {
            require(maker != address(0) && maker == ecrecover(orderHash, signature.v, signature.r, signature.s), "INVALID_SIGNER_ERROR");
        }
    }

    /// @dev Transfers an NFT asset.
    /// @param token The address of the NFT contract.
    /// @param from The address currently holding the asset.
    /// @param to The address to transfer the asset to.
    /// @param tokenId The ID of the asset to transfer.
    function _transferNFTAssetFrom(address token, address from, address to, uint256 tokenId, uint256 /* amount */) internal override {
        _transferERC721AssetFrom(token, from, to, tokenId);
    }

    /// @dev Updates storage to indicate that the given order
    ///      has been filled by the given amount.
    /// @param order The order that has been filled.
    function _updateOrderState(LibNFTOrder.NFTSellOrder memory order, bytes32 /* orderHash */, uint128 /* fillAmount */) internal override {
        _setOrderStatusBit(order.maker, order.nonce);
    }

    function _setOrderStatusBit(address maker, uint256 nonce) private {
        // The bitvector is indexed by the lower 8 bits of the nonce.
        uint256 flag = 1 << (nonce & 255);
        // Update order status bit vector to indicate that the given order
        // has been cancelled/filled by setting the designated bit to 1.
        LibERC721OrdersStorage.getStorage().orderStatusByMaker[maker][uint248((nonce >> 8) & ORDER_NONCE_MASK)] |= flag;
    }

    /// @dev Get the current status of an ERC721 sell order.
    /// @param order The ERC721 sell order.
    /// @return status The status of the order.
    function getERC721SellOrderStatus(LibNFTOrder.NFTSellOrder memory order) public override view returns (LibNFTOrder.OrderStatus) {
        // Check for listingTime.
        // Gas Optimize, listingTime only used in rare cases.
        if (order.expiry & 0xffffffff00000000 > 0) {
            if ((order.expiry >> 32) & 0xffffffff > block.timestamp) {
                return LibNFTOrder.OrderStatus.INVALID;
            }
        }

        // Check for expiryTime.
        if (order.expiry & 0xffffffff <= block.timestamp) {
            return LibNFTOrder.OrderStatus.EXPIRED;
        }

        // Check `orderStatusByMaker` state variable to see if the order
        // has been cancelled or previously filled.
        LibERC721OrdersStorage.Storage storage stor = LibERC721OrdersStorage.getStorage();

        // `orderStatusByMaker` is indexed by maker and nonce.
        uint256 orderStatusBitVector = stor.orderStatusByMaker[order.maker][uint248((order.nonce >> 8) & ORDER_NONCE_MASK)];

        // The bitvector is indexed by the lower 8 bits of the nonce.
        uint256 flag = 1 << (order.nonce & 255);

        // If the designated bit is set, the order has been cancelled or
        // previously filled, so it is now unfillable.
        if (orderStatusBitVector & flag != 0) {
            return LibNFTOrder.OrderStatus.UNFILLABLE;
        }

        // Otherwise, the order is fillable.
        return LibNFTOrder.OrderStatus.FILLABLE;
    }

    /// @dev Get the current status of an ERC721 buy order.
    /// @param order The ERC721 buy order.
    /// @return status The status of the order.
    function getERC721BuyOrderStatus(LibNFTOrder.NFTBuyOrder memory order) public override view returns (LibNFTOrder.OrderStatus) {
        // Only buy orders with `nftId` == 0 can be property orders.
        if (order.nftId != 0 && order.nftProperties.length > 0) {
            return LibNFTOrder.OrderStatus.INVALID;
        }

        // Buy orders cannot use ETH as the ERC20 token, since ETH cannot be
        // transferred from the buyer by a contract.
        if (address(order.erc20Token) == NATIVE_TOKEN_ADDRESS) {
            return LibNFTOrder.OrderStatus.INVALID;
        }

        return getERC721SellOrderStatus(order.asNFTSellOrder());
    }

    /// @dev Get the order info for an NFT sell order.
    /// @param nftSellOrder The NFT sell order.
    /// @return orderInfo Info about the order.
    function _getOrderInfo(LibNFTOrder.NFTSellOrder memory nftSellOrder) internal override view returns (LibNFTOrder.OrderInfo memory) {
        LibNFTOrder.OrderInfo memory orderInfo;
        orderInfo.orderHash = getERC721SellOrderHash(nftSellOrder);
        orderInfo.status = getERC721SellOrderStatus(nftSellOrder);
        orderInfo.orderAmount = 1;
        orderInfo.remainingAmount = orderInfo.status == LibNFTOrder.OrderStatus.FILLABLE ? 1 : 0;
        return orderInfo;
    }

    /// @dev Get the order info for an NFT buy order.
    /// @param nftBuyOrder The NFT buy order.
    /// @return orderInfo Info about the order.
    function _getOrderInfo(LibNFTOrder.NFTBuyOrder memory nftBuyOrder) internal override view returns (LibNFTOrder.OrderInfo memory) {
        LibNFTOrder.OrderInfo memory orderInfo;
        orderInfo.orderHash = getERC721BuyOrderHash(nftBuyOrder);
        orderInfo.status = getERC721BuyOrderStatus(nftBuyOrder);
        orderInfo.orderAmount = 1;
        orderInfo.remainingAmount = orderInfo.status == LibNFTOrder.OrderStatus.FILLABLE ? 1 : 0;
        return orderInfo;
    }

    /// @dev Get the EIP-712 hash of an ERC721 sell order.
    /// @param order The ERC721 sell order.
    /// @return orderHash The order hash.
    function getERC721SellOrderHash(LibNFTOrder.NFTSellOrder memory order) public override view returns (bytes32) {
        return _getEIP712Hash(LibNFTOrder.getNFTSellOrderStructHash(
                order, LibCommonNftOrdersStorage.getStorage().hashNonces[order.maker]));
    }

    /// @dev Get the EIP-712 hash of an ERC721 buy order.
    /// @param order The ERC721 buy order.
    /// @return orderHash The order hash.
    function getERC721BuyOrderHash(LibNFTOrder.NFTBuyOrder memory order) public override view returns (bytes32) {
        return _getEIP712Hash(LibNFTOrder.getNFTBuyOrderStructHash(
                order, LibCommonNftOrdersStorage.getStorage().hashNonces[order.maker]));
    }

    /// @dev Get the order status bit vector for the given
    ///      maker address and nonce range.
    /// @param maker The maker of the order.
    /// @param nonceRange Order status bit vectors are indexed
    ///        by maker address and the upper 248 bits of the
    ///        order nonce. We define `nonceRange` to be these
    ///        248 bits.
    /// @return bitVector The order status bit vector for the
    ///         given maker and nonce range.
    function getERC721OrderStatusBitVector(address maker, uint248 nonceRange) external override view returns (uint256) {
        uint248 range = uint248(nonceRange & ORDER_NONCE_MASK);
        return LibERC721OrdersStorage.getStorage().orderStatusByMaker[maker][range];
    }

    function getHashNonce(address maker) external override view returns (uint256) {
        return LibCommonNftOrdersStorage.getStorage().hashNonces[maker];
    }

    /// Increment a particular maker's nonce, thereby invalidating all orders that were not signed
    /// with the original nonce.
    function incrementHashNonce() external override {
        uint256 newHashNonce = ++LibCommonNftOrdersStorage.getStorage().hashNonces[msg.sender];
        emit HashNonceIncremented(msg.sender, newHashNonce);
    }
}