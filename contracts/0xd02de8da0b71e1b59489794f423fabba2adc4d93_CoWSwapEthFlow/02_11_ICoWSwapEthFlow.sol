// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity ^0.8;

import "../libraries/EthFlowOrder.sol";

/// @title CoW Swap ETH Flow Event Interface
/// @author CoW Swap Developers
interface ICoWSwapEthFlowEvents {
    /// @dev Event emitted to notify that an order was refunded. Note that this event is not fired every time the order
    /// is invalidated (even though the user receives all unspent ETH back). This is because we want to differenciate
    /// the case where the user invalidates a valid order and when the user receives back the funds from an expired
    /// order.
    ///
    /// @param orderUid CoW Swap's unique order identifier of the order that has been invalidated (and refunded).
    /// @param refunder The address that triggered the order refund.
    event OrderRefund(bytes orderUid, address indexed refunder);
}

/// @title CoW Swap ETH Flow Interface
/// @author CoW Swap Developers
interface ICoWSwapEthFlow is ICoWSwapEthFlowEvents {
    /// @dev Error thrown when trying to create a new order whose order hash is the same as an order hash that was
    /// already assigned.
    error OrderIsAlreadyOwned(bytes32 orderHash);

    /// @dev Error thrown when trying to create an order that would be expired at the time of creation
    error OrderIsAlreadyExpired();

    /// @dev Error thrown when trying to create an order without sending the expected amount of ETH to this contract.
    error IncorrectEthAmount();

    /// @dev Error thrown when trying to create an order with a sell amount == 0
    error NotAllowedZeroSellAmount();

    /// @dev Error thrown if trying to invalidate an order while not allowed.
    error NotAllowedToInvalidateOrder(bytes32 orderHash);

    /// @dev Error thrown when unsuccessfully sending ETH to an address.
    error EthTransferFailed();

    /// @dev Function that creates and broadcasts an ETH flow order that sells native ETH. The order is paid for when
    /// the caller sends out the transaction. The caller takes ownership of the new order.
    ///
    /// @param order The data describing the order to be created. See [`EthFlowOrder.Data`] for extra information on
    /// each parameter.
    /// @return orderHash The hash of the CoW Swap order that is created to settle the new ETH order.
    function createOrder(EthFlowOrder.Data calldata order)
        external
        payable
        returns (bytes32 orderHash);

    /// @dev Marks existing ETH-flow orders as invalid and, for each order, refunds the ETH that hasn't been traded yet.
    /// The function call will not revert, if some orders are not refundable. It will silently ignore these orders.
    /// Note that some parameters of the orders are ignored, as for example the order expiration date and the quote id.
    ///
    /// @param orderArray Array of orders to be invalidated.
    function invalidateOrdersIgnoringNotAllowed(
        EthFlowOrder.Data[] calldata orderArray
    ) external;

    /// @dev Marks an existing ETH-flow order as invalid and refunds the ETH that hasn't been traded yet.
    /// Note that some parameters of the orders are ignored, as for example the order expiration date and the quote id.
    ///
    /// @param order Order to be invalidated.
    function invalidateOrder(EthFlowOrder.Data calldata order) external;

    /// @dev EIP1271-compliant onchain signature verification function.
    /// This function is used by the CoW Swap settlement contract to determine if an order that is signed with an
    /// EIP1271 signature is valid. As this contract has approved the vault relayer contract, a valid signature for an
    /// order means that the order can be traded on CoW Swap.
    ///
    /// @param orderHash Hash of the order to be signed. This is the EIP-712 signing hash for the specified order as
    /// defined in the CoW Swap settlement contract.
    /// @param signature Signature byte array. This parameter is unused since as all information needed to verify if an
    /// order is already available onchain.
    /// @return magicValue Either the EIP-1271 "magic value" indicating success (0x1626ba7e) or a different value
    /// indicating failure (0xffffffff).
    function isValidSignature(bytes32 orderHash, bytes memory signature)
        external
        view
        returns (bytes4 magicValue);

    /// @dev This function reads the  chain's native token balance of this contract (e.g., ETH for mainnet) and converts
    // the entire amount to its wrapped version (e.g., WETH).
    function wrapAll() external;

    /// @dev This function takes the specified amount of the chain's native token (e.g., ETH for mainnet) stored by this
    /// contract and converts it to its wrapped version (e.g., WETH).
    ///
    /// @param amount The amount of native tokens to convert to wrapped native tokens.
    function wrap(uint256 amount) external;

    /// @dev This function takes the specified amount of the chain's wrapped native token (e.g., WETH for mainnet)
    /// and converts it to its unwrapped version (e.g., ETH).
    ///
    /// @param amount The amount of wrapped native tokens to convert to native tokens.
    function unwrap(uint256 amount) external;
}