// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

/// @title Vote Escrow ERC20 Token Interface
/// @author Promethios
/// @notice Interface of a ERC20 token used for vote escrow. Notice that transfers and
/// allowances are disabled
interface IVeERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);
}