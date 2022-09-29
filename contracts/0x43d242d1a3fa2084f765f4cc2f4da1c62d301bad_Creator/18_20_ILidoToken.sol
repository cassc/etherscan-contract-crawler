// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.13;

interface ILidoToken {
    /// @dev The address of the stETH underlying asset
    function stETH() external view returns (address);

    /// @notice Returns amount of stETH for one wstETH
    function stEthPerToken() external view returns (uint256);
}