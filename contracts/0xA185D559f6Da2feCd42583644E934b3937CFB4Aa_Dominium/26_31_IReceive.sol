//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

/// @author Amit Molek
/// @dev Receive
interface IReceive {
    /// @dev Emitted on withdraw
    /// @param member the member that withdrew
    /// @param value the value that the member withdrew
    event ValueWithdrawn(address member, uint256 value);

    /// @dev Emitted on receiving value
    /// @param from the value sender
    /// @param value the received value
    event ValueReceived(address from, uint256 value);

    receive() external payable;

    /// @notice Withdraw collected funds
    /// @dev Emits `ValueWithdrawn`
    function withdraw() external;

    /// @return The value amount that the member can `withdraw` from the group
    function withdrawable(address member) external view returns (uint256);

    /// @return The total value amount withdrawable from the group
    function totalWithdrawable() external view returns (uint256);
}