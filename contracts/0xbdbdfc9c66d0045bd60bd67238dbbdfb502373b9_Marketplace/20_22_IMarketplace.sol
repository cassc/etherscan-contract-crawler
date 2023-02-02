// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../Order.sol";

/// @title IMarketplace
/// @author filkny
/// @author nazariyv
/// @notice Marketplace interface for the RKL Marketplace
interface IMarketplace {
    /// @notice Emitted when all orders below a certain nonce are cancelled for a user
    /// @param user The address for which the orders have been cancelled
    /// @param newMinNonce The nonce below which all orders are cancelled for the user
    event CancelAllOrdersForUser(address indexed user, uint256 indexed newMinNonce);

    /// @notice Emitted when multiple orders corresponding to specific nonces are cancelled
    /// @param user The address for which the orders have been cancelled
    /// @param orderNonces The nonces of the orders that have been cancelled
    event CancelMultipleOrders(address indexed user, uint256[] indexed orderNonces);

    /// @notice Emitted when an order is successfully fulfilled
    /// @param from The seller
    /// @param to The buyer
    /// @param collection The address of the collection of the ERC721/1155 token(s) being sold
    /// @param tokenId The tokenId of the token being sold
    /// @param currency The currency being used to pay the seller
    /// @param price The total amount of currenct to be payed for the sal
    event OrderFulfilled(
        address indexed from,
        address indexed to,
        address indexed collection,
        uint256 tokenId,
        uint256 amount,
        address currency,
        uint256 price
    );

    /// @notice Fulfills an order created and signed off-chain.
    /// Call must be made by the address intending to buy in case
    /// of an ask, and the address intending to sell in the case of
    /// bid.
    ///
    /// @dev Emits a {OrderFulfilled} event.
    ///
    /// Requirements:
    /// - order.signer must be signer of the signature composed by order.r
    /// order.s and order.v
    ///
    /// @param orders The orders to be fuliflled
    function fulfillOrder(Orders.Order[] calldata orders) external;

    /// @notice Cancels multiple orders corresponding to the provided nonces
    /// @param orderNonces An array of nonces corresponding to the orders to
    /// be cancelled
    function cancelMultipleOrders(uint256[] calldata orderNonces) external;

    /// @notice Cancels all orders with nonce up until minNonce for the caller
    /// @param minNonce the nonce that the caller's minNonce should be set to
    function cancelAllOrdersForSender(uint256 minNonce) external;
}