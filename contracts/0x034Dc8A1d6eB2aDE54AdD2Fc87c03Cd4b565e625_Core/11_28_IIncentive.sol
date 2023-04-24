// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

/// @title incentive contract interface
/// @notice Called by CHI token contract when transferring with an incentivized address
/// @dev should be appointed as a Minter or Burner as needed
interface IIncentive {
    // ----------- Chi only state changing api -----------

    /// @notice apply incentives on transfer
    /// @param sender the sender address of the CHI
    /// @param receiver the receiver address of the CHI
    /// @param operator the operator (msg.sender) of the transfer
    /// @param amount the amount of CHI transferred
    function incentivize(
        address sender,
        address receiver,
        address operator,
        uint256 amount
    ) external;
}