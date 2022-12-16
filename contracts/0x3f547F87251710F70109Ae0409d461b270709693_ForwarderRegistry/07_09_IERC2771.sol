// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

/// @title Secure Protocol for Native Meta Transactions.
/// @dev See https://eips.ethereum.org/EIPS/eip-2771
interface IERC2771 {
    /// @notice Checks whether a forwarder is trusted.
    /// @param forwarder The forwarder to check.
    /// @return isTrusted True if `forwarder` is trusted, false if not.
    function isTrustedForwarder(address forwarder) external view returns (bool isTrusted);
}