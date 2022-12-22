// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.9;

import { Initializable } from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract GeneralWrapperToken is Initializable, ReentrancyGuard, ERC20
{
	using SafeERC20 for IERC20;

	address public token;

	constructor(address _token)
		ERC20("", "")
	{
		initialize(_token);
	}

	function name() public pure override returns (string memory _name)
	{
		return "General Wrapper Token";
	}

	function symbol() public pure override returns (string memory _symbol)
	{
		return "GWT";
	}

	function initialize(address _token) public initializer
	{
		token = _token;
	}

	function want() external view returns (address _want)
	{
		return token;
	}

	function totalReserve() public view returns (uint256 _totalReserve)
	{
		return IERC20(token).balanceOf(address(this));
	}

	function deposit(uint256 _amount) external nonReentrant returns (uint256 _shares)
	{
		uint256 _totalSupply = totalSupply();
		uint256 _totalReserve = totalReserve();
		IERC20(token).safeTransferFrom(msg.sender, address(this), _amount);
		uint256 _newTotalReserve = totalReserve();
		_amount = _newTotalReserve - _totalReserve;
		_shares = _calcSharesFromAmount(_totalReserve, _totalSupply, _amount);
		_mint(msg.sender, _shares);
		return _shares;
	}

	function withdraw(uint256 _shares) external nonReentrant returns (uint256 _amount)
	{
		uint256 _totalSupply = totalSupply();
		uint256 _totalReserve = totalReserve();
		_amount = _calcAmountFromShares(_totalReserve, _totalSupply, _shares);
		_burn(msg.sender, _shares);
		IERC20(token).safeTransfer(msg.sender, _amount);
		return _amount;
	}

	function _calcSharesFromAmount(uint256 _totalReserve, uint256 _totalSupply, uint256 _amount) internal pure virtual returns (uint256 _shares)
	{
		if (_totalReserve == 0) return _amount;
		return _amount * _totalSupply / _totalReserve;
	}

	function _calcAmountFromShares(uint256 _totalReserve, uint256 _totalSupply, uint256 _shares) internal pure virtual returns (uint256 _amount)
	{
		if (_totalSupply == 0) return _totalReserve;
		return _shares * _totalReserve / _totalSupply;
	}
}