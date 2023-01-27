// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.9;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC1155 } from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import { ERC1155Holder } from "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

import { LockCycle } from "./LockCycle.sol";
import { BaseStakingPool } from "./BaseStakingPool.sol";

contract ERC1155StakingPool is LockCycle, BaseStakingPool, ERC1155Holder
{
	using SafeERC20 for IERC20;

	struct UserTokenInfo {
		uint256 amount;
	}

	struct UserInfo2 {
		uint256 userTokenCount;
		mapping(uint256 => UserTokenInfo) userTokenInfo;
	}

	struct TokenInfo {
		uint256 amount;
		int256 weight;
	}

	address public collection;
	uint256 public tokenCount;
	mapping(uint256 => TokenInfo) public tokenInfo;
	uint256 public poolMinPerUser;
	uint256 public poolMaxPerUser;

	mapping(address => UserInfo2) public userInfo2;

	constructor(address _owner, address _collection)
	{
		initialize(_owner, _collection);
	}

	function initialize(address _owner, address _collection) public override initializer
	{
		_initialize(_owner);
		collection = _collection;
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

	function deposit(uint256[] calldata _ids, uint256[] calldata _amounts, bool _claimRewards) external payable nonReentrant collectFee(0)
	{
		if (_claimRewards) {
			_harvestAll(msg.sender);
		}
		uint256 _count = _ids.length;
		require(_amounts.length == _count, "invalid length");
		UserInfo2 storage _userInfo2 = userInfo2[msg.sender];
		uint256 _userTokenCount = 0;
		for (uint256 _i = 0; _i < _count; _i++) {
			uint256 _id = _ids[_i];
			uint256 _amount = _amounts[_i];
			_userInfo2.userTokenInfo[_id].amount += _amount;
			tokenInfo[_id].amount += _amount;
			_userTokenCount += _amount;
		}
		uint256 _oldAmount = _userInfo2.userTokenCount;
		uint256 _newAmount = _oldAmount + _userTokenCount;
		if (_newAmount > 0) {
			require(poolMinPerUser <= _newAmount && _newAmount <= poolMaxPerUser, "invalid balance");
		}
		if (_userTokenCount > 0) {
			_userInfo2.userTokenCount = _newAmount;
			IERC1155(collection).safeBatchTransferFrom(msg.sender, address(this), _ids, _amounts, new bytes(0));
			tokenCount += _userTokenCount;
		}
		emit Deposit(msg.sender, _ids, _amounts);
		{
			uint256 _factor = _pushLock(msg.sender);
			uint256 _shares = 0;
			for (uint256 _i = 0; _i < _count; _i++) {
				_shares += _amounts[_i] * uint256(1e18 + tokenInfo[_ids[_i]].weight);
			}
			_deposit(msg.sender, _shares + _shares * _factor / 1e18);
		}
	}

	function withdraw(uint256[] calldata _ids, uint256[] calldata _amounts, bool _claimRewards) external payable nonReentrant collectFee(0)
	{
		if (_claimRewards) {
			_harvestAll(msg.sender);
		}
		uint256 _factor = _checkLock(msg.sender);
		uint256 _count = _ids.length;
		require(_amounts.length == _count, "invalid length");
		UserInfo2 storage _userInfo2 = userInfo2[msg.sender];
		uint256 _userTokenCount = 0;
		for (uint256 _i = 0; _i < _count; _i++) {
			uint256 _id = _ids[_i];
			uint256 _amount = _amounts[_i];
			UserTokenInfo storage _userTokenInfo = _userInfo2.userTokenInfo[_id];
			require(_amount <= _userTokenInfo.amount, "insufficient balance");
			_userTokenInfo.amount -= _amount;
			tokenInfo[_id].amount -= _amount;
			_userTokenCount += _amount;
		}
		uint256 _oldAmount = _userInfo2.userTokenCount;
		uint256 _newAmount = _oldAmount - _userTokenCount;
		if (_newAmount > 0) {
			require(poolMinPerUser <= _newAmount && _newAmount <= poolMaxPerUser, "invalid balance");
		}
		if (_userTokenCount > 0) {
			_userInfo2.userTokenCount = _newAmount;
			IERC1155(collection).safeBatchTransferFrom(address(this), msg.sender, _ids, _amounts, new bytes(0));
			tokenCount -= _userTokenCount;
		}
		emit Withdraw(msg.sender, _ids, _amounts);
		{
			uint256 _shares = 0;
			for (uint256 _i = 0; _i < _count; _i++) {
				_shares += _amounts[_i] * uint256(1e18 + tokenInfo[_ids[_i]].weight);
			}
			_withdraw(msg.sender, _shares + _shares * _factor / 1e18);
		}
	}

	function emergencyWithdraw(uint256[] calldata _ids) external payable nonReentrant collectFee(0)
	{
		_checkLock(msg.sender);
		uint256 _count = _ids.length;
		UserInfo2 storage _userInfo2 = userInfo2[msg.sender];
		uint256 _userTokenCount = 0;
		uint256[] memory _amounts = new uint256[](_count);
		for (uint256 _i = 0; _i < _count; _i++) {
			uint256 _id = _ids[_i];
			UserTokenInfo storage _userTokenInfo = _userInfo2.userTokenInfo[_id];
			uint256 _amount = _userTokenInfo.amount;
			_userTokenInfo.amount = 0;
			tokenInfo[_id].amount -= _amount;
			_userTokenCount += _amount;
			_amounts[_i] = _amount;
		}
		uint256 _oldAmount = _userInfo2.userTokenCount;
		require(_userTokenCount == _oldAmount, "incomplete list");
		if (_userTokenCount > 0) {
			_userInfo2.userTokenCount = 0;
			IERC1155(collection).safeBatchTransferFrom(address(this), msg.sender, _ids, _amounts, new bytes(0));
			tokenCount -= _userTokenCount;
		}
		emit EmergencyWithdraw(msg.sender, _ids, _amounts);
		_emergencyWithdraw(msg.sender);
	}

	function exit(uint256[] calldata _ids) external payable nonReentrant collectFee(0)
	{
		_checkLock(msg.sender);
		uint256 _count = _ids.length;
		UserInfo2 storage _userInfo2 = userInfo2[msg.sender];
		uint256 _userTokenCount = 0;
		uint256[] memory _amounts = new uint256[](_count);
		for (uint256 _i = 0; _i < _count; _i++) {
			uint256 _id = _ids[_i];
			UserTokenInfo storage _userTokenInfo = _userInfo2.userTokenInfo[_id];
			uint256 _amount = _userTokenInfo.amount;
			_userTokenInfo.amount = 0;
			tokenInfo[_id].amount -= _amount;
			_userTokenCount += _amount;
			_amounts[_i] = _amount;
		}
		uint256 _oldAmount = _userInfo2.userTokenCount;
		require(_userTokenCount == _oldAmount, "incomplete list");
		if (_userTokenCount > 0) {
			_userInfo2.userTokenCount = 0;
			IERC1155(collection).safeBatchTransferFrom(address(this), msg.sender, _ids, _amounts, new bytes(0));
			tokenCount -= _userTokenCount;
		}
		emit Exit(msg.sender, _ids, _amounts);
		_exit(msg.sender);
	}

	function updatePoolLimitsPerUser(uint256 _poolMinPerUser, uint256 _poolMaxPerUser) external onlyOwner
	{
		require(_poolMinPerUser <= _poolMaxPerUser, "invalid limits");
		if (tokenCount > 0) {
			require(_poolMinPerUser <= poolMinPerUser && poolMaxPerUser <= _poolMaxPerUser, "unexpanded limits");
		}
		poolMinPerUser = _poolMinPerUser;
		poolMaxPerUser = _poolMaxPerUser;
		emit UpdatePoolLimitsPerUser(_poolMinPerUser, _poolMaxPerUser);
	}

	function updateItemsWeight(uint256[] calldata _ids, int256 _newWeight, address[][] calldata _accounts) external onlyOwner
	{
		uint256 _count = _ids.length;
		require(_accounts.length == _count, "invalid length");
		require(-1e18 <= _newWeight && _newWeight <= 1e18, "invalid weight");
		for (uint256 _i = 0; _i < _count; _i++) {
			uint256 _id = _ids[_i];
			TokenInfo storage _tokenInfo = tokenInfo[_id];
			int256 _oldWeight = _tokenInfo.weight;
			_tokenInfo.weight = _newWeight;
			uint256 _tokenCount = 0;
			uint256 _subcount = _accounts[_i].length;
			for (uint256 _j = 0; _j < _subcount; _j++) {
				address _account = _accounts[_i][_j];
				uint256 _amount = userInfo2[_account].userTokenInfo[_id].amount;
				uint256 _factor = lockInfo[_account].factor;
				uint256 _oldShares = _amount * uint256(1e18 + _oldWeight);
				uint256 _newShares = _amount * uint256(1e18 + _newWeight);
				_adjust(_account, _oldShares + _oldShares * _factor / 1e18, _newShares + _newShares * _factor / 1e18);
				_tokenCount += _amount;
			}
			require(_tokenCount == _tokenInfo.amount, "incomplete list");
		}
		emit UpdateItemsWeight(_ids, _newWeight);
	}

	event Lock(address indexed _account, uint256 _cycle, uint256 _factor);
	event Deposit(address indexed _account, uint256[] _ids, uint256[] _amounts);
	event Withdraw(address indexed _account, uint256[] _ids, uint256[] _amounts);
	event EmergencyWithdraw(address indexed _account, uint256[] _ids, uint256[] _amounts);
	event Exit(address indexed _account, uint256[] _ids, uint256[] _amounts);
	event UpdatePoolLimitsPerUser(uint256 _poolMinPerUser, uint256 _poolMaxPerUser);
	event UpdateItemsWeight(uint256[] _ids, int256 _weight);
}