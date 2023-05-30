// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IBentToken {
    function mint(address user, uint256 cvxAmount) external;
}