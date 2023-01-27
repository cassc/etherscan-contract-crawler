// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.9;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import { LockCycle } from "./LockCycle.sol";
import { BaseStakingPool } from "./BaseStakingPool.sol";

contract ERC20StakingPool is LockCycle, BaseStakingPool
{
	using SafeERC20 for IERC20;

	struct UserInfo2 {
		uint256 amount;
	}

	address public stakedToken;
	uint256 public stakedBalance;
	uint256 public poolMinPerUser;
	uint256 public poolMaxPerUser;
	uint256 public scale;

	mapping(address => UserInfo2) public userInfo2;

	constructor(address _owner, address _stakedToken)
	{
		initialize(_owner, _stakedToken);
	}

	function initialize(address _owner, address _stakedToken) public override initializer
	{
		uint256 _decimals = _stakedToken == address(0) ? 18 : IERC20Metadata(_stakedToken).decimals();
		require(_decimals <= 18, "invalid token");
		_initialize(_owner);
		stakedToken = _stakedToken;
		poolMaxPerUser = type(uint256).max;
		scale = 10 ** (18 - _decimals);
	}

	function lock(uint256 _cycle) external nonReentrant
	{
		(uint256 _oldFactor, uint256 _newFactor) = _adjustLock(msg.sender, _cycle);
		UserInfo1 storage _userInfo1 = userInfo1[msg.sender];
		uint256 _shares = _userInfo1.shares;
		emit Lock(msg.sender, _cycle, _newFactor);
		if (_shares > 0 && _oldFactor != _newFactor) {
			_adjust(msg.sender, _shares + _shares * _oldFactor / 1e18, _shares + _shares * _newFactor / 1e18);
		}
	}

	function deposit(uint256 _amount, bool _claimRewards) external payable nonReentrant collectFee(0)
	{
		if (_claimRewards) {
			_harvestAll(msg.sender);
		}
		UserInfo2 storage _userInfo2 = userInfo2[msg.sender];
		uint256 _oldAmount = _userInfo2.amount;
		uint256 _newAmount = _oldAmount + _amount;
		if (_newAmount > 0) {
			require(poolMinPerUser <= _newAmount && _newAmount <= poolMaxPerUser, "invalid balance");
		}
		if (_amount > 0) {
			_userInfo2.amount = _newAmount;
			IERC20(stakedToken).safeTransferFrom(msg.sender, address(this), _amount);
			stakedBalance += _amount;
		}
		emit Deposit(msg.sender, _amount);
		{
			uint256 _factor = _pushLock(msg.sender);
			uint256 _shares = _amount * scale;
			_deposit(msg.sender, _shares + _shares * _factor / 1e18);
		}
	}

	function withdraw(uint256 _amount, bool _claimRewards) external payable nonReentrant collectFee(0)
	{
		if (_claimRewards) {
			_harvestAll(msg.sender);
		}
		uint256 _factor = _checkLock(msg.sender);
		UserInfo2 storage _userInfo2 = userInfo2[msg.sender];
		uint256 _oldAmount = _userInfo2.amount;
		require(_amount <= _oldAmount, "insufficient balance");
		uint256 _newAmount = _oldAmount - _amount;
		if (_newAmount > 0) {
			require(poolMinPerUser <= _newAmount && _newAmount <= poolMaxPerUser, "invalid balance");
		}
		if (_amount > 0) {
			_userInfo2.amount = _newAmount;
			IERC20(stakedToken).safeTransfer(msg.sender, _amount);
			stakedBalance -= _amount;
		}
		emit Withdraw(msg.sender, _amount);
		{
			uint256 _shares = _amount * scale;
			_withdraw(msg.sender, _shares + _shares * _factor / 1e18);
		}
	}

	function emergencyWithdraw() external payable nonReentrant collectFee(0)
	{
		_checkLock(msg.sender);
		UserInfo2 storage _userInfo2 = userInfo2[msg.sender];
		uint256 _amount = _userInfo2.amount;
		if (_amount > 0) {
			_userInfo2.amount = 0;
			IERC20(stakedToken).safeTransfer(msg.sender, _amount);
			stakedBalance -= _amount;
		}
		emit EmergencyWithdraw(msg.sender, _amount);
		_emergencyWithdraw(msg.sender);
	}

	function exit() external payable nonReentrant collectFee(0)
	{
		_checkLock(msg.sender);
		UserInfo2 storage _userInfo2 = userInfo2[msg.sender];
		uint256 _amount = _userInfo2.amount;
		if (_amount > 0) {
			_userInfo2.amount = 0;
			IERC20(stakedToken).safeTransfer(msg.sender, _amount);
			stakedBalance -= _amount;
		}
		emit Exit(msg.sender, _amount);
		_exit(msg.sender);
	}

	function updatePoolLimitsPerUser(uint256 _poolMinPerUser, uint256 _poolMaxPerUser) external onlyOwner
	{
		require(_poolMinPerUser <= _poolMaxPerUser, "invalid limits");
		if (stakedBalance > 0) {
			require(_poolMinPerUser <= poolMinPerUser && poolMaxPerUser <= _poolMaxPerUser, "unexpanded limits");
		}
		poolMinPerUser = _poolMinPerUser;
		poolMaxPerUser = _poolMaxPerUser;
		emit UpdatePoolLimitsPerUser(_poolMinPerUser, _poolMaxPerUser);
	}

	function freeBalance(address _token) public view override returns(uint256 _balance)
	{
		_balance = super.freeBalance(_token);
		if (_token == stakedToken) _balance -= stakedBalance;
		return _balance;
	}

	event Lock(address indexed _account, uint256 _cycle, uint256 _factor);
	event Deposit(address indexed _account, uint256 _amount);
	event Withdraw(address indexed _account, uint256 _amount);
	event EmergencyWithdraw(address indexed _account, uint256 _amount);
	event Exit(address indexed _account, uint256 _amount);
	event UpdatePoolLimitsPerUser(uint256 _poolMinPerUser, uint256 _poolMaxPerUser);
}