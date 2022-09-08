//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title Interface for WETH9
interface IWETH9 is IERC20 {
    /// @notice Calling deposit with msg.value returns the token
    function deposit() external payable;

    /// @notice Calling withdraw returns eth to the caller
    function withdraw(uint256) external;
}