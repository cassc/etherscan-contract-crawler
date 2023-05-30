// SPDX-License-Identifier: GNU GPLv3

pragma solidity 0.8.18;

import "@openzeppelin/[email protected]/token/ERC20/IERC20.sol";

interface IUniswapV2Pair is IERC20 {
  function mint(address to) external returns (uint liquidity);
  function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
}