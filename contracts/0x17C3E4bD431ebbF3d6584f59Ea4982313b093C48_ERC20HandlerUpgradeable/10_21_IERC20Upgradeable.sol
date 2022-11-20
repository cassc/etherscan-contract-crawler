// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

/// @title Interface to be used with handlers that support ERC20s and ERC721s.
/// @author Router Protocol.
interface IERC20Upgradeable {
    function transfer(address, uint256) external;

    function decimals() external view returns (uint8);
}