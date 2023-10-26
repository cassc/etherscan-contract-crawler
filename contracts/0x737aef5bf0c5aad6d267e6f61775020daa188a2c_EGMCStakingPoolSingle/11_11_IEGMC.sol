// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IEGMC is IERC20 {
    function uniswapV2Router() external view returns (address);
    function uniswapV2Pair() external view returns (address);
    function WETH() external view returns (address);

    function liquidityWallet() external view returns (address);
}