// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.9;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Initializable } from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface IWrapperToken
{
	function token() external view returns (address _token);

	function wrap(uint256 _amount) external;
	function unwrap(uint256 _amount) external;
}

contract MultiWrappedToken is Initializable, Ownable, ReentrancyGuard, ERC20
{
	using SafeERC20 for IERC20;

	struct TokenInfo {
		address token;
		uint256 amount;
		bool wrapped;
	}

	TokenInfo[] public tokenInfo;
	mapping(address => uint256) public tokenIndex;

	uint256 public version = 0;

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
		return "xOne Token";
	}

	function symbol() public pure override returns (string memory _symbol)
	{
		return "xONE";
	}

	function initialize(address _owner) public initializer
	{
		_transferOwnership(_owner);
	}

	function upgrade() external
	{
		require(version == 0, "invalid version");
		version = 1;

		tokenInfo[0].token = 0x187caF528650fc6aB089ec9dc9DD6F08694b0eEf;
		tokenInfo[0].amount = 0;
		tokenInfo[0].wrapped = false;

		tokenInfo[1].token = 0x6d94324a4EcffaF69C8E4c3e86582B3045574E04;
		tokenInfo[0].amount = 0;
		tokenInfo[1].wrapped = false;

		tokenInfo[2].token = 0xdc612572219e50f5759A441BC9E6F14C92116757;
		tokenInfo[0].amount = 0;
		tokenInfo[2].wrapped = false;

		tokenInfo[3].token = 0x12d426BBE2FE78Fcf44F879E985d9051B200757a;
		tokenInfo[0].amount = 0;
		tokenInfo[3].wrapped = false;

		tokenInfo[4].token = 0x44a904d884368FaF4ea1e3FD086977B769048d1C;
		tokenInfo[0].amount = 0;
		tokenInfo[4].wrapped = false;

		tokenInfo[5].token = 0x381e7d98Df8ffd6A399fb2CE11Ad56eBF2a6119c;
		tokenInfo[0].amount = 0;
		tokenInfo[5].wrapped = true;

		tokenInfo[6].token = 0x7142154B14Bd56410cFFC7d42fe2b635409e57c3;
		tokenInfo[0].amount = 0;
		tokenInfo[6].wrapped = true;

		tokenInfo[7].token = 0xa9f9F29EA81AE7BDb180a15096C3307fB33EBB4C;
		tokenInfo[0].amount = 0;
		tokenInfo[7].wrapped = true;

		tokenInfo[8].token = 0x13eb43c8289CC8D7945462FF4fAfe686d4Bf53F6;
		tokenInfo[0].amount = 0;
		tokenInfo[8].wrapped = false;

		tokenInfo[9].token = 0xc822dE2843cf3a8a0642908F13d9f57E7A6D9011;
		tokenInfo[0].amount = 0;
		tokenInfo[9].wrapped = false;
	}

	function addToken(address _token, bool _wrapped) external onlyOwner
	{
		require(_token != address(0), "invalid address");
		uint256 _index = tokenIndex[_token];
		require(_index == 0, "duplicate token");

		tokenInfo.push(TokenInfo({ token: _token, amount: 0, wrapped: _wrapped }));

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
			if (_tokenInfo.wrapped) {
				address _token = IWrapperToken(_tokenInfo.token).token();
				IERC20(_token).safeTransferFrom(msg.sender, address(this), _amountIn);
				IERC20(_token).safeApprove(_tokenInfo.token, _amountIn);
				IWrapperToken(_tokenInfo.token).wrap(_amountIn);
			} else {
				IERC20(_tokenInfo.token).safeTransferFrom(msg.sender, address(this), _amountIn);
			}
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
			if (_tokenInfo.wrapped) {
				address _token = IWrapperToken(_tokenInfo.token).token();
				IWrapperToken(_tokenInfo.token).unwrap(_amountOut);
				IERC20(_token).safeTransfer(msg.sender, _amountOut);
			} else {
				IERC20(_tokenInfo.token).safeTransfer(msg.sender, _amountOut);
			}
		}

		emit Unwrap(msg.sender, _amountIn);
	}

	event Wrap(address indexed _account, uint256 _amount);
	event Unwrap(address indexed _account, uint256 _amount);
}