// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.9;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import { VaultBase } from "../../base/VaultBase.sol";
import { LibUniswapV2Pair } from "../../protocols/uniswap_v2/LibUniswapV2Pair.sol";
import { Math } from "../../utils/Math.sol";

contract ZenithTT2Vault is VaultBase
{
	using SafeERC20 for IERC20;
	using LibUniswapV2Pair for LibUniswapV2Pair.Self;

	struct Options {
		uint256 ratePerSec;
		uint256 entryDiscountRate;
		uint256 amountPerSec;
		uint256 minTradeAmount;
	}

	LibUniswapV2Pair.Self public pool;

	Options public options;

	address public quoteToken;
	address public baseToken;

	uint256 public totalAmount;
	uint256 public positionAmount;
	uint256 public positionSize;

	uint256 public lastTime;
	uint256 public lastTotalExpectedAmount;
	uint256 public lastBuyTime;
	uint256 public lastPriceCumulative;

	function _initialize(bytes memory _data) internal override
	{
		(quoteToken, options, pool) = abi.decode(_data, (address, Options, LibUniswapV2Pair.Self));
		totalAmount = 0;
		positionAmount = 0;
		positionSize = 0;
		lastTime = block.timestamp;
		lastTotalExpectedAmount = 0;
		lastBuyTime = block.timestamp;
		if (quoteToken == pool.token0) {
			baseToken = pool.token1;
			lastPriceCumulative = pool._price0CumulativeLatest();
		}
		else
		if (quoteToken == pool.token1) {
			baseToken = pool.token0;
			lastPriceCumulative = pool._price1CumulativeLatest();
		}
		else {
			revert("panic");
		}
	}

	function setOptions(Options memory _options) external onlyWhitelisted
	{
		options = _options;
	}

	function tokens() external view override returns (address[] memory _tokens)
	{
		_tokens = new address[](2);
		_tokens[0] = pool.token0;
		_tokens[1] = pool.token1;
		return _tokens;
	}

	function totalReserve(address _token) public view override returns (uint256 _totalReserve)
	{
		uint256 _availableAmount = totalAmount - positionAmount;
		if (_token == quoteToken) {
			if (_token == pool.token0) {
				_totalReserve = _availableAmount + pool._price0of1(positionSize);
			}
			else
			if (_token == pool.token1) {
				_totalReserve = _availableAmount + pool._price1of0(positionSize);
			}
			else {
				revert("panic");
			}
		}
		else
		if (_token == baseToken) {
			if (_token == pool.token0) {
				_totalReserve = pool._price0of1(_availableAmount) + positionSize;
			}
			else
			if (_token == pool.token1) {
				_totalReserve = pool._price1of0(_availableAmount) + positionSize;
			}
			else {
				revert("panic");
			}
		}
		else {
			revert("invalid token");
		}
		return _totalReserve;
	}

	function totalExpectedAmount(uint256 _when) public view returns (uint256 _totalExpectedAmount)
	{
		if (_when == 0) _when = block.timestamp;
		uint256 _timeElapsed = _when - lastTime;
		uint256 _rate = Math._exp(100e16 + options.ratePerSec, _timeElapsed);
		return lastTotalExpectedAmount * _rate / 100e16;
	}

	function tradeAmount(uint256 _when) public view returns (uint256 _tradeAmount)
	{
		if (_when == 0) _when = block.timestamp;
		uint256 _timeElapsed = _when - lastBuyTime;
		return options.amountPerSec * _timeElapsed;
	}

	function entryCurrentRate(uint256 _amount) external view returns (uint256 _entryCurrentRate)
	{
		if (_amount == 0) _amount = tradeAmount(0);
		uint256 _availableAmount = totalAmount - positionAmount;
		if (_amount > _availableAmount) {
			_amount = _availableAmount;
		}
		uint256 _size;
		uint256 _averagePriceSize;
		if (quoteToken == pool.token0) {
			_size = pool._calcSwapOut0(_amount);
			_averagePriceSize = pool._averagePrice1of0(lastPriceCumulative, lastBuyTime, _amount);
		}
		else
		if (quoteToken == pool.token1) {
			_size = pool._calcSwapOut1(_amount);
			_averagePriceSize = pool._averagePrice0of1(lastPriceCumulative, lastBuyTime, _amount);
		}
		else {
			revert("panic");
		}
		return _averagePriceSize * 100e16 / _size;
	}

	function deposit(address _token, uint256 _amount, uint256 _minShares) external override nonEmergency nonReentrant returns (uint256 _shares)
	{
		require(_token == quoteToken, "invalid token");
		uint256 _totalReserve = totalExpectedAmount(0);
		uint256 _totalSupply = totalSupply();
		_shares = _calcSharesFromAmount(_totalReserve, _totalSupply, _amount);
		require(_shares >= _minShares, "high slippage");
		totalAmount += _amount;
		lastTime = block.timestamp;
		lastTotalExpectedAmount = _totalReserve + _amount;
		_mint(msg.sender, _shares);
		IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
		return _shares;
	}

	function withdraw(address _token, uint256 _shares, uint256 _minAmount) external override nonReentrant returns (uint256 _amount)
	{
		require(_token == quoteToken, "invalid token");
		require(positionAmount == 0, "open position");
		uint256 _totalReserve = totalExpectedAmount(0);
		uint256 _totalSupply = totalSupply();
		uint256 _expectedAmount = _calcAmountFromShares(_totalReserve, _totalSupply, _shares);
		_amount = totalAmount * _expectedAmount / _totalReserve;
		require(_amount >= _minAmount, "high slippage");
		totalAmount -= _amount;
		lastTime = block.timestamp;
		lastTotalExpectedAmount = _totalReserve - _expectedAmount;
		_burn(msg.sender, _shares);
		IERC20(_token).safeTransfer(msg.sender, _amount);
		return _amount;
	}

	function withdraw(uint256 _shares, uint256 _minExpectedAmount) external nonReentrant returns (uint256 _amount, uint256 _size)
	{
		uint256 _totalReserve = totalExpectedAmount(0);
		uint256 _totalSupply = totalSupply();
		uint256 _expectedAmount = _calcAmountFromShares(_totalReserve, _totalSupply, _shares);
		require(_expectedAmount >= _minExpectedAmount, "high slippage");
		uint256 _availableAmount = totalAmount - positionAmount;
		{
			uint256 _tradeAmount;
			if (quoteToken == pool.token0) {
				_tradeAmount = pool._calcSwapOut1(positionSize);
			}
			else
			if (quoteToken == pool.token1) {
				_tradeAmount = pool._calcSwapOut0(positionSize);
			}
			else {
				revert("panic");
			}
			require(_tradeAmount < options.minTradeAmount || _availableAmount + _tradeAmount < _totalReserve, "pending sell");
		}
		_amount = _availableAmount * _expectedAmount / _totalReserve;
		_size = positionSize * _expectedAmount / _totalReserve;
		uint256 _positionAmount = positionAmount * _expectedAmount / _totalReserve;
		totalAmount -= _amount + _positionAmount;
		positionAmount -= _positionAmount;
		positionSize -= _size;
		lastTime = block.timestamp;
		lastTotalExpectedAmount = _totalReserve - _expectedAmount;
		_burn(msg.sender, _shares);
		IERC20(quoteToken).safeTransfer(msg.sender, _amount);
		IERC20(baseToken).safeTransfer(msg.sender, _size);
		return (_amount, _size);
	}

	function compound(uint256 _minShares) external override onlyWhitelisted nonReentrant returns (uint256 _shares)
	{
		uint256 _balance = IERC20(quoteToken).balanceOf(address(this));
		uint256 _availableAmount = totalAmount - positionAmount;
		uint256 _amount = _balance - _availableAmount;
		if (_amount == 0) {
			require(_minShares == 0, "high slippage");
			return 0;
		}
		uint256 _totalReserve = totalExpectedAmount(0);
		uint256 _totalSupply = totalSupply();
		_shares = _calcSharesFromAmount(_totalReserve, _totalSupply, _amount);
		require(_shares >= _minShares, "high slippage");
		totalAmount += _amount;
		lastTime = block.timestamp;
		lastTotalExpectedAmount = _totalReserve + _amount;
		if (commission > 0) {
			_mint(owner(), _shares * commission / 1e18);
		}
		return _shares;
	}

	function buy() external onlyWhitelisted nonEmergency nonReentrant returns (uint256 _amount, uint256 _size)
	{
		_amount = tradeAmount(0);
		uint256 _availableAmount = totalAmount - positionAmount;
		if (_amount > _availableAmount) {
			_amount = _availableAmount;
		}
		require(_amount >= options.minTradeAmount, "invalid amount");
		uint256 _averagePriceSize;
		if (quoteToken == pool.token0) {
			_size = pool._swap0(_amount, address(this));
			_averagePriceSize = pool._averagePrice1of0(lastPriceCumulative, lastBuyTime, _amount);
			lastPriceCumulative = pool._price0CumulativeLatest();
		}
		else
		if (quoteToken == pool.token1) {
			_size = pool._swap1(_amount, address(this));
			_averagePriceSize = pool._averagePrice0of1(lastPriceCumulative, lastBuyTime, _amount);
			lastPriceCumulative = pool._price1CumulativeLatest();
		}
		else {
			revert("panic");
		}
		require(_size * options.entryDiscountRate >= _averagePriceSize * 100e16, "insufficient price");
		positionAmount += _amount;
		positionSize += _size;
		lastBuyTime = block.timestamp;
		emit Buy(_amount, _size);
		return (_amount, _size);
	}

	function sell() external onlyWhitelisted nonEmergency nonReentrant returns (uint256 _amount, uint256 _size)
	{
		_size = positionSize;
		if (quoteToken == pool.token0) {
			_amount = pool._swap1(_size, address(this));
			lastPriceCumulative = pool._price0CumulativeLatest();
		}
		else
		if (quoteToken == pool.token1) {
			_amount = pool._swap0(_size, address(this));
			lastPriceCumulative = pool._price1CumulativeLatest();
		}
		else {
			revert("panic");
		}
		require(_amount >= options.minTradeAmount, "invalid amount");
		uint256 _availableAmount = totalAmount - positionAmount;
		require(_availableAmount + _amount >= totalExpectedAmount(0), "insufficient price");
		positionAmount = 0;
		positionSize = 0;
		lastTime = block.timestamp;
		lastTotalExpectedAmount = totalAmount;
		lastBuyTime = block.timestamp;
		emit Sell(_amount, _size);
		return (_amount, _size);
	}

	event Buy(uint256 _amount, uint256 _size);
	event Sell(uint256 _amount, uint256 _size);
}