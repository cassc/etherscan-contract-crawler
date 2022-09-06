//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IV2Router {

    function addLiquidity(IERC20 tokenA, uint aAmount, IERC20 tokenB, uint bAmount)
        external 
        returns (address);

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut)
        external
        view
        returns (uint amount);
    
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut)
        external
        view
        returns (uint amount);

    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}