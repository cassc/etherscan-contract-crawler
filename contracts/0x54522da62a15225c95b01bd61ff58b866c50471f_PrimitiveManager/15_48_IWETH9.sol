// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.6;

import "./IERC20.sol";

/// @title   Interface for WETH9
/// @author  Primitive
interface IWETH9 is IERC20 {
    /// @notice Wraps ETH into WETH
    function deposit() external payable;

    /// @notice Unwraps WETH into ETH
    function withdraw(uint256) external;
}