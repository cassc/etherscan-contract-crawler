// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity ^0.8;

import "../vendored/GPv2Order.sol";
import "../interfaces/ICoWSwapOnchainOrders.sol";
import "../libraries/CoWSwapEip712.sol";

/// @title CoW Swap Onchain Order Creator Event Emitter
/// @author CoW Swap Developers
contract CoWSwapOnchainOrders is ICoWSwapOnchainOrders {
    using GPv2Order for GPv2Order.Data;
    using GPv2Order for bytes;

    /// @dev The domain separator for the CoW Swap settlement contract.
    bytes32 internal immutable cowSwapDomainSeparator;

    /// @param settlementContractAddress The address of CoW Swap's settlement contract on the chain where this contract
    /// is deployed.
    constructor(address settlementContractAddress) {
        cowSwapDomainSeparator = CoWSwapEip712.domainSeparator(
            settlementContractAddress
        );
    }

    /// @dev Emits an event with all information needed to execute an order onchain and returns the corresponding order
    /// hash.
    ///
    /// See [`ICoWSwapOnchainOrders.OrderPlacement`] for details on the meaning of each parameter.
    /// @return The EIP-712 hash of the order data as computed by the CoW Swap settlement contract.
    function broadcastOrder(
        address sender,
        GPv2Order.Data memory order,
        OnchainSignature memory signature,
        bytes memory data
    ) internal returns (bytes32) {
        emit OrderPlacement(sender, order, signature, data);
        return order.hash(cowSwapDomainSeparator);
    }
}