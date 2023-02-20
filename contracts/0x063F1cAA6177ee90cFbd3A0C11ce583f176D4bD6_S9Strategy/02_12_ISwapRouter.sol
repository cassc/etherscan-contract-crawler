pragma solidity >=0.8.17;
// SPDX-License-Identifier: MIT

interface ISwapRouter {
    function swapTokenForToken(address _tokenIn, address _tokenOut, uint256 _amount, uint256 _amountOutMin, address _to) external returns(uint256);
    function swapTokenForETH(address _tokenIn, uint256 _amount, uint256 _amountOutMin, address _to) external returns(uint256);
    function swapETHForToken(address _tokenOut, uint256 _amount, uint256 _amountOutMin, address _to) external payable returns(uint256);
    // function swap(address tokenIn, address tokenOut, uint amount, uint minAmountOut, address to) external;
    function _swapV2(address _router, address _tokenIn, uint256 _amount, address _to) external returns(uint256);
}