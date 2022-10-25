// SPDX-License-Identifier: Apache 2.0
pragma solidity >=0.8.0 <0.9.0;

import "../../interfaces/IERC20.sol";

/// @notice This contract makes it easy for clients to track ERC20.
abstract contract MixinAbstract is IERC20 {
    /// @dev Non-implemented ERC20 method.
    function transfer(address to, uint256 value) external override returns (bool success) {}

    /// @dev Non-implemented ERC20 method.
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external override returns (bool success) {}

    /// @dev Non-implemented ERC20 method.
    function approve(address spender, uint256 value) external override returns (bool success) {}

    /// @dev Non-implemented ERC20 method.
    function allowance(address owner, address spender) external view override returns (uint256) {}
}