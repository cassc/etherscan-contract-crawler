// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.9;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Initializable } from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import { FarmingCompound } from "./FarmingCompound.sol";
import { FarmingVolatile } from "./FarmingVolatile.sol";
import { IUniswapV2Router } from "./IUniswapV2Router.sol";

/*
  VDCs
  - 40% to drip pool split between 20% Volatile/20% Compount/60% burned
  - 1:1 token multi
  - hmine Sacrifice xperps for any token choose
    - start tomorrow (6PM UTC 7th)
    - goes for a week (6PM UTC 14th)
    - price 11c
    - funds to Ghost (0xcD8dDeE99C0c4Be4cD699661AE9c00C69D1Eb4A8)
    - BUSD

  Questions:
  1- Compound for MWT
  2- 1% to bankroll
  3- farming launch coincides with end of sacrifice?
*/
contract FarmingSacrifice is Initializable, Ownable, ReentrancyGuard
{
	using SafeERC20 for IERC20;

	address constant DEFAULT_BANKROLL = 0xcD8dDeE99C0c4Be4cD699661AE9c00C69D1Eb4A8; // ghost

	uint256 constant DEFAULT_PRICE = 0.11e18; // 11c BUSD

	uint256 constant DEFAULT_HALT_TIME = 1663178400; // 2022-09-14 6PM UTC

	address public reserveToken; // xPERPS
	address public currencyToken; // BUSD

	address public farmingCompound;
	address public farmingVolatile;

	address public router;
	address public wrappedToken;

	address public bankroll = DEFAULT_BANKROLL;

	uint256 public price = DEFAULT_PRICE;

	uint256 public haltTime = DEFAULT_HALT_TIME;

	modifier notHasHalted()
	{
		require(block.timestamp < haltTime, "unavailable");
		_;
	}

	constructor(address _reserveToken, address _currencyToken, address _farmingCompound, address _farmingVolatile, address _router)
	{
		initialize(msg.sender, _reserveToken, _currencyToken, _farmingCompound, _farmingVolatile, _router);
	}

	function initialize(address _owner, address _reserveToken, address _currencyToken, address _farmingCompound, address _farmingVolatile, address _router) public initializer
	{
		_transferOwnership(_owner);

		bankroll = DEFAULT_BANKROLL;

		price = DEFAULT_PRICE;

		haltTime = DEFAULT_HALT_TIME;

		require(_currencyToken != _reserveToken, "invalid token");
		reserveToken = _reserveToken;
		currencyToken = _currencyToken;

		farmingCompound = _farmingCompound;
		farmingVolatile = _farmingVolatile;

		router = _router;
		wrappedToken = IUniswapV2Router(router).WETH();
	}

	// updates the bankroll address
	function setBankroll(address _bankroll) external onlyOwner
	{
		require(_bankroll != address(0), "invalid address");
		bankroll = _bankroll;
	}

	// updates the price
	function setPrice(uint256 _price) external onlyOwner
	{
		require(_price > 0, "invalid price");
		price = _price;
	}

	// updates the halt time
	function setHaltTime(uint256 _haltTime) external onlyOwner notHasHalted
	{
		require(_haltTime > block.timestamp, "invalid time");
		haltTime = _haltTime;
	}

	function recoverReserve(uint256 _amount) external onlyOwner nonReentrant
	{
		uint256 _reserve = IERC20(reserveToken).balanceOf(address(this));
		require(_amount <= _reserve, "insufficient balance");
		IERC20(reserveToken).safeTransfer(msg.sender, _amount);
	}

	function buy(uint256 _minAmountOut, bool _joinVolatile) external payable notHasHalted nonReentrant returns (uint256 _amountOut)
	{
		address[] memory _path = new address[](2);
		_path[0] = wrappedToken;
		_path[1] = currencyToken;
		uint256 _amountIn = IUniswapV2Router(router).swapExactETHForTokens{value: msg.value}(1, _path, bankroll, block.timestamp)[_path.length - 1];

		_amountOut = _amountIn * 1e18 / price;
		require(_amountOut >= _minAmountOut, "high slippage");

		uint256 _balance = IERC20(reserveToken).balanceOf(address(this));
		require(_amountOut <= _balance, "insufficient balance");

		if (_joinVolatile) {
			IERC20(reserveToken).safeApprove(farmingVolatile, _amountOut);
			FarmingVolatile(farmingVolatile).depositOnBehalfOf(_amountOut, msg.sender);
		} else {
			IERC20(reserveToken).safeApprove(farmingCompound, _amountOut);
			FarmingCompound(farmingCompound).depositOnBehalfOf(_amountOut, msg.sender);
		}

		return _amountOut;
	}

	function buy(address _token, uint256 _tokenAmount, bool _directRoute, uint256 _minAmountOut, bool _joinVolatile) external notHasHalted nonReentrant returns (uint256 _amountOut)
	{
		IERC20(_token).safeTransferFrom(msg.sender, address(this), _tokenAmount);
		uint256 _amountIn;
		if (_token == reserveToken) {
			IERC20(currencyToken).safeTransfer(bankroll, _tokenAmount);
			_amountIn = _tokenAmount;
		} else {
			IERC20(_token).safeApprove(router, _tokenAmount);
			address[] memory _path;
			if (_directRoute) {
				_path = new address[](2);
				_path[0] = _token;
				_path[1] = currencyToken;
			} else {
				_path = new address[](3);
				_path[0] = _token;
				_path[1] = wrappedToken;
				_path[2] = currencyToken;
			}
			_amountIn = IUniswapV2Router(router).swapExactTokensForTokens(_tokenAmount, 1, _path, bankroll, block.timestamp)[_path.length - 1];
		}

		_amountOut = _amountIn * 1e18 / price;
		require(_amountOut >= _minAmountOut, "high slippage");

		uint256 _balance = IERC20(reserveToken).balanceOf(address(this));
		require(_amountOut <= _balance, "insufficient balance");

		if (_joinVolatile) {
			IERC20(reserveToken).safeApprove(farmingVolatile, _amountOut);
			FarmingVolatile(farmingVolatile).depositOnBehalfOf(_amountOut, msg.sender);
		} else {
			IERC20(reserveToken).safeApprove(farmingCompound, _amountOut);
			FarmingCompound(farmingCompound).depositOnBehalfOf(_amountOut, msg.sender);
		}

		return _amountOut;
	}
}