// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

/// The messenger interface.
///
/// Implementations of this interface are expected to transport
/// messages across the L1 <-> L2 boundary. For instance,
/// if an implementation is deployed on L1, the :sol:func:`sendMessage`
/// would send a message to a L2 chain, as determined by the implementation.
/// In order to do this, a messenger implementation may use a native
/// messenger contract. In such cases, :sol:func:`nativeMessenger` must
/// return the address of the native messenger contract.
interface IMessenger {
    /// Send a message across the L1 <-> L2 boundary.
    ///
    /// @param target The message recipient.
    /// @param message The message.
    function sendMessage(address target, bytes calldata message) external;

    /// Return whether the call is allowed or not.
    ///
    /// @param caller The caller.
    /// @param courier The contract that is trying to deliver the message.
    function callAllowed(address caller, address courier)
        external
        view
        returns (bool);
}