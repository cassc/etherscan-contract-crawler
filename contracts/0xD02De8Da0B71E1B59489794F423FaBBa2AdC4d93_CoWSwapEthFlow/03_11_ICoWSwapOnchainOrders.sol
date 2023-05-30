// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity ^0.8;

import "../vendored/GPv2Order.sol";

/// @title CoW Swap Onchain Order Creator Interface
/// @author CoW Swap Developers
interface ICoWSwapOnchainOrders {
    /// @dev List of signature schemes that are supported by this contract to create orders onchain.
    enum OnchainSigningScheme {
        Eip1271,
        PreSign
    }

    /// @dev Struct containing information on the signign scheme used plus the corresponding signature.
    struct OnchainSignature {
        /// @dev The signing scheme used by the signature data.
        OnchainSigningScheme scheme;
        /// @dev The data used as an order signature.
        bytes data;
    }

    /// @dev Event emitted to broadcast an order onchain.
    ///
    /// @param sender The user who triggered the creation of the order. Note that this address does *not* need to be
    /// the actual owner of the order and does not need to be related to the order or signature in any way.
    /// For example, if a smart contract creates orders on behalf of the user, then the sender would be the user who
    /// triggers the creation of the order, while the actual owner of the order would be the smart contract that
    /// creates it.
    /// @param order Information on the order that is created in this transacion. The order is expected to be a valid
    /// order for the CoW Swap settlement contract and contain all information needed to settle it in a batch.
    /// @param signature The signature that can be used to verify the newly created order. Note that it is always
    /// possible to recover the owner of the order from a valid signature.
    /// @param data Any extra data that should be passed along with the order. This will be used by the services that
    /// collects onchain orders and no specific encoding is enforced on this field. It is supposed to encode extra
    /// information that is not included in the order data so that it can be passed along when decoding an onchain
    /// order. As an example, a contract that creates orders on behalf of a user could set a different expiration date
    /// than the one specified in the order.
    event OrderPlacement(
        address indexed sender,
        GPv2Order.Data order,
        OnchainSignature signature,
        bytes data
    );

    /// @dev Event emitted to notify that an order was invalidated.
    ///
    /// @param orderUid CoW Swap's unique order identifier of the order that has been invalidated.
    event OrderInvalidation(bytes orderUid);
}