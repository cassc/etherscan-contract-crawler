/**
 * A Multisend interface
 * SPDX-License-Identifier: MIT
 */
pragma solidity ^0.8.15;
interface IMultisend {

    /// @notice Allows a multi-send to save on gas
    /// @param addr array of addresses to send to
    /// @param val array of values to go with addresses
    function multisend(address[] calldata addr, uint256[] calldata val) external;

    /// @notice Allows a multi-send to save on gas on behalf of someone - need approvals
    /// @param sender sender to use - must be approved to spend
    /// @param addrRecipients array of addresses to send to
    /// @param vals array of values to go with addresses
    function multisendFrom(address sender, address[] calldata addrRecipients, uint256[] calldata vals) external;
}