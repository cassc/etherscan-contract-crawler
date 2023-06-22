// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "OpenZeppelin/[email protected]/contracts/access/Ownable.sol";
import "../interfaces/IMessenger.sol";

/// A helper contract that provides a way to restrict callers of restricted functions
/// to a single address. This allows for a trusted call chain,
/// as described in :ref:`contracts' architecture <contracts-architecture>`.
contract RestrictedCalls is Ownable {
    /// Maps caller chain IDs to tuples [caller, messenger].
    ///
    /// For same-chain calls, the messenger address is 0x0.
    mapping(uint256 callerChainId => address[2]) public callers;

    function _addCaller(
        uint256 callerChainId,
        address caller,
        address messenger
    ) internal {
        require(caller != address(0), "RestrictedCalls: caller cannot be 0");
        require(
            callers[callerChainId][0] == address(0),
            "RestrictedCalls: caller already exists"
        );
        callers[callerChainId] = [caller, messenger];
    }

    /// Allow calls from an address on the same chain.
    ///
    /// @param caller The caller.
    function addCaller(address caller) external onlyOwner {
        _addCaller(block.chainid, caller, address(0));
    }

    /// Allow calls from an address on another chain.
    ///
    /// @param callerChainId The caller's chain ID.
    /// @param caller The caller.
    /// @param messenger The messenger.
    function addCaller(
        uint256 callerChainId,
        address caller,
        address messenger
    ) external onlyOwner {
        _addCaller(callerChainId, caller, messenger);
    }

    /// Mark the function as restricted.
    ///
    /// Calls to the restricted function can only come from an address that
    /// was previously added by a call to :sol:func:`addCaller`.
    ///
    /// Example usage::
    ///
    ///     restricted(block.chainid)   // expecting calls from the same chain
    ///     restricted(otherChainId)    // expecting calls from another chain
    ///
    modifier restricted(uint256 callerChainId) {
        address caller = callers[callerChainId][0];

        if (callerChainId == block.chainid) {
            require(msg.sender == caller, "RestrictedCalls: call disallowed");
        } else {
            address messenger = callers[callerChainId][1];
            require(
                messenger != address(0),
                "RestrictedCalls: messenger not set"
            );
            require(
                IMessenger(messenger).callAllowed(caller, msg.sender),
                "RestrictedCalls: call disallowed"
            );
        }
        _;
    }
}