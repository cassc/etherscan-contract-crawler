// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity ^0.8;

import "../vendored/GPv2Order.sol";
import "../vendored/IERC20.sol";

/// @title CoW Swap ETH Flow Order Library
/// @author CoW Swap Developers
library EthFlowOrder {
    /// @dev Struct collecting all parameters of an ETH flow order that need to be stored onchain.
    struct OnchainData {
        /// @dev The address of the user whom the order belongs to.
        address owner;
        /// @dev The latest timestamp in seconds when the order can be settled.
        uint32 validTo;
    }

    /// @dev Data describing all parameters of an ETH flow order.
    struct Data {
        /// @dev The address of the token that should be bought for ETH. It follows the same format as in the CoW Swap
        /// contracts, meaning that the token GPv2Transfer.BUY_ETH_ADDRESS (0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
        /// represents native ETH (and should most likely not be used in this context).
        IERC20 buyToken;
        /// @dev The address that should receive the proceeds from the order. Note that using the address
        /// GPv2Order.RECEIVER_SAME_AS_OWNER (i.e., the zero address) as the receiver is not allowed.
        address receiver;
        /// @dev The exact amount of ETH that should be sold in this order.
        uint256 sellAmount;
        /// @dev The minimum amount of buyToken that should be received to settle this order.
        uint256 buyAmount;
        /// @dev Extra data to include in the order. It is used by the CoW Swap infrastructure as extra information on
        /// the order and has no direct effect on on-chain execution.
        bytes32 appData;
        /// @dev The exact amount of ETH that should be paid by the user to the CoW Swap contract after the order is
        /// settled.
        uint256 feeAmount;
        /// @dev The latest timestamp in seconds when the order can be settled.
        uint32 validTo;
        /// @dev Flag indicating whether the order is fill-or-kill or can be filled partially.
        bool partiallyFillable;
        /// @dev quoteId The quote id obtained from the CoW Swap API to lock in the current price. It is not directly
        /// used by any onchain component but is part of the information emitted onchain on order creation and may be
        /// required for an order to be automatically picked up by the CoW Swap orderbook.
        int64 quoteId;
    }

    /// @dev An order that is owned by this address is an order that has not yet been assigned.
    address internal constant NO_OWNER = address(0);

    /// @dev An order that is owned by this address is an order that has been invalidated. Note that this address cannot
    /// be directly used to create orders.
    address internal constant INVALIDATED_OWNER = address(type(uint160).max);

    /// @dev Error returned if the receiver of the ETH flow order is unspecified (`GPv2Order.RECEIVER_SAME_AS_OWNER`).
    error ReceiverMustBeSet();

    /// @dev Transforms an ETH flow order into the CoW Swap order that can be settled by the ETH flow contract.
    ///
    /// @param order The ETH flow order to be converted.
    /// @param wrappedNativeToken The address of the wrapped native token for the current network (e.g., WETH for
    /// Ethereum mainet).
    /// @return The CoW Swap order data that represents the user order in the ETH flow contract.
    function toCoWSwapOrder(Data memory order, IERC20 wrappedNativeToken)
        internal
        pure
        returns (GPv2Order.Data memory)
    {
        if (order.receiver == GPv2Order.RECEIVER_SAME_AS_OWNER) {
            // The receiver field specified which address is going to receive the proceeds from the orders. If using
            // `RECEIVER_SAME_AS_OWNER`, then the receiver is implicitly assumed by the CoW Swap Protocol to be the
            // same as the order owner.
            // However, the owner of an ETH flow order is always the ETH flow smart contract, and any ERC20 tokens sent
            // to this contract would be lost.
            revert ReceiverMustBeSet();
        }

        // Note that not all fields from `order` are used in creating the corresponding CoW Swap order.
        // For example, validTo and quoteId are ignored.
        return
            GPv2Order.Data(
                wrappedNativeToken, // IERC20 sellToken
                order.buyToken, // IERC20 buyToken
                order.receiver, // address receiver
                order.sellAmount, // uint256 sellAmount
                order.buyAmount, // uint256 buyAmount
                // This CoW Swap order is not allowed to expire. If it expired, then any solver of CoW Swap contract
                // would be allowed to clear the `filledAmount` for this order using `freeFilledAmountStorage`, making
                // it impossible to detect if the order has been previously filled.
                // Note that order.validTo is disregarded in building the CoW Swap order.
                type(uint32).max, // uint32 validTo
                order.appData, // bytes32 appData
                order.feeAmount, // uint256 feeAmount
                // Only sell orders are allowed. In a buy order, any leftover ETH would stay in the ETH flow contract
                // and would need to be sent back to the user, whose extra gas cost is usually not worth it.
                GPv2Order.KIND_SELL, // bytes32 kind
                order.partiallyFillable, // bool partiallyFillable
                // We do not currently support interacting with the Balancer vault.
                GPv2Order.BALANCE_ERC20, // bytes32 sellTokenBalance
                GPv2Order.BALANCE_ERC20 // bytes32 buyTokenBalance
            );
    }
}