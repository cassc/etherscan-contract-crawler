// SPDX-License-Identifier: MIT
pragma solidity =0.8.15;

import './IIqStaking.sol';

/// @dev An airdrop contract supporting airdrop of any token
///   by the Manager contract.
/// @title IAirdrop
/// @author gotbit
interface IAirdrop {
    // read

    /// @dev Returns the address of the Manager contract
    ///   allowed to use the contract.
    function manager() external view returns (address);

    // write

    /// @dev Change the address of the Manager contract
    function setManager(address manager_) external;

    /// @dev Airdrop any token.
    /// @param token The address of the token to airdrop.
    /// @param amount The total amount of token to airdrop.
    /// @param receivers The list of receivers with their shares of `amount`.
    function airdrop(
        address token,
        uint256 amount,
        IIqStaking.UserSharesOutput[] memory receivers
    ) external;
}