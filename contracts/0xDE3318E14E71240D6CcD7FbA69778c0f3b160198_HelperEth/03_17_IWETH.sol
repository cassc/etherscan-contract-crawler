// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "openzeppelin-contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

/// @title interface for weth
interface IWETH is IERC20Upgradeable {
    function deposit() external payable;

    function withdraw(uint amount) external;
}