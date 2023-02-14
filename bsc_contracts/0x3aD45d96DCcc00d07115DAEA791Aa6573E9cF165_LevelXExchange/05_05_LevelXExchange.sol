// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.9;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import { IUniswapV2Router } from "./IUniswapV2Router.sol";

contract LevelXExchange
{
	using SafeERC20 for IERC20;

	function swapExactETHForTokensSupportingFeeOnTransferTokens(address _router, uint256 _amountOutMin, address[] calldata _path, address _to, uint256 _deadline, bytes32 _referral) external payable returns (uint256 _amountOut)
	{
		address _tokenOut = _path[_path.length - 1];
		uint256 _balanceOut = IERC20(_tokenOut).balanceOf(_to);
		IUniswapV2Router(_router).swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(_amountOutMin, _path, _to, _deadline);
		_amountOut = IERC20(_tokenOut).balanceOf(_to) - _balanceOut;
		emit Referral(address(0), _tokenOut, msg.value, _amountOut, _referral);
		return _amountOut;
	}

	function swapExactTokensForETHSupportingFeeOnTransferTokens(address _router, uint256 _amountIn, uint256 _amountOutMin, address[] calldata _path, address _to, uint256 _deadline, bytes32 _referral) external returns (uint256 _amountOut)
	{
		address _tokenIn = _path[0];
		uint256 _balanceOut = _to.balance;
		IERC20(_tokenIn).safeTransferFrom(msg.sender, address(this), _amountIn);
		uint256 _balanceIn = IERC20(_tokenIn).balanceOf(address(this));
		IERC20(_tokenIn).safeApprove(_router, _balanceIn);
		IUniswapV2Router(_router).swapExactTokensForETHSupportingFeeOnTransferTokens(_balanceIn, _amountOutMin, _path, _to, _deadline);
		_amountOut = _to.balance - _balanceOut;
		emit Referral(_tokenIn, address(0), _amountIn, _amountOut, _referral);
		return _amountOut;
	}

	function swapExactTokensForTokensSupportingFeeOnTransferTokens(address _router, uint256 _amountIn, uint256 _amountOutMin, address[] calldata _path, address _to, uint256 _deadline, bytes32 _referral) external returns (uint256 _amountOut)
	{
		address _tokenIn = _path[0];
		address _tokenOut = _path[_path.length - 1];
		uint256 _balanceOut = IERC20(_tokenOut).balanceOf(_to);
		IERC20(_tokenIn).safeTransferFrom(msg.sender, address(this), _amountIn);
		uint256 _balanceIn = IERC20(_tokenIn).balanceOf(address(this));
		IERC20(_tokenIn).safeApprove(_router, _balanceIn);
		IUniswapV2Router(_router).swapExactTokensForTokensSupportingFeeOnTransferTokens(_balanceIn, _amountOutMin, _path, _to, _deadline);
		_amountOut = IERC20(_tokenOut).balanceOf(_to) - _balanceOut;
		emit Referral(_tokenIn, _tokenOut, _amountIn, _amountOut, _referral);
		return _amountOut;
	}

	event Referral(address indexed _tokenIn, address indexed _tokenOut, uint256 _amountIn, uint256 _amountOut, bytes32 indexed _referral);
}