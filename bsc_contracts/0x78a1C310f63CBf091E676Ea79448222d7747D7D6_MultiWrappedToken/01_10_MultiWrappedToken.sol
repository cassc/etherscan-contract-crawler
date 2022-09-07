// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.9;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Initializable } from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract MultiWrappedToken is Initializable, Ownable, ReentrancyGuard, ERC20
{
	using SafeERC20 for IERC20;

	struct TokenInfo {
		address token;
		uint256 amount;
	}

	TokenInfo[] public tokenInfo;
	mapping(address => uint256) public tokenIndex;

	function tokenInfoLength() external view returns (uint256 _length)
	{
		return tokenInfo.length;
	}

	constructor()
		ERC20("", "")
	{
		initialize(msg.sender);
	}

	function name() public pure override returns (string memory _name)
	{
		return "One Token";
	}

	function symbol() public pure override returns (string memory _symbol)
	{
		return "ONE";
	}

	function initialize(address _owner) public initializer
	{
		_transferOwnership(_owner);
	}

	function addToken(address _token) external onlyOwner
	{
		require(_token != address(0), "invalid address");
		uint256 _index = tokenIndex[_token];
		require(_index == 0, "duplicate token");

		tokenInfo.push(TokenInfo({ token: _token, amount: 0 }));

		tokenIndex[_token] = tokenInfo.length;
	}

	function removeToken(address _token) external onlyOwner nonReentrant
	{
		require(_token != address(0), "invalid address");
		uint256 _index = tokenIndex[_token];
		require(_index != 0, "unknown token");

		tokenIndex[_token] = 0;

		TokenInfo storage _tokenInfo = tokenInfo[_index - 1];
		uint256 _amount = _tokenInfo.amount;

		uint256 _lastIndex = tokenInfo.length;
		if (_index < _lastIndex) {
			_tokenInfo = tokenInfo[_lastIndex - 1];
			tokenIndex[_tokenInfo.token] = _index;
		}

		tokenInfo.pop();

		if (_amount > 0) {
			IERC20(_token).safeTransfer(msg.sender, _amount);
		}
	}

	function wrap(uint256 _amountOut) external nonReentrant returns (uint256[] memory _amountsIn)
	{
		uint256 _totalSupply = totalSupply();
		if (_totalSupply == 0) _totalSupply = _amountOut;

		_mint(msg.sender, _amountOut);

		_amountsIn = new uint256[](tokenInfo.length);

		for (uint256 _i; _i < tokenInfo.length; _i++) {
			TokenInfo storage _tokenInfo = tokenInfo[_i];
			uint256 _totalReserve = _tokenInfo.amount;
			if (_totalReserve == 0) _totalReserve = _totalSupply;
			uint256 _amountIn = _amountOut * _totalReserve / _totalSupply;
			_amountsIn[_i] = _amountIn;
			_tokenInfo.amount += _amountIn;
			IERC20(_tokenInfo.token).safeTransferFrom(msg.sender, address(this), _amountIn);
		}

		emit Wrap(msg.sender, _amountOut);

		return _amountsIn;
	}

	function unwrap(uint256 _amountIn) external nonReentrant returns (uint256[] memory _amountsOut)
	{
		uint256 _totalSupply = totalSupply();

		_burn(msg.sender, _amountIn);

		for (uint256 _i; _i < tokenInfo.length; _i++) {
			TokenInfo storage _tokenInfo = tokenInfo[_i];
			uint256 _totalReserve = _tokenInfo.amount;
			uint256 _amountOut = _amountIn * _totalReserve / _totalSupply;
			_amountsOut[_i] = _amountOut;
			_tokenInfo.amount -= _amountOut;
			IERC20(_tokenInfo.token).safeTransfer(msg.sender, _amountOut);
		}

		emit Unwrap(msg.sender, _amountIn);
	}

	event Wrap(address indexed _account, uint256 _amount);
	event Unwrap(address indexed _account, uint256 _amount);
}