// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.9;

import { Address } from "@openzeppelin/contracts/utils/Address.sol";

import { LockCycle } from "./LockCycle.sol";
import { BaseStakingPool } from "./BaseStakingPool.sol";

contract NativeStakingPool is LockCycle, BaseStakingPool
{
	using Address for address payable;

	struct UserInfo2 {
		uint256 amount;
	}

	uint256 public stakedBalance;
	uint256 public poolMinPerUser;
	uint256 public poolMaxPerUser;

	mapping(address => UserInfo2) public userInfo2;

	constructor(address _owner)
	{
		initialize(_owner, address(0));
	}

	function initialize(address _owner, address _stakedToken) public override initializer
	{
		require(_stakedToken == address(0), "invalid token");
		_initialize(_owner);
		poolMaxPerUser = type(uint256).max;
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

	function deposit(uint256 _amount, bool _claimRewards) external payable nonReentrant collectFee(_amount)
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
			stakedBalance += _amount;
		}
		emit Deposit(msg.sender, _amount);
		{
			uint256 _factor = _pushLock(msg.sender);
			uint256 _shares = _amount;
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
			payable(msg.sender).sendValue(_amount);
			stakedBalance -= _amount;
		}
		emit Withdraw(msg.sender, _amount);
		{
			uint256 _shares = _amount;
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
			payable(msg.sender).sendValue(_amount);
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
			payable(msg.sender).sendValue(_amount);
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

	event Lock(address indexed _account, uint256 _cycle, uint256 _factor);
	event Deposit(address indexed _account, uint256 _amount);
	event Withdraw(address indexed _account, uint256 _amount);
	event EmergencyWithdraw(address indexed _account, uint256 _amount);
	event Exit(address indexed _account, uint256 _amount);
	event UpdatePoolLimitsPerUser(uint256 _poolMinPerUser, uint256 _poolMaxPerUser);
}