// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

interface IUniswapConnector {
    function uniswapV3Router02() external view returns (address);

    function swapTokenForToken(address _tokenIn, address _tokenOut, uint256 _amount, uint256 _amountOutMin, address _to) external returns(uint256);

    function swapTokenForTokenV3ExactOutput(address _tokenIn, address _tokenOut, uint256 _amount, uint256 _amountInMaximum, address _to) external payable returns(uint256);
    
    function swapETHForToken(address _tokenOut, uint256 _amount, uint256 _amountOutMin, address _to) external payable returns(uint256);
}