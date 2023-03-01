// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IPancakeswapV2Exchange.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IPancakeswapV2Factory {
    function getPair(IERC20 tokenA, IERC20 tokenB) external view returns (IPancakeswapV2Exchange pair);
}