// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2;

interface IPYESwapRouter {
    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path, uint totalFee) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path, uint totalFee) external view returns (uint[] memory amounts);
}