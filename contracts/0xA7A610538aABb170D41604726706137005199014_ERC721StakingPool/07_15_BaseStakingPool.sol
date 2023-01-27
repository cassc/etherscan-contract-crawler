// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.9;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Initializable } from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";

import { FeeCollectionManager } from "./FeeCollectionManager.sol";

abstract contract BaseStakingPool is Ownable, ReentrancyGuard, Initializable
{
	using Address for address payable;
	using SafeERC20 for IERC20;

	struct RewardInfo {
		uint256 index;
		uint256 rewardBalance;
		uint256 rewardPerSec;
		uint256 accRewardPerShare18;
	}

	struct UserRewardInfo {
		uint256 accReward;
		uint256 rewardDebt18;
	}

	struct UserInfo1 {
		uint256 shares;
		mapping(address => UserRewardInfo) userRewardInfo;
	}

	uint256 public constant MAX_REWARD_TOKENS = 10;

	address public factory;

	uint256 public totalShares;
	uint256 public lastRewardTimestamp;
	address[] public rewardToken;
	mapping(address => RewardInfo) public rewardInfo;
	mapping(address => UserInfo1) public userInfo1;
	bool public rewardPerUnit;
	uint256 public rewardMultiplier;

	modifier collectFee(uint256 _netValue)
	{
		{
			bytes4 _selector = bytes4(msg.data);
			uint256 _fixedValueFee = FeeCollectionManager(factory).fixedValueFee(_selector);
			require(msg.value == _netValue + _fixedValueFee, "invalid value");
			if (_fixedValueFee > 0) {
				FeeCollectionManager(factory).feeRecipient().sendValue(_fixedValueFee);
			}
		}
		_;
	}

	function initialize(address _owner, address _token) public virtual;

	function _initialize(address _owner) internal
	{
		_transferOwnership(_owner);
		factory = msg.sender;
		lastRewardTimestamp = block.timestamp;
		rewardPerUnit = false;
		rewardMultiplier = 1e18;
	}

	function rewardTokenCount() external view returns (uint256 _rewardTokenCount)
	{
		return rewardToken.length;
	}

	function userRewardInfo(address _account, address _rewardToken) external view returns (UserRewardInfo memory _userRewardInfo)
	{
		return userInfo1[_account].userRewardInfo[_rewardToken];
	}

	function pendingReward(address _account, address _rewardToken) external view returns (uint256 _pendingReward)
	{
		RewardInfo storage _rewardInfo = rewardInfo[_rewardToken];
		uint256 _accRewardPerShare18 = _rewardInfo.accRewardPerShare18;
		if (block.timestamp > lastRewardTimestamp) {
			if (totalShares > 0) {
				uint256 _reward = ((block.timestamp - lastRewardTimestamp) * _rewardInfo.rewardPerSec * rewardMultiplier) / 1e18;
				uint256 _maxReward = freeBalance(_rewardToken);
				if (_reward > _maxReward) _reward = _maxReward;
				if (_reward > 0) {
					_accRewardPerShare18 += _reward * 1e18 / totalShares;
				}
			}
		}
		UserInfo1 storage _userInfo = userInfo1[_account];
		UserRewardInfo storage _userRewardInfo = _userInfo.userRewardInfo[_rewardToken];
		return _userRewardInfo.accReward + (_userInfo.shares * _accRewardPerShare18 - _userRewardInfo.rewardDebt18) / 1e18;
	}

	function harvestAll() external payable nonReentrant collectFee(0)
	{
		_harvestAll(msg.sender);
	}

	function harvest(address _rewardToken) external payable nonReentrant collectFee(0)
	{
		_harvest(msg.sender, _rewardToken);
	}

	function addRewardToken(address _rewardToken) external onlyOwner
	{
		_updatePool();
		RewardInfo storage _rewardInfo = rewardInfo[_rewardToken];
		require(_rewardInfo.index == 0, "duplicate token");
		uint256 _length = rewardToken.length;
		require(_length < MAX_REWARD_TOKENS, "limit reached");
		rewardToken.push(_rewardToken);
		_rewardInfo.index = _length + 1;
		emit AddRewardToken(_rewardToken);
	}

	function removeRewardToken(address _rewardToken) external onlyOwner
	{
		_updatePool();
		RewardInfo storage _rewardInfo = rewardInfo[_rewardToken];
		uint256 _index = _rewardInfo.index;
		require(_index > 0, "unknown token");
		require(_rewardInfo.rewardBalance == 0, "pending reward");
		_rewardInfo.index = 0;
		_rewardInfo.rewardPerSec = 0;
		_rewardInfo.accRewardPerShare18 = 0;
		uint256 _length = rewardToken.length;
		if (_index < _length) {
			address _otherRewardToken = rewardToken[_length - 1];
			rewardInfo[_otherRewardToken].index = _index;
			rewardToken[_index - 1] = _otherRewardToken;
		}
		rewardToken.pop();
		emit RemoveRewardToken(_rewardToken);
	}

	function updateRewardPerSec(address _rewardToken, uint256 _rewardPerSec) external onlyOwner
	{
		_updatePool();
		RewardInfo storage _rewardInfo = rewardInfo[_rewardToken];
		require(_rewardInfo.index > 0, "unknown token");
		_rewardInfo.rewardPerSec = _rewardPerSec;
		emit UpdateRewardPerSec(_rewardToken, _rewardPerSec);
	}

	function updateRewardPerUnit(bool _rewardPerUnit) external onlyOwner
	{
		_updatePool();
		rewardPerUnit = _rewardPerUnit;
		rewardMultiplier = _rewardPerUnit ? totalShares : 1e18;
		emit UpdateRewardPerUnit(_rewardPerUnit);
	}

	function addRewardFunds(address _rewardToken, uint256 _amount) external onlyOwner nonReentrant
	{
		_updatePool();
		RewardInfo storage _rewardInfo = rewardInfo[_rewardToken];
		require(_rewardInfo.index > 0, "unknown token");
		IERC20(_rewardToken).safeTransferFrom(msg.sender, address(this), _amount);
		emit AddRewardFunds(_rewardToken, _amount);
	}

	function recoverFunds(address _token) external onlyOwner nonReentrant returns (uint256 _amount)
	{
		_updatePool();
		_amount = freeBalance(_token);
		IERC20(_token).safeTransfer(msg.sender, _amount);
		emit RecoverFunds(_token, _amount);
	}

	function _harvestAll(address _account) internal
	{
		UserInfo1 storage _userInfo = userInfo1[_account];
		uint256 _shares = _userInfo.shares;
		if (_shares > 0) {
			_updatePool();
			_updateUserReward(_userInfo, _shares, _shares);
		}
		_harvestAllUserReward(_account, _userInfo);
		emit HarvestAll(_account);
	}

	function _harvest(address _account, address _rewardToken) internal
	{
		UserInfo1 storage _userInfo = userInfo1[_account];
		uint256 _shares = _userInfo.shares;
		if (_shares > 0) {
			_updatePool();
			_updateUserReward(_userInfo, _shares, _shares);
		}
		_harvestUserReward(_account, _userInfo, _rewardToken);
	}

	function _deposit(address _account, uint256 _shares) internal
	{
		if (_shares > 0) {
			UserInfo1 storage _userInfo1 = userInfo1[_account];
			uint256 _oldShares = _userInfo1.shares;
			uint256 _newShares = _oldShares + _shares;
			_updatePool();
			_updateUserReward(_userInfo1, _oldShares, _newShares);
			_userInfo1.shares = _newShares;
			totalShares += _shares;
			if (rewardPerUnit) {
				rewardMultiplier = totalShares;
			}
		}
	}

	function _withdraw(address _account, uint256 _shares) internal
	{
		if (_shares > 0) {
			UserInfo1 storage _userInfo1 = userInfo1[_account];
			uint256 _oldShares = _userInfo1.shares;
			uint256 _newShares = _oldShares - _shares;
			_updatePool();
			_updateUserReward(_userInfo1, _oldShares, _newShares);
			_userInfo1.shares = _newShares;
			totalShares -= _shares;
			if (rewardPerUnit) {
				rewardMultiplier = totalShares;
			}
		}
	}

	function _emergencyWithdraw(address _account) internal
	{
		UserInfo1 storage _userInfo1 = userInfo1[_account];
		uint256 _shares = _userInfo1.shares;
		if (_shares > 0) {
			_discardUserReward(_userInfo1);
			_userInfo1.shares = 0;
			totalShares -= _shares;
			if (rewardPerUnit) {
				rewardMultiplier = totalShares;
			}
		}
	}

	function _exit(address _account) internal
	{
		UserInfo1 storage _userInfo1 = userInfo1[_account];
		uint256 _shares = _userInfo1.shares;
		if (_shares > 0) {
			_updatePool();
			_updateUserReward(_userInfo1, _shares, 0);
			_userInfo1.shares = 0;
			totalShares -= _shares;
			if (rewardPerUnit) {
				rewardMultiplier = totalShares;
			}
		}
		_harvestAllUserReward(_account, _userInfo1);
	}

	function _adjust(address _account, uint256 _negativeShares, uint256 _positiveShares) internal
	{
		if (_negativeShares != _positiveShares) {
			UserInfo1 storage _userInfo1 = userInfo1[_account];
			uint256 _oldShares = _userInfo1.shares;
			uint256 _newShares = _oldShares - _negativeShares + _positiveShares;
			_updatePool();
			_updateUserReward(_userInfo1, _oldShares, _newShares);
			_userInfo1.shares = _newShares;
			totalShares = totalShares - _negativeShares + _positiveShares;
			if (rewardPerUnit) {
				rewardMultiplier = totalShares;
			}
		}
	}

	function freeBalance(address _token) public view virtual returns(uint256 _balance)
	{
		_balance = IERC20(_token).balanceOf(address(this));
		_balance -= rewardInfo[_token].rewardBalance;
		return _balance;
	}

	function _updatePool() private
	{
		if (block.timestamp > lastRewardTimestamp) {
			if (totalShares > 0) {
				uint256 _ellapsed = block.timestamp - lastRewardTimestamp;
				uint256 _length = rewardToken.length;
				for (uint256 _i = 0; _i < _length; _i++) {
					address _rewardToken = rewardToken[_i];
					RewardInfo storage _rewardInfo = rewardInfo[_rewardToken];
					uint256 _reward = (_ellapsed * _rewardInfo.rewardPerSec * rewardMultiplier) / 1e18;
					uint256 _maxReward = freeBalance(_rewardToken);
					if (_reward > _maxReward) _reward = _maxReward;
					if (_reward > 0) {
						_rewardInfo.rewardBalance += _reward;
						_rewardInfo.accRewardPerShare18 += _reward * 1e18 / totalShares;
					}
				}
			}
			lastRewardTimestamp = block.timestamp;
		}
	}

	function _discardUserReward(UserInfo1 storage _userInfo) private
	{
		uint256 _length = rewardToken.length;
		for (uint256 _i = 0; _i < _length; _i++) {
			_userInfo.userRewardInfo[rewardToken[_i]].rewardDebt18 = 0;
		}
	}

	function _updateUserReward(UserInfo1 storage _userInfo, uint256 _oldShares, uint256 _newShares) private
	{
		uint256 _length = rewardToken.length;
		for (uint256 _i = 0; _i < _length; _i++) {
			address _rewardToken = rewardToken[_i];
			uint256 _accRewardPerShare18 = rewardInfo[_rewardToken].accRewardPerShare18;
			UserRewardInfo storage _userRewardInfo = _userInfo.userRewardInfo[_rewardToken];
			if (_oldShares > 0) {
				_userRewardInfo.accReward += (_oldShares * _accRewardPerShare18 - _userRewardInfo.rewardDebt18) / 1e18;
			}
			_userRewardInfo.rewardDebt18 = _newShares * _accRewardPerShare18;
		}
	}

	function _harvestAllUserReward(address _account, UserInfo1 storage _userInfo) private
	{
		uint256 _length = rewardToken.length;
		for (uint256 _i = 0; _i < _length; _i++) {
			_harvestUserReward(_account, _userInfo, rewardToken[_i]);
		}
	}

	function _harvestUserReward(address _account, UserInfo1 storage _userInfo, address _rewardToken) private
	{
		UserRewardInfo storage _userRewardInfo = _userInfo.userRewardInfo[_rewardToken];
		uint256 _reward = _userRewardInfo.accReward;
		if (_reward > 0) {
			_userRewardInfo.accReward = 0;
			IERC20(_rewardToken).safeTransfer(_account, _reward);
			rewardInfo[_rewardToken].rewardBalance -= _reward;
			emit Harvest(_account, _rewardToken, _reward);
		}
	}

	event AddRewardToken(address indexed _rewardToken);
	event RemoveRewardToken(address indexed _rewardToken);
	event UpdateRewardPerSec(address indexed _rewardToken, uint256 _rewardPerSec);
	event UpdateRewardPerUnit(bool _rewardPerUnit);
	event AddRewardFunds(address indexed _rewardToken, uint256 _amount);
	event RecoverFunds(address indexed _token, uint256 _amount);
	event HarvestAll(address indexed _account);
	event Harvest(address indexed _account, address indexed _rewardToken, uint256 _amount);
}