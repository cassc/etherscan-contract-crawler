// SPDX-License-Identifier: GNU GPLv3

pragma solidity 0.8.17;

import "@openzeppelin/[email protected]/token/ERC20/IERC20.sol";

interface IUniswapV2Pair is IERC20 {
  function burn(address to) external returns (uint amount0, uint amount1);
  function sync() external;
}