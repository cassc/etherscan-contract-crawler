// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.9;

import { Initializable } from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";

import { IUniswapV2Router } from "./IUniswapV2Router.sol";

contract LevelXSeed is Initializable, ReentrancyGuard
{
	using Address for address payable;
	using SafeERC20 for IERC20;

	struct AccountInfo {
		bool exists; // existence flag
		uint256 amount; // amount of LVLX bought
		uint256 cost; // amount of BUSD paid
	}

	/*
	 10M LVLX @ $.004
	  9M LVLX @ $.005
	  8M LVLX @ $.006
	  7M LVLX @ $.007
	  6M LVLX @ $.008
	 */

	uint256 constant BUY_FEE = 12.5e16; // 12.5%
	uint256 constant BASE_BRACKET = 10_000_000e18; // 10M LVLX
	uint256 constant BRACKET_DECREMENT = 1_000_000e18; // 1M LVLX
	uint256 constant BASE_PRICE = 0.004e18; // 0.004 BUSD
	uint256 constant PRICE_INCREMENT = 0.001e18; // 0.001 BUSD
	uint256 constant MAX_ROUNDS = 5;

	address public router;
	address public wrappedToken;
	address public paymentToken;
	address public bankroll;
	uint256 public launchTime;
	uint256 public limitPerAccount;

	uint256 public baseBracket;
	uint256 public bracket;
	uint256 public price;
	uint256 public round;
	uint256 public totalSold;
	uint256 public totalReceived;

	address[] public accountIndex;
	mapping(address => AccountInfo) public accountInfo;

	function accountIndexLength() external view returns (uint256 _length)
	{
		return accountIndex.length;
	}

	modifier hasLaunched
	{
		require(block.timestamp >= launchTime);
		_;
	}

	constructor(address _router, address _paymentToken, address _bankroll, uint256 _launchTime, uint256 _limitPerAccount)
	{
		initialize(_router, _paymentToken, _bankroll, _launchTime, _limitPerAccount);
	}

	function initialize(address _router, address _paymentToken, address _bankroll, uint256 _launchTime, uint256 _limitPerAccount) public initializer
	{
		address _wrappedToken = IUniswapV2Router(_router).WETH();
		require(_paymentToken != _wrappedToken, "invalid token");
		router = _router;
		wrappedToken = _wrappedToken;
		paymentToken = _paymentToken;
		bankroll = _bankroll;
		launchTime = _launchTime;
		limitPerAccount = _limitPerAccount;

		baseBracket = BASE_BRACKET;
		bracket = BASE_BRACKET;
		price = BASE_PRICE;
		round = 1;
		totalSold = 0;
		totalReceived = 0;
	}

	function airdrop(address _token, address _from) external
	{
		IERC20(_token).safeTransferFrom(_from, address(this), totalSold);
		for (uint256 _i = 0; _i < accountIndex.length; _i++) {
			address _account = accountIndex[_i];
			AccountInfo storage _accountInfo = accountInfo[_account];
			IERC20(_token).safeTransfer(_account, _accountInfo.amount);
		}
	}

	function _calcCostFromAmountView(uint256 _amount) internal view returns (uint256 _cost)
	{
		uint256 _baseBracket = baseBracket;
		uint256 _bracket = bracket;
		uint256 _price = price;
		uint256 _round = round;
		uint256 _totalSold = totalSold;
		_cost = 0;
		while (_round <= MAX_ROUNDS) {
			uint256 _available = _bracket - _totalSold;
			uint256 _value = _available * _price / 1e18;
			if (_available >= _amount) {
				uint256 _c = _amount * _price / 1e18;
				_totalSold += _amount;
				return _cost + _c;
			}
			_cost += _value;
			_amount -= _available;
			_totalSold += _available;
			_baseBracket -= BRACKET_DECREMENT;
			_bracket += _baseBracket;
			_price += PRICE_INCREMENT;
			_round++;
		}
		return 0;
	}

	function _calcAmountFromCostView(uint256 _cost) internal view returns (uint256 _amount)
	{
		uint256 _baseBracket = baseBracket;
		uint256 _bracket = bracket;
		uint256 _price = price;
		uint256 _round = round;
		uint256 _totalSold = totalSold;
		_amount = 0;
		while (_round <= MAX_ROUNDS) {
			uint256 _available = _bracket - _totalSold;
			uint256 _value = _available * _price / 1e18;
			if (_value >= _cost) {
				uint256 _a = _cost * 1e18 / _price;
				if (_a > _available) _a = _available;
				_totalSold += _a;
				return _amount + _a;
			}
			_cost -= _value;
			_amount += _available;
			_totalSold += _available;
			_baseBracket -= BRACKET_DECREMENT;
			_bracket += _baseBracket;
			_price += PRICE_INCREMENT;
			_round++;
		}
		return 0;
	}

	function _calcCostFromAmount(uint256 _amount) internal returns (uint256 _cost)
	{
		_cost = 0;
		while (round <= MAX_ROUNDS) {
			uint256 _available = bracket - totalSold;
			uint256 _value = _available * price / 1e18;
			if (_available >= _amount) {
				uint256 _c = _amount * price / 1e18;
				totalSold += _amount;
				return _cost + _c;
			}
			_cost += _value;
			_amount -= _available;
			totalSold += _available;
			baseBracket -= BRACKET_DECREMENT;
			bracket += baseBracket;
			price += PRICE_INCREMENT;
			round++;
		}
		return 0;
	}

	function _calcAmountFromCost(uint256 _cost) internal returns (uint256 _amount)
	{
		_amount = 0;
		while (round <= MAX_ROUNDS) {
			uint256 _available = bracket - totalSold;
			uint256 _value = _available * price / 1e18;
			if (_value >= _cost) {
				uint256 _a = _cost * 1e18 / price;
				if (_a > _available) _a = _available;
				totalSold += _a;
				return _amount + _a;
			}
			_cost -= _value;
			_amount += _available;
			totalSold += _available;
			baseBracket -= BRACKET_DECREMENT;
			bracket += baseBracket;
			price += PRICE_INCREMENT;
			round++;
		}
		return 0;
	}

	function estimateBuyFromAmount(address _token, bool _directRoute, uint256 _amount) external view returns (uint256 _tokenAmount)
	{
		if (_amount == 0) return 0;
		uint256 _netCost = _calcCostFromAmountView(_amount);
		if (_netCost == 0) return 0;
		uint256 _cost = _netCost * 1e18 / (1e18 - BUY_FEE) + 1; // applies buy fee
		if (_token == paymentToken) {
			_tokenAmount = _cost;
		} else {
			if (_token == address(0)) {
				address[] memory _path = new address[](2);
				_path[0] = wrappedToken;
				_path[1] = paymentToken;
				_tokenAmount = IUniswapV2Router(router).getAmountsIn(_cost, _path)[0];
			} else {
				address[] memory _path;
				if (_directRoute) {
					_path = new address[](2);
					_path[0] = _token;
					_path[1] = paymentToken;
				} else {
					require(_token != wrappedToken, "not indirect");
					_path = new address[](3);
					_path[0] = _token;
					_path[1] = wrappedToken;
					_path[2] = paymentToken;
				}
				_tokenAmount = IUniswapV2Router(router).getAmountsIn(_cost, _path)[0];
			}
		}
		return _tokenAmount;
	}

	function estimateBuyFromCost(address _token, bool _directRoute, uint256 _tokenAmount) external view returns (uint256 _amount)
	{
		uint256 _cost;
		if (_token == paymentToken) {
			_cost = _tokenAmount;
		} else {
			if (_token == address(0)) {
				address[] memory _path = new address[](2);
				_path[0] = wrappedToken;
				_path[1] = paymentToken;
				_cost = IUniswapV2Router(router).getAmountsOut(_tokenAmount, _path)[_path.length - 1];
			} else {
				address[] memory _path;
				if (_directRoute) {
					_path = new address[](2);
					_path[0] = _token;
					_path[1] = paymentToken;
				} else {
					require(_token != wrappedToken, "not indirect");
					_path = new address[](3);
					_path[0] = _token;
					_path[1] = wrappedToken;
					_path[2] = paymentToken;
				}
				_cost = IUniswapV2Router(router).getAmountsOut(_tokenAmount, _path)[_path.length - 1];
			}
		}
		uint256 _netCost = _cost * (1e18 - BUY_FEE) / 1e18; // applies buy fee
		if (_netCost == 0) return 0;
		_amount = _calcAmountFromCostView(_netCost);
		if (_amount == 0) return 0;
		return _amount;
	}

	function buyFromAmount(address _token, bool _directRoute, uint256 _amount, uint256 _maxTokenAmount) external payable nonReentrant hasLaunched returns (uint256 _tokenAmount)
	{
		require(_amount > 0, "invalid amount");
		uint256 _netCost = _calcCostFromAmount(_amount);
		require(_netCost != 0, "sold out");
		uint256 _cost = _netCost * 1e18 / (1e18 - BUY_FEE) + 1; // applies buy fee
		totalReceived += _cost;
		{
			AccountInfo storage _accountInfo = accountInfo[msg.sender];
			if (!_accountInfo.exists) {
				_accountInfo.exists = true;
				accountIndex.push(msg.sender);
			}
			_accountInfo.amount += _amount;
			_accountInfo.cost += _cost;
			require(_accountInfo.amount <= limitPerAccount, "limit reached");
		}
		if (_token == paymentToken) {
			require(msg.value == 0, "invalid value");
			_tokenAmount = _cost;
			require(_tokenAmount <= _maxTokenAmount, "high slippage");
			IERC20(paymentToken).safeTransferFrom(msg.sender, bankroll, _cost);
		} else {
			if (_token == address(0)) {
				require(msg.value == _maxTokenAmount, "invalid value");
				address[] memory _path = new address[](2);
				_path[0] = wrappedToken;
				_path[1] = paymentToken;
				_tokenAmount = IUniswapV2Router(router).swapETHForExactTokens{value: _maxTokenAmount}(_cost, _path, bankroll, block.timestamp)[0];
				uint256 _excessTokenAmount = _maxTokenAmount - _tokenAmount;
				if (_excessTokenAmount > 0) {
					payable(msg.sender).sendValue(_excessTokenAmount);
				}
			} else {
				require(msg.value == 0, "invalid value");
				IERC20(_token).safeTransferFrom(msg.sender, address(this), _maxTokenAmount);
				IERC20(_token).safeApprove(router, _maxTokenAmount);
				address[] memory _path;
				if (_directRoute) {
					_path = new address[](2);
					_path[0] = _token;
					_path[1] = paymentToken;
				} else {
					require(_token != wrappedToken, "not indirect");
					_path = new address[](3);
					_path[0] = _token;
					_path[1] = wrappedToken;
					_path[2] = paymentToken;
				}
				_tokenAmount = IUniswapV2Router(router).swapTokensForExactTokens(_cost, _maxTokenAmount, _path, bankroll, block.timestamp)[0];
				IERC20(_token).safeApprove(router, 0);
				uint256 _excessTokenAmount = _maxTokenAmount - _tokenAmount;
				if (_excessTokenAmount > 0) {
					IERC20(_token).safeTransfer(msg.sender, _excessTokenAmount);
				}
			}
		}
		emit Buy(msg.sender, _token, _tokenAmount, _amount, _cost);
		return _tokenAmount;
	}

	function buyFromCost(address _token, bool _directRoute, uint256 _tokenAmount, uint256 _minAmount) external payable nonReentrant hasLaunched returns (uint256 _amount)
	{
		uint256 _cost;
		if (_token == paymentToken) {
			require(msg.value == 0, "invalid value");
			_cost = _tokenAmount;
			IERC20(paymentToken).safeTransferFrom(msg.sender, bankroll, _cost);
		} else {
			if (_token == address(0)) {
				require(msg.value == _tokenAmount, "invalid value");
				address[] memory _path = new address[](2);
				_path[0] = wrappedToken;
				_path[1] = paymentToken;
				_cost = IUniswapV2Router(router).swapExactETHForTokens{value: _tokenAmount}(0, _path, bankroll, block.timestamp)[_path.length - 1];
			} else {
				require(msg.value == 0, "invalid value");
				IERC20(_token).safeTransferFrom(msg.sender, address(this), _tokenAmount);
				IERC20(_token).safeApprove(router, _tokenAmount);
				address[] memory _path;
				if (_directRoute) {
					_path = new address[](2);
					_path[0] = _token;
					_path[1] = paymentToken;
				} else {
					require(_token != wrappedToken, "not indirect");
					_path = new address[](3);
					_path[0] = _token;
					_path[1] = wrappedToken;
					_path[2] = paymentToken;
				}
				_cost = IUniswapV2Router(router).swapExactTokensForTokens(_tokenAmount, 0, _path, bankroll, block.timestamp)[_path.length - 1];
			}
		}
		uint256 _netCost = _cost * (1e18 - BUY_FEE) / 1e18; // applies buy fee
		require(_netCost > 0, "invalid amount");
		_amount = _calcAmountFromCost(_netCost);
		require(_amount != 0, "sold out");
		require(_amount >= _minAmount, "high slippage");
		totalReceived += _cost;
		{
			AccountInfo storage _accountInfo = accountInfo[msg.sender];
			if (!_accountInfo.exists) {
				_accountInfo.exists = true;
				accountIndex.push(msg.sender);
			}
			_accountInfo.amount += _amount;
			_accountInfo.cost += _cost;
			require(_accountInfo.amount <= limitPerAccount, "limit reached");
		}
		emit Buy(msg.sender, _token, _tokenAmount, _amount, _cost);
		return _amount;
	}

	receive() external payable {}

	event Buy(address indexed _account, address indexed _token, uint256 _tokenAmount, uint256 _amount, uint256 _cost);
}