// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Initializable } from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import { HmineMain2 } from "./HmineMain2.sol";

contract HmineMain1 is Initializable, Ownable, ReentrancyGuard
{
	using SafeERC20 for IERC20;

	address constant DEFAULT_BANKROLL = 0x25be1fcF5F51c418a0C30357a4e8371dB9cf9369; // multisig
	address constant DEFAULT_MANAGEMENT_0 = 0x36b13280500AEBC5A75EbC1e9cB9Bf1b6A78a95e; // miko
	address constant DEFAULT_MANAGEMENT_1 = 0x2165fa4a32B9c228cD55713f77d2e977297D03e8; // ghost
	address constant DEFAULT_MANAGEMENT_2 = 0xcD8dDeE99C0c4Be4cD699661AE9c00C69D1Eb4A8;
	address constant DEFAULT_LIQUIDITY_TAKER = 0x2165fa4a32B9c228cD55713f77d2e977297D03e8; // ghost

	uint256 constant MAX_SUPPLY = 200_000e18;
	uint256 constant ROUND_INCREMENT = 250e18;
	uint256 constant FIRST_ROUND = 100_000e18;
	uint256 constant SECOND_ROUND = FIRST_ROUND + ROUND_INCREMENT;
	uint256 constant MIN_PRICE = 7e18;
	uint256 constant PRICE_INCREMENT = 0.75e18;

	address public hmineToken; // xHMINE
	address public currencyToken; // BUSD
	address public hmineMain2;

	address public bankroll = DEFAULT_BANKROLL;
	address[3] public management = [DEFAULT_MANAGEMENT_0, DEFAULT_MANAGEMENT_1, DEFAULT_MANAGEMENT_2];
	address public liquidityTaker = DEFAULT_LIQUIDITY_TAKER;

	uint256 public totalSold = 0;
	uint256 public currentPrice = 0;

	modifier onlyLiquidityTaker()
	{
		require(msg.sender == liquidityTaker, "access denied");
		_;
	}

	constructor(address _hmineToken, address _currenctyToken, address _hmineMain2, uint256 _totalSold)
	{
		initialize(msg.sender, _hmineToken, _currenctyToken, _hmineMain2, _totalSold);
	}

	function initialize(address _owner, address _hmineToken, address _currenctyToken, address _hmineMain2, uint256 _totalSold) public initializer
	{
		_transferOwnership(_owner);

		bankroll = DEFAULT_BANKROLL;
		management = [DEFAULT_MANAGEMENT_0, DEFAULT_MANAGEMENT_1, DEFAULT_MANAGEMENT_2];
		liquidityTaker = DEFAULT_LIQUIDITY_TAKER;

		totalSold = 0;
		currentPrice = 0;

		require(_currenctyToken != _hmineToken, "invalid token");
		require(_totalSold <= MAX_SUPPLY, "invalid amount");
		hmineToken = _hmineToken;
		currencyToken = _currenctyToken;
		hmineMain2 = _hmineMain2;

		totalSold = _totalSold;
		currentPrice = MIN_PRICE;
		if (totalSold > FIRST_ROUND) {
			currentPrice += PRICE_INCREMENT * ((totalSold - FIRST_ROUND) / ROUND_INCREMENT);
		}
		IERC20(hmineToken).safeTransferFrom(msg.sender, address(this), MAX_SUPPLY - totalSold);
	}

	function setBankroll(address _bankroll) external onlyOwner
	{
		require(_bankroll != address(0), "invalid address");
		bankroll = _bankroll;
	}

	function setManagement(uint256 _i, address _management) external onlyOwner
	{
		require(_i < management.length, "invalid index");
		require(_management != address(0), "invalid address");
		management[_i] = _management;
	}

	function setLiquidityTaker(address _liquidityTaker) external onlyOwner
	{
		liquidityTaker = _liquidityTaker;
	}

	function recoverReserve(uint256 _amount) external onlyLiquidityTaker nonReentrant
	{
		uint256 _reserve = IERC20(currencyToken).balanceOf(address(this));
		require(_amount <= _reserve, "insufficient balance");
		IERC20(currencyToken).safeTransfer(msg.sender, _amount);
	}

	function calculateSwap(uint256 _amount, bool _isBuy) external view returns (uint256 _value)
	{
		(_value, ) = _isBuy ? _getBuyValue(_amount) : _getSellValue(_amount);
		return _value;
	}

	function buy(uint256 _amount) external nonReentrant returns (uint256 _value)
	{
		require(_amount > 0, "invalid amount");

		(uint256 _hmineValue, uint256 _price) = _getBuyValue(_amount);

		_buy(msg.sender, _amount, _hmineValue, _price, msg.sender);

		emit Buy(msg.sender, _hmineValue, _price, HmineMain2(hmineMain2).totalStaked());

		return _hmineValue;
	}

	function buyOnBehalfOf(uint256 _amount, address _account) external nonReentrant returns (uint256 _value)
	{
		require(_amount > 0, "invalid amount");

		(uint256 _hmineValue, uint256 _price) = _getBuyValue(_amount);

		_buy(msg.sender, _amount, _hmineValue, _price, _account);

		emit Buy(_account, _hmineValue, _price, HmineMain2(hmineMain2).totalStaked());

		return _hmineValue;
	}

	function compound() external nonReentrant
	{
		uint256 _amount = HmineMain2(hmineMain2).claimOnBehalfOf(msg.sender);

		(uint256 _hmineValue, uint256 _price) = _getBuyValue(_amount);

		_buy(address(this), _amount, _hmineValue, _price, msg.sender);

		emit Compound(msg.sender, _hmineValue, _price, HmineMain2(hmineMain2).totalStaked());
	}

	function _buy(address _sender, uint256 _amount, uint256 _hmineValue, uint256 _price, address _account) internal
	{
		require(totalSold + _hmineValue <= MAX_SUPPLY, "exceeds supply");

		uint256 _managementAmount = (_amount * 10e16 / 100e16) / management.length;
		uint256 _bankrollAmount = _amount * 80e16 / 100e16;
		uint256 _amountToStakers = _amount - (management.length * _managementAmount + _bankrollAmount);

		if (_sender == address(this)) {
			for (uint256 _i = 0; _i < management.length; _i++) {
				IERC20(currencyToken).safeTransfer(management[_i], _managementAmount);
			}
			IERC20(currencyToken).safeTransfer(bankroll, _bankrollAmount);
		} else {
			for (uint256 _i = 0; _i < management.length; _i++) {
				IERC20(currencyToken).safeTransferFrom(_sender, management[_i], _managementAmount);
			}
			IERC20(currencyToken).safeTransferFrom(_sender, bankroll, _bankrollAmount);
			IERC20(currencyToken).safeTransferFrom(_sender, address(this), _amountToStakers);
		}

		IERC20(currencyToken).safeApprove(hmineMain2, _amountToStakers);
		HmineMain2(hmineMain2).rewardAll(_amountToStakers);

		IERC20(hmineToken).safeApprove(hmineMain2, _hmineValue);
		HmineMain2(hmineMain2).depositOnBehalfOf(_hmineValue, _account);

		totalSold += _hmineValue;

		currentPrice = _price;
	}

	function sell(uint256 _amount) external nonReentrant returns (uint256 _value)
	{
		require(_amount > 0, "invalid amount");

		(uint256 _sellValue, uint256 _price) = _getSellValue(_amount);

		uint256 _5percent = (_sellValue * 5e16) / 100e16;

		uint256 _reserve = IERC20(currencyToken).balanceOf(address(this));
		require(_5percent <= _reserve, "insufficient balance");

		IERC20(hmineToken).safeTransferFrom(msg.sender, address(this), _amount);

		IERC20(currencyToken).safeTransfer(msg.sender, _5percent);

		HmineMain2(hmineMain2).updateAccount(msg.sender);

		totalSold -= _amount;

		currentPrice = _price;

		emit Sell(msg.sender, _amount, _price, HmineMain2(hmineMain2).totalStaked());

		return _sellValue;
	}

	function _getBuyValue(uint256 _amount) internal view returns (uint256 _hmineValue, uint256 _price)
	{
		_price = currentPrice;
		_hmineValue = _amount * 1e18 / _price;
		if (totalSold + _hmineValue <= SECOND_ROUND) {
			if (totalSold + _hmineValue == SECOND_ROUND) {
				_price += PRICE_INCREMENT;
			}
		}
		else {
			_hmineValue = 0;
			uint256 _amountLeftOver = _amount;
			uint256 _roundAvailable = ROUND_INCREMENT - totalSold % ROUND_INCREMENT;

			// If short of first round, adjust up to first round
			if (totalSold < FIRST_ROUND) {
				_hmineValue += FIRST_ROUND - totalSold;
				_amountLeftOver -= _hmineValue * _price / 1e18;
				_roundAvailable = ROUND_INCREMENT;
			}

			uint256 _valueOfLeftOver = _amountLeftOver * 1e18 / _price;
			if (_valueOfLeftOver < _roundAvailable) {
				_hmineValue += _valueOfLeftOver;
			} else {
				_hmineValue += _roundAvailable;
				_amountLeftOver = (_valueOfLeftOver - _roundAvailable) * _price / 1e18;
				_price += PRICE_INCREMENT;
				while (_amountLeftOver > 0) {
					_valueOfLeftOver = _amountLeftOver * 1e18 / _price;
					if (_valueOfLeftOver >= ROUND_INCREMENT) {
						_hmineValue += ROUND_INCREMENT;
						_amountLeftOver = (_valueOfLeftOver - ROUND_INCREMENT) * _price / 1e18;
						_price += PRICE_INCREMENT;
					} else {
						_hmineValue += _valueOfLeftOver;
						_amountLeftOver = 0;
					}
				}
			}
		}
		return (_hmineValue, _price);
	}

	function _getSellValue(uint256 _amount) internal view returns (uint256 _sellValue, uint256 _price)
	{
		_price = currentPrice;
		uint256 _roundAvailable = totalSold % ROUND_INCREMENT;
		if (_amount <= _roundAvailable) {
			_sellValue = _amount * _price / 1e18;
		}
		else {
			_sellValue = _roundAvailable * _price / 1e18;
			uint256 _amountLeftOver = _amount - _roundAvailable;
			while (_amountLeftOver > 0) {
				if (_price > MIN_PRICE) {
					_price -= PRICE_INCREMENT;
				}
				if (_amountLeftOver > ROUND_INCREMENT) {
					_sellValue += ROUND_INCREMENT * _price / 1e18;
					_amountLeftOver -= ROUND_INCREMENT;
				} else {
					_sellValue += _amountLeftOver * _price / 1e18;
					_amountLeftOver = 0;
				}
			}
		}
		return (_sellValue, _price);
	}

	event Buy(address indexed _account, uint256 _amount, uint256 _price, uint256 _totalStaked);
	event Sell(address indexed _account, uint256 _amount, uint256 _price, uint256 _totalStaked);
	event Compound(address indexed _account, uint256 _amount, uint256 _price, uint256 _totalStaked);
}