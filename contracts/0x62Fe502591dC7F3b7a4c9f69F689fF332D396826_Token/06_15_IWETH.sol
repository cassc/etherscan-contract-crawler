// SPDX-License-Identifier: GNU GPLv3

pragma solidity 0.8.18;

import "@openzeppelin/[email protected]/token/ERC20/IERC20.sol";

interface IWETH is IERC20 {
  function deposit() external payable;
}