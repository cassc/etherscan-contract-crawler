// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IStrongX is IERC20 {
    function uniswapV2Router() external returns (address);
    function uniswapV2Pair() external returns (address);
    function WETH() external returns (address);

    function mint(address to, uint amount) external;
    function burn(uint amount) external;
}