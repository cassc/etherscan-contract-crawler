// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

/// @title incentive contract interface
/// @notice Called by uAD token contract when transferring with an incentivized address
/// @dev should be appointed as a Minter or Burner as needed
interface IIncentive {
    /// @notice apply incentives on transfer
    /// @param sender the sender address of uAD
    /// @param receiver the receiver address of uAD
    /// @param operator the operator (msg.sender) of the transfer
    /// @param amount the amount of uAD transferred
    function incentivize(
        address sender,
        address receiver,
        address operator,
        uint256 amount
    ) external;
}