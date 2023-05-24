// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.9;

interface IUniswapV2Router
{
	function factory() external view returns (address _factory);

	function addLiquidityETH(address _token, uint256 _amountTokenDesired, uint256 _amountTokenMin, uint256 _amountETHMin, address _to, uint256 _deadline) external payable returns (uint256 _amountToken, uint256 _amountETH, uint256 _liquidity);
	function swapExactETHForTokens(uint256 _amountOutMin, address[] calldata _path, address _to, uint256 _deadline) external payable returns (uint256[] memory _amounts);
	function swapExactTokensForTokensSupportingFeeOnTransferTokens(uint256 _amountIn, uint256 _amountOutMin, address[] calldata _path, address _to, uint256 _deadline) external;
}