// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.9;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Initializable } from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";

contract MultiWrappedToken is Initializable, Ownable, ReentrancyGuard, ERC20
{
	using Address for address payable;
	using SafeERC20 for IERC20;

	struct TokenInfo {
		address token;
		uint256 rate;
		uint256 amount;
	}

	string private name_;
	string private symbol_;

	TokenInfo[] public tokenInfo;
	mapping(address => uint256) public tokenIndex;

	function tokenInfoLength() external view returns (uint256 _length)
	{
		return tokenInfo.length;
	}

	constructor()
		ERC20("", "")
	{
		initialize(msg.sender, "", "");
	}

	function name() public view override returns (string memory _name)
	{
		return name_;
	}

	function symbol() public view override returns (string memory _symbol)
	{
		return symbol_;
	}

	function initialize(address _owner, string memory _name, string memory _symbol) public initializer
	{
		_transferOwnership(_owner);

		name_ = _name;
		symbol_ = _symbol;
	}

	function reindexTokens() external onlyOwner
	{
		tokenIndex[0x2170Ed0880ac9A755fd29B2688956BD959F933F8] = 0;
		tokenIndex[0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c] = 0;
		tokenIndex[0x0000000000000000000000000000000000000000] = 0;
		tokenIndex[0x5f0Da599BB2ccCfcf6Fdfd7D81743B6020864350] = 0;
		tokenIndex[0xCC42724C6683B7E57334c4E856f4c9965ED682bD] = 0;
		tokenIndex[0x570A5D26f7765Ecb712C0924E4De545B89fD43dF] = 0;
		tokenIndex[0xF8A0BF9cF54Bb92F17374d9e9A321E6a111a51bD] = 0;
		tokenIndex[0xb86AbCb37C3A4B64f74f59301AFF131a1BEcC787] = 0;
		tokenIndex[0xBf5140A22578168FD562DCcF235E5D43A02ce9B1] = 0;
		tokenIndex[0x7083609fCE4d1d8Dc0C979AAb8c869Ea2C873402] = 0;

		for (uint256 _i = 0; _i < tokenInfo.length; _i++) {
			TokenInfo storage _tokenInfo = tokenInfo[_i];
			tokenIndex[_tokenInfo.token] = _i + 1;
		}
	}

	function addToken(address _token, uint256 _rate) external onlyOwner
	{
		uint256 _index = tokenIndex[_token];
		require(_index == 0, "duplicate token");

		tokenInfo.push(TokenInfo({ token: _token, rate: _rate, amount: 0 }));

		tokenIndex[_token] = tokenInfo.length;
	}

	function removeToken(address _token) external onlyOwner nonReentrant
	{
		uint256 _index = tokenIndex[_token];
		require(_index != 0, "unknown token");

		tokenIndex[_token] = 0;

		TokenInfo storage _tokenInfo = tokenInfo[_index - 1];
		uint256 _amount = _tokenInfo.amount;

		uint256 _lastIndex = tokenInfo.length;
		if (_index < _lastIndex) {
			TokenInfo storage _lastTokenInfo = tokenInfo[_lastIndex - 1];
			_tokenInfo.token = _lastTokenInfo.token;
			_tokenInfo.rate = _lastTokenInfo.rate;
			_tokenInfo.amount = _lastTokenInfo.amount;
			tokenIndex[_tokenInfo.token] = _index;
		}

		tokenInfo.pop();

		if (_amount > 0) {
			IERC20(_token).safeTransfer(msg.sender, _amount);
		}
	}

	function wrap(uint256 _amountOut) external payable nonReentrant returns (uint256[] memory _amountsIn)
	{
		_amountsIn = new uint256[](tokenInfo.length);

		_mint(msg.sender, _amountOut);

		for (uint256 _i = 0; _i < tokenInfo.length; _i++) {
			TokenInfo storage _tokenInfo = tokenInfo[_i];
			uint256 _amountIn = _amountOut * _tokenInfo.rate / 1e18;
			_amountsIn[_i] = _amountIn;
			_tokenInfo.amount += _amountIn;
			if (_tokenInfo.token == address(0)) {
				require(msg.value >= _amountIn, "insufficient value");
				if (msg.value > _amountIn) {
					payable(msg.sender).sendValue(msg.value - _amountIn);
				}
			} else {
				IERC20(_tokenInfo.token).safeTransferFrom(msg.sender, address(this), _amountIn);
			}
		}

		emit Wrap(msg.sender, _amountOut);

		return _amountsIn;
	}

	function unwrap(uint256 _amountIn) external nonReentrant returns (uint256[] memory _amountsOut)
	{
		_amountsOut = new uint256[](tokenInfo.length);

		uint256 _totalSupply = totalSupply();

		_burn(msg.sender, _amountIn);

		for (uint256 _i = 0; _i < tokenInfo.length; _i++) {
			TokenInfo storage _tokenInfo = tokenInfo[_i];
			uint256 _totalReserve = _tokenInfo.amount;
			uint256 _amountOut = _amountIn * _totalReserve / _totalSupply;
			_amountsOut[_i] = _amountOut;
			_tokenInfo.amount -= _amountOut;
			if (_tokenInfo.token == address(0)) {
				payable(msg.sender).sendValue(_amountOut);
			} else {
				IERC20(_tokenInfo.token).safeTransfer(msg.sender, _amountOut);
			}
		}

		emit Unwrap(msg.sender, _amountIn);

		return _amountsOut;
	}

	event Wrap(address indexed _account, uint256 _amount);
	event Unwrap(address indexed _account, uint256 _amount);
}