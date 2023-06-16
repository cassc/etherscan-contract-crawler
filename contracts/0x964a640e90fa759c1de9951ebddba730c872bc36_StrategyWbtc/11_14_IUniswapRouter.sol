pragma solidity ^0.5.15;

interface IUniswapRouter {
    function swapExactTokensForTokens(uint, uint, address[] calldata, address, uint) external;
}