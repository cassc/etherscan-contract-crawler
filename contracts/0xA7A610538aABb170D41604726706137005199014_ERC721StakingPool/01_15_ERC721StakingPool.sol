// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.9;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { ERC721Holder } from "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

import { LockCycle } from "./LockCycle.sol";
import { BaseStakingPool } from "./BaseStakingPool.sol";

contract ERC721StakingPool is LockCycle, BaseStakingPool, ERC721Holder
{
	using SafeERC20 for IERC20;

	struct UserInfo2 {
		uint256 userTokenCount;
	}

	struct TokenInfo {
		address owner;
		int256 weight;
	}

	uint256 public constant POOL_MAX_PER_USER = 20;

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

	function deposit(uint256[] calldata _tokenIdList, bool _claimRewards) external payable nonReentrant collectFee(0)
	{
		if (_claimRewards) {
			_harvestAll(msg.sender);
		}
		uint256 _count = _tokenIdList.length;
		UserInfo2 storage _userInfo2 = userInfo2[msg.sender];
		uint256 _oldCount = _userInfo2.userTokenCount;
		uint256 _newCount = _oldCount + _count;
		if (_newCount > 0) {
			require(poolMinPerUser <= _newCount && _newCount <= poolMaxPerUser, "invalid balance");
		}
		if (_count > 0) {
			_userInfo2.userTokenCount = _newCount;
			for (uint256 _i = 0; _i < _count; _i++) {
				uint256 _tokenId = _tokenIdList[_i];
				TokenInfo storage _tokenInfo = tokenInfo[_tokenId];
				require(_tokenInfo.owner == address(0), "invalid owner");
				IERC721(collection).safeTransferFrom(msg.sender, address(this), _tokenId);
				_tokenInfo.owner = msg.sender;
			}
			tokenCount += _count;
		}
		emit Deposit(msg.sender, _tokenIdList);
		{
			uint256 _factor = _pushLock(msg.sender);
			uint256 _shares = 0;
			for (uint256 _i = 0; _i < _count; _i++) {
				_shares += uint256(1e18 + tokenInfo[_tokenIdList[_i]].weight);
			}
			_deposit(msg.sender, _shares + _shares * _factor / 1e18);
		}
	}

	function withdraw(uint256[] calldata _tokenIdList, bool _claimRewards) external payable nonReentrant collectFee(0)
	{
		if (_claimRewards) {
			_harvestAll(msg.sender);
		}
		uint256 _factor = _checkLock(msg.sender);
		uint256 _count = _tokenIdList.length;
		UserInfo2 storage _userInfo2 = userInfo2[msg.sender];
		uint256 _oldCount = _userInfo2.userTokenCount;
		require(_count <= _oldCount, "insufficient balance");
		uint256 _newCount = _oldCount - _count;
		if (_newCount > 0) {
			require(poolMinPerUser <= _newCount && _newCount <= poolMaxPerUser, "invalid balance");
		}
		if (_count > 0) {
			_userInfo2.userTokenCount = _newCount;
			for (uint256 _i = 0; _i < _count; _i++) {
				uint256 _tokenId = _tokenIdList[_i];
				TokenInfo storage _tokenInfo = tokenInfo[_tokenId];
				require(_tokenInfo.owner == msg.sender, "invalid owner");
				IERC721(collection).safeTransferFrom(address(this), msg.sender, _tokenId);
				_tokenInfo.owner = address(0);
			}
			tokenCount -= _count;
		}
		emit Withdraw(msg.sender, _tokenIdList);
		{
			uint256 _shares = 0;
			for (uint256 _i = 0; _i < _count; _i++) {
				_shares += uint256(1e18 + tokenInfo[_tokenIdList[_i]].weight);
			}
			_withdraw(msg.sender, _shares + _shares * _factor / 1e18);
		}
	}

	function emergencyWithdraw(uint256[] calldata _tokenIdList) external payable nonReentrant collectFee(0)
	{
		_checkLock(msg.sender);
		uint256 _count = _tokenIdList.length;
		UserInfo2 storage _userInfo2 = userInfo2[msg.sender];
		uint256 _oldCount = _userInfo2.userTokenCount;
		require(_count == _oldCount, "incomplete list");
		if (_count > 0) {
			_userInfo2.userTokenCount = 0;
			for (uint256 _i = 0; _i < _count; _i++) {
				uint256 _tokenId = _tokenIdList[_i];
				TokenInfo storage _tokenInfo = tokenInfo[_tokenId];
				require(_tokenInfo.owner == msg.sender, "invalid owner");
				IERC721(collection).safeTransferFrom(address(this), msg.sender, _tokenId);
				_tokenInfo.owner = address(0);
			}
			tokenCount -= _count;
		}
		emit EmergencyWithdraw(msg.sender, _tokenIdList);
		_emergencyWithdraw(msg.sender);
	}

	function exit(uint256[] calldata _tokenIdList) external payable nonReentrant collectFee(0)
	{
		_checkLock(msg.sender);
		uint256 _count = _tokenIdList.length;
		UserInfo2 storage _userInfo2 = userInfo2[msg.sender];
		uint256 _oldCount = _userInfo2.userTokenCount;
		require(_count == _oldCount, "incomplete list");
		if (_count > 0) {
			_userInfo2.userTokenCount = 0;
			for (uint256 _i = 0; _i < _count; _i++) {
				uint256 _tokenId = _tokenIdList[_i];
				TokenInfo storage _tokenInfo = tokenInfo[_tokenId];
				require(_tokenInfo.owner == msg.sender, "invalid owner");
				IERC721(collection).safeTransferFrom(address(this), msg.sender, _tokenId);
				_tokenInfo.owner = address(0);
			}
			tokenCount -= _count;
		}
		emit Exit(msg.sender, _tokenIdList);
		_exit(msg.sender);
	}

	function updatePoolLimitsPerUser(uint256 _poolMinPerUser, uint256 _poolMaxPerUser) external onlyOwner
	{
		require(_poolMaxPerUser <= POOL_MAX_PER_USER, "hard limit");
		require(_poolMinPerUser <= _poolMaxPerUser, "invalid limits");
		if (tokenCount > 0) {
			require(_poolMinPerUser <= poolMinPerUser && poolMaxPerUser <= _poolMaxPerUser, "unexpanded limits");
		}
		poolMinPerUser = _poolMinPerUser;
		poolMaxPerUser = _poolMaxPerUser;
		emit UpdatePoolLimitsPerUser(_poolMinPerUser, _poolMaxPerUser);
	}

	function updateItemsWeight(uint256[] calldata _tokenIdList, int256 _newWeight) external onlyOwner
	{
		require(-1e18 <= _newWeight && _newWeight <= 1e18, "invalid weight");
		uint256 _count = _tokenIdList.length;
		for (uint256 _i = 0; _i < _count; _i++) {
			TokenInfo storage _tokenInfo = tokenInfo[_tokenIdList[_i]];
			int256 _oldWeight = _tokenInfo.weight;
			_tokenInfo.weight = _newWeight;
			address _account = _tokenInfo.owner;
			if (_account != address(0)) {
				uint256 _factor = lockInfo[_account].factor;
				uint256 _oldShares = uint256(1e18 + _oldWeight);
				uint256 _newShares = uint256(1e18 + _newWeight);
				_adjust(_account, _oldShares + _oldShares * _factor / 1e18, _newShares + _newShares * _factor / 1e18);
			}
		}
		emit UpdateItemsWeight(_tokenIdList, _newWeight);
	}

	event Lock(address indexed _account, uint256 _cycle, uint256 _factor);
	event Deposit(address indexed _account, uint256[] _tokenIdList);
	event Withdraw(address indexed _account, uint256[] _tokenIdList);
	event EmergencyWithdraw(address indexed _account, uint256[] _tokenIdList);
	event Exit(address indexed _account, uint256[] _tokenIdList);
	event UpdatePoolLimitsPerUser(uint256 _poolMinPerUser, uint256 _poolMaxPerUser);
	event UpdateItemsWeight(uint256[] _tokenIdList, int256 _weight);
}