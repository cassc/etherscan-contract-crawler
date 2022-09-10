// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import { CounterpartyPool } from "./CounterpartyPool.sol";
import { IMockSynth } from "./IMockSynth.sol";

interface IUniswapV2Router
{
	function WETH() external pure returns (address _WETH);
	function getAmountsOut(uint256 _amountIn, address[] calldata _path) external view returns (uint256[] memory _amounts);

	function swapExactETHForTokens(uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external payable returns (uint256[] memory amounts);
	function swapExactTokensForTokens(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external returns (uint256[] memory amounts);
}

contract TokenBridge is ReentrancyGuard
{
	using SafeERC20 for IERC20;

	address public immutable counterpartyPool;
	address public immutable mockSynth;
	address public immutable reserveToken;

	address public immutable router;
	address public immutable wrappedToken;

	constructor(address _counterpartyPool, address _router)
	{
		counterpartyPool = _counterpartyPool;
		router = _router;
		mockSynth = CounterpartyPool(_counterpartyPool).mockSynth();
		reserveToken = CounterpartyPool(_counterpartyPool).reserveToken();
		wrappedToken = IUniswapV2Router(router).WETH();
	}

	function deposit(uint256 _minShares, bool _joinCounterpartyPool) external payable nonReentrant returns (uint256 _shares)
	{
		address[] memory _path = new address[](2);
		_path[0] = wrappedToken;
		_path[1] = reserveToken;
		uint256 _amount = IUniswapV2Router(router).swapExactETHForTokens{value: msg.value}(1, _path, address(this), block.timestamp)[_path.length - 1];
		if (_joinCounterpartyPool) {
			IERC20(reserveToken).safeApprove(counterpartyPool, _amount);
			return CounterpartyPool(counterpartyPool).depositOnBehalfOf(_amount, _minShares, msg.sender);
		} else {
			_shares = _amount;
			require(_shares >= _minShares, "high slippage");
			IERC20(reserveToken).safeApprove(mockSynth, _amount);
			IMockSynth(mockSynth).deposit(msg.sender, _amount);
			return _shares;
		}
	}

	function deposit(address _token, uint256 _tokenAmount, bool _directRoute, uint256 _minShares, bool _joinCounterpartyPool) external nonReentrant returns (uint256 _shares)
	{
		IERC20(_token).safeTransferFrom(msg.sender, address(this), _tokenAmount);
		uint256 _amount;
		if (_token == reserveToken) {
			_amount = _tokenAmount;
		} else {
			IERC20(_token).safeApprove(router, _tokenAmount);
			address[] memory _path;
			if (_directRoute) {
				_path = new address[](2);
				_path[0] = _token;
				_path[1] = reserveToken;
			} else {
				_path = new address[](3);
				_path[0] = _token;
				_path[1] = wrappedToken;
				_path[2] = reserveToken;
			}
			_amount = IUniswapV2Router(router).swapExactTokensForTokens(_tokenAmount, 1, _path, address(this), block.timestamp)[_path.length - 1];
		}
		if (_joinCounterpartyPool) {
			IERC20(reserveToken).safeApprove(counterpartyPool, _amount);
			return CounterpartyPool(counterpartyPool).depositOnBehalfOf(_amount, _minShares, msg.sender);
		} else {
			_shares = _amount;
			require(_shares >= _minShares, "high slippage");
			IERC20(reserveToken).safeApprove(mockSynth, _amount);
			IMockSynth(mockSynth).deposit(msg.sender, _amount);
			return _shares;
		}
	}
}