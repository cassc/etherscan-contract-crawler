// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

/// @dev A simplified version of the WETH
interface IWETH9Like {
    function deposit() external payable;
    function withdraw(uint256 _amount) external;
}