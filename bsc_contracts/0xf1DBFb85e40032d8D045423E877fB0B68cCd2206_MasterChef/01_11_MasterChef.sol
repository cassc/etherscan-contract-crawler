// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.9;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Initializable } from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import { FarmingCompound } from "./FarmingCompound.sol";
import { FarmingVolatile } from "./FarmingVolatile.sol";
import { GrowthBonding } from "../growth/GrowthBonding.sol";

contract MasterChef is Initializable, Ownable, ReentrancyGuard
{
	using SafeERC20 for IERC20;

	struct PoolInfo {
		address token;
		uint256 allocPoint;
		uint256 lastRewardTime;
		uint256 accRewardPerShare;
		uint256 amount;
		uint256 depositFee;
		uint256 withdrawalFee;
		uint256 epochAccRewardPerShare;
	}

	struct UserInfo {
		uint256 amount;
		uint256 rewardDebt;
		uint256 unclaimedReward;
	}

	struct ReferralInfo {
		uint256 volume;
		uint256 reward;
	}

	struct AccountInfo {
		bool exists;
		uint256 reserved0;
		uint256 reserved1;
		uint256 reserved2;
		uint256 reserved3;
	}

	address constant FURNACE = 0x000000000000000000000000000000000000dEaD;

	address constant DEFAULT_FAUCET = 0x392681Eaf8AD9BC65e74BE37Afe7503D92802b7d; // multisig
	address constant DEFAULT_BANKROLL = 0x392681Eaf8AD9BC65e74BE37Afe7503D92802b7d; // multisig

	uint256 constant DEFAULT_LAUNCH_TIME = 1663776000; // 2022-09-21 4PM UTC

	uint256[4] public defaultFees = [2.5e16, 5e16, 10e16, 20e16];
	uint256[4] public defaultAllocs = [11.25e16, 16.25e16, 26.25e16, 46.25e16];

	uint256 public epochPeriod = 1 weeks;
	uint256[6] public epochLengthPerPeriod = [24 hours, 20 hours, 16 hours, 12 hours, 8 hours, 6 hours];

	address public rewardToken;
	address public tokenBridge;

	address public farmingCompound;
	address public farmingVolatile;

	address public faucet = DEFAULT_FAUCET;
	address public bankroll = DEFAULT_BANKROLL;

	uint256 public launchTime = DEFAULT_LAUNCH_TIME;
	uint256 public nextEpoch = launchTime + epochLengthPerPeriod[0];

	uint256 public rewardPerSec = 0;
	uint256 public totalAllocPoint = 0;

	uint256 public allocReward = 0;

	PoolInfo[] public poolInfo;

	mapping(uint256 => mapping(address => UserInfo)) public userInfo;

	uint256 public epochIndex = 0;

	ReferralInfo[2] public referralInfo;
	mapping(address => mapping(uint256 => uint256)) public userReferralVolume;

	uint256 constant DEFAULT_CLAIM_FEE = 20e16; // 20%

	uint256 public claimFee = DEFAULT_CLAIM_FEE;

	uint256 constant BASE_WEEK_TIME = 1663722000;  // 2022-09-21 01:00 UTC

	address[] public accountIndex;
	mapping(address => AccountInfo) public accountInfo;

	function accountIndexLength() external view returns (uint256 _length)
	{
		return accountIndex.length;
	}

	function getAccountByIndex(uint256 _index) external view returns (AccountInfo memory _accountInfo)
	{
		return accountInfo[accountIndex[_index]];
	}

	function getUserByIndex(uint256 _pid, uint256 _index) external view returns (UserInfo memory _userInfo)
	{
		return userInfo[_pid][accountIndex[_index]];
	}

	function indexAccounts(address[] memory _accounts) external onlyOwner
	{
		for (uint256 _i = 0; _i < _accounts.length; _i++) {
			_indexAccount(_accounts[_i]);
		}
	}

	function _indexAccount(address _account) internal
	{
		AccountInfo storage _accountInfo = accountInfo[_account];
		if (!_accountInfo.exists) {
			// adds account to index
			_accountInfo.exists = true;
			accountIndex.push(_account);
		}
	}

	function epochLength(uint256 /*_when*/) public pure returns (uint256 _epochLength)
	{
		return 24 hours;
		/*
		if (_when < BASE_WEEK_TIME) _when = BASE_WEEK_TIME;
		uint256 _i = (_when - BASE_WEEK_TIME) / epochPeriod;
		if (_i > 5) _i = 5;
		return epochLengthPerPeriod[_i];
		*/
	}

	modifier hasLaunched()
	{
		require(block.timestamp >= launchTime, "unavailable");
		_;
	}

	constructor(address _rewardToken, address _tokenBridge, address _farmingCompound, address _farmingVolatile)
	{
		initialize(msg.sender, _rewardToken, _tokenBridge, _farmingCompound, _farmingVolatile);
	}

	function initialize(address _owner, address _rewardToken, address _tokenBridge, address _farmingCompound, address _farmingVolatile) public initializer
	{
		_transferOwnership(_owner);

		defaultFees = [2.5e16, 5e16, 10e16, 20e16];
		defaultAllocs = [11.25e16, 16.25e16, 26.25e16, 46.25e16];

		epochPeriod = 1 weeks;
		epochLengthPerPeriod = [24 hours, 20 hours, 16 hours, 12 hours, 8 hours, 6 hours];

		faucet = DEFAULT_FAUCET;
		bankroll = DEFAULT_BANKROLL;

		launchTime = DEFAULT_LAUNCH_TIME;
		nextEpoch = launchTime + epochLengthPerPeriod[0];

		rewardPerSec = 0;
		totalAllocPoint = 0;

		allocReward = 0;

		epochIndex = 0;

		claimFee = DEFAULT_CLAIM_FEE;

		rewardToken = _rewardToken;
		tokenBridge = _tokenBridge;

		farmingCompound = _farmingCompound;
		farmingVolatile = _farmingVolatile;
	}

	function setFaucet(address _faucet) external onlyOwner
	{
		require(_faucet != address(0), "invalid address");
		faucet = _faucet;
	}

	function setBankroll(address _bankroll) external onlyOwner
	{
		require(_bankroll != address(0), "invalid address");
		bankroll = _bankroll;
	}
/*
	function setTokenBridge(address _tokenBridge) external onlyOwner
	{
		tokenBridge = _tokenBridge;
	}
*/
	function setLaunchTime(uint256 _launchTime) external onlyOwner
	{
		require(block.timestamp < launchTime, "unavailable");
		require(_launchTime >= block.timestamp, "invalid time");
		for (uint256 _pid = 0; _pid < poolInfo.length; _pid++) {
			PoolInfo storage _poolInfo = poolInfo[_pid];
			if (_poolInfo.lastRewardTime <= launchTime) {
				_poolInfo.lastRewardTime = _launchTime;
			}
		}
		launchTime = _launchTime;
		nextEpoch = _launchTime + epochLengthPerPeriod[0];
	}

	function updateEpochPeriod(uint256 _period) external onlyOwner
	{
		require(_period > 0, "invalid period");
		epochPeriod = _period;
	}

	function updateEpochLengthPerPeriod(uint256 _i, uint256 _length) external onlyOwner
	{
		require(_i < 6, "invalid index");
		require(_length > 0, "invalid length");
		epochLengthPerPeriod[_i] = _length;
		if (block.timestamp < launchTime && _i == 0) {
			nextEpoch = launchTime + epochLengthPerPeriod[0];
		}
	}

	function updateNextEpoch(uint256 _nextEpoch) external onlyOwner
	{
		require(_nextEpoch > block.timestamp, "invalid time");
		nextEpoch = _nextEpoch;
	}

	function updateRewardPerSec(uint256 _rewardPerSec) external onlyOwner nonReentrant
	{
		_massUpdatePools();
		rewardPerSec = _rewardPerSec;
	}

	function addPool(address _token, uint256 _allocPoint, uint256 _startTime, uint256 _depositFee, uint256 _withdrawalFee) external onlyOwner nonReentrant
	{
		require(_token != address(0), "invalid address");
		require(_startTime >= launchTime && _startTime >= block.timestamp, "invalid timestamp");
		require(_depositFee <= 100e16, "invalid rate");
		require(_withdrawalFee <= 100e16, "invalid rate");
		_massUpdatePools();
		totalAllocPoint += _allocPoint;
		poolInfo.push(PoolInfo({
			token: _token,
			allocPoint: _allocPoint,
			lastRewardTime: _startTime,
			accRewardPerShare: 0,
			amount: 0,
			depositFee: _depositFee,
			withdrawalFee: _withdrawalFee,
			epochAccRewardPerShare: 0
		}));
		for (uint256 _i = 1; _i < 4; _i++) {
			poolInfo.push(PoolInfo({
				token: _token,
				allocPoint: 0,
				lastRewardTime: type(uint256).max,
				accRewardPerShare: 0,
				amount: 0,
				depositFee: 100e16,
				withdrawalFee: 100e16,
				epochAccRewardPerShare: 0
			}));
		}
	}

	function updatePoolAllocPoints(uint256 _pid, uint256 _allocPoint) external onlyOwner nonReentrant
	{
		require(_pid % 4 == 0, "invalid pid");
		_massUpdatePools();
		PoolInfo storage _poolInfo = poolInfo[_pid];
		totalAllocPoint -= _poolInfo.allocPoint;
		_poolInfo.allocPoint = _allocPoint;
		totalAllocPoint += _poolInfo.allocPoint;
	}

	function addCluster(address _token, uint256 _allocPoint, uint256 _startTime) external onlyOwner nonReentrant
	{
		require(_token != address(0), "invalid address");
		require(_startTime >= launchTime && _startTime >= block.timestamp, "invalid timestamp");
		_massUpdatePools();
		totalAllocPoint += _allocPoint;
		for (uint256 _i = 0; _i < 4; _i++) {
			poolInfo.push(PoolInfo({
				token: _token,
				allocPoint: _allocPoint * defaultAllocs[_i] / 100e16,
				lastRewardTime: _startTime,
				accRewardPerShare: 0,
				amount: 0,
				depositFee: defaultFees[_i],
				withdrawalFee: defaultFees[_i],
				epochAccRewardPerShare: 0
			}));
		}
	}

	function updateClusterAllocPoints(uint256 _pid, uint256 _allocPoint) external onlyOwner nonReentrant
	{
		require(_pid % 4 == 0, "invalid pid");
		_massUpdatePools();
		for (uint256 _i = 0; _i < 4; _i++) {
			PoolInfo storage _poolInfo = poolInfo[_pid + _i];
			totalAllocPoint -= _poolInfo.allocPoint;
			_poolInfo.allocPoint = _allocPoint * defaultAllocs[_i] / 100e16;
			totalAllocPoint += _poolInfo.allocPoint;
		}
	}

	function setClaimFee(uint256 _claimFee) external onlyOwner
	{
		require(_claimFee <= 100e16, "invalid rate");
		claimFee = _claimFee;
	}

	function recoverLostFunds(address _token) external onlyOwner nonReentrant
	{
		uint256 _amount = 0;
		for (uint256 _pid = 0; _pid < poolInfo.length; _pid++) {
			PoolInfo storage _poolInfo = poolInfo[_pid];
			if (_token == _poolInfo.token) {
				_amount += _poolInfo.amount;
			}
		}
		uint256 _balance = IERC20(_token).balanceOf(address(this));
		IERC20(_token).safeTransfer(msg.sender, _balance - _amount);
	}

	function massUpdatePools() external nonReentrant
	{
		_massUpdatePools();
	}

	function updatePool(uint256 _pid) external nonReentrant
	{
		_updatePool(_pid);
	}

	function updateEpoch() external nonReentrant
	{
		_updateEpoch();
	}

	function pendingReferral(address _account) external nonReentrant returns (uint256 _amount)
	{
		_updateEpoch();
		require(epochIndex > 0, "unavailable");
		uint256 _lastEpoch = epochIndex - 1;
		uint256 _volume = userReferralVolume[_account][_lastEpoch];
		if (_volume == 0) return 0;
		uint256 _index = _lastEpoch % 2;
		uint256 _totalVolume = referralInfo[_index].volume;
		uint256 _totalReward = referralInfo[_index].reward;
		return _volume * _totalReward / _totalVolume;
	}

	function pendingReward(uint256 _pid, address _account) external nonReentrant returns (uint256 _reward)
	{
		PoolInfo storage _poolInfo = poolInfo[_pid];
		UserInfo storage _userInfo = userInfo[_pid][_account];
		_updatePool(_pid);
		{
			uint256 epochRewardDebt = _userInfo.amount * _poolInfo.epochAccRewardPerShare / 1e18;
			if (epochRewardDebt > _userInfo.rewardDebt) _userInfo.rewardDebt = epochRewardDebt;
		}
		return _userInfo.amount * _poolInfo.accRewardPerShare / 1e18 - _userInfo.rewardDebt + _userInfo.unclaimedReward;
	}

	function deposit(uint256 _pid, uint256 _amount) external nonReentrant hasLaunched
	{
		_depositOnBehalfOf(msg.sender, _pid, _amount, msg.sender, address(0));
	}

	function depositOnBehalfOf(uint256 _pid, uint256 _amount, address _account, address _referral) external nonReentrant hasLaunched
	{
		require(msg.sender == _account || msg.sender == tokenBridge, "access denied");
		_depositOnBehalfOf(msg.sender, _pid, _amount, _account, _referral);
	}

	function _depositOnBehalfOf(address _sender, uint256 _pid, uint256 _amount, address _account, address _referral) internal
	{
		PoolInfo storage _poolInfo = poolInfo[_pid];
		UserInfo storage _userInfo = userInfo[_pid][_account];
		_indexAccount(_account);
		_updatePool(_pid);
		if (_referral != address(0) && _referral != _sender) {
			userReferralVolume[_referral][epochIndex] += _amount;
			uint256 _index = epochIndex % 2;
			referralInfo[_index].volume += _amount;
			emit Referral(_referral, epochIndex, _amount);
		}
		if (_userInfo.amount > 0) {
			{
				uint256 epochRewardDebt = _userInfo.amount * _poolInfo.epochAccRewardPerShare / 1e18;
				if (epochRewardDebt > _userInfo.rewardDebt) _userInfo.rewardDebt = epochRewardDebt;
			}
			uint256 _reward = _userInfo.amount * _poolInfo.accRewardPerShare / 1e18 - _userInfo.rewardDebt;
			if (_reward > 0) {
				allocReward -= _reward;
				_userInfo.unclaimedReward += _reward;
			}
		}
		if (_amount > 0) {
			uint256 _feeAmount = _amount * _poolInfo.depositFee / 1e18;
			uint256 _netAmount = _amount - _feeAmount;
			_userInfo.amount += _netAmount;
			_poolInfo.amount += _netAmount;
			if (_sender != address(this)) {
				IERC20(_poolInfo.token).safeTransferFrom(_sender, address(this), _netAmount);
			}
			if (_feeAmount > 0) {
				if (_sender == address(this)) {
					IERC20(_poolInfo.token).safeTransfer(bankroll, _feeAmount);
				} else {
					IERC20(_poolInfo.token).safeTransferFrom(_sender, bankroll, _feeAmount);
				}
			}
		}
		_userInfo.rewardDebt = _userInfo.amount * _poolInfo.accRewardPerShare / 1e18;
		emit Deposit(_account, _pid, _amount);
	}

	function withdraw(uint256 _pid, uint256 _amount) external
	{
		withdrawOnBehalfOf(_pid, _amount, msg.sender);
	}

	function withdrawOnBehalfOf(uint256 _pid, uint256 _amount, address _account) public nonReentrant
	{
		require(msg.sender == _account || msg.sender == tokenBridge, "access denied");
		PoolInfo storage _poolInfo = poolInfo[_pid];
		UserInfo storage _userInfo = userInfo[_pid][_account];
		require(_amount <= _userInfo.amount, "insufficient balance");
		_updatePool(_pid);
		{
			{
				uint256 epochRewardDebt = _userInfo.amount * _poolInfo.epochAccRewardPerShare / 1e18;
				if (epochRewardDebt > _userInfo.rewardDebt) _userInfo.rewardDebt = epochRewardDebt;
			}
			uint256 _reward = _userInfo.amount * _poolInfo.accRewardPerShare / 1e18 - _userInfo.rewardDebt;
			if (_reward > 0) {
				allocReward -= _reward;
				_userInfo.unclaimedReward += _reward;
			}
		}
		if (_amount > 0) {
			uint256 _feeAmount = _amount * _poolInfo.withdrawalFee / 1e18;
			uint256 _netAmount = _amount - _feeAmount;
			_userInfo.amount -= _amount;
			_poolInfo.amount -= _amount;
			IERC20(_poolInfo.token).safeTransfer(msg.sender, _netAmount);
			if (_feeAmount > 0) {
				IERC20(_poolInfo.token).safeTransfer(bankroll, _feeAmount);
			}
		}
		_userInfo.rewardDebt = _userInfo.amount * _poolInfo.accRewardPerShare / 1e18;
		emit Withdraw(_account, _pid, _amount);
	}

	function emergencyWithdraw(uint256 _pid) external nonReentrant
	{
		PoolInfo storage _poolInfo = poolInfo[_pid];
		UserInfo storage _userInfo = userInfo[_pid][msg.sender];
		uint256 _amount = _userInfo.amount;
		_userInfo.amount = 0;
		_userInfo.rewardDebt = 0;
		_poolInfo.amount -= _amount;
		uint256 _feeAmount = _amount * _poolInfo.withdrawalFee / 1e18;
		uint256 _netAmount = _amount - _feeAmount;
		IERC20(_poolInfo.token).safeTransfer(msg.sender, _netAmount);
		if (_feeAmount > 0) {
			IERC20(_poolInfo.token).safeTransfer(bankroll, _feeAmount);
		}
		emit EmergencyWithdraw(msg.sender, _pid, _amount);
	}

	function claimReferral() external nonReentrant returns (uint256 _amount)
	{
		_amount = _updateReferral(msg.sender);
		if (_amount > 0) {
			uint256 _feeAmount = _amount * claimFee / 1e18;
			uint256 _netAmount = _amount - _feeAmount;
			allocReward -= _netAmount;
			IERC20(rewardToken).safeTransferFrom(faucet, msg.sender, _netAmount);
		}
		emit ClaimReferral(msg.sender, _amount);
		return _amount;
	}

	function claimReward(uint256 _pid) external nonReentrant returns (uint256 _amount)
	{
		_amount = _updateReward(_pid, msg.sender);
		if (_amount > 0) {
			uint256 _feeAmount = _amount * claimFee / 1e18;
			uint256 _netAmount = _amount - _feeAmount;
			allocReward += _feeAmount;
			IERC20(rewardToken).safeTransferFrom(faucet, msg.sender, _netAmount);

			// claim tax for xGRO is injected into bonds
			if (_pid == 56) { // xGRO
				allocReward -= _feeAmount;
				IERC20(rewardToken).safeTransferFrom(faucet, address(this), _feeAmount);
				address BONDS30 = 0x0885D30B594E30062FD8a542842eA1836395e1B3;
				address BONDS60 = 0xC40d78657f605fcEb905e1Be2B8C7F99CADEb360;
				address BONDS90 = 0x80212AcC56e6f49808dE6A597f46a9475311cd7e;
				uint256 _bonds30Amount = _feeAmount * 15e16 / 100e16; // 15%
				uint256 _bonds60Amount = _bonds30Amount + _bonds30Amount; // 30%
				uint256 _bonds90Amount = _feeAmount - (_bonds30Amount + _bonds60Amount); // 55%
				IERC20(rewardToken).approve(BONDS30, _bonds30Amount);
				GrowthBonding(BONDS30).reward(_bonds30Amount);
				IERC20(rewardToken).approve(BONDS60, _bonds60Amount);
				GrowthBonding(BONDS60).reward(_bonds60Amount);
				IERC20(rewardToken).approve(BONDS90, _bonds90Amount);
				GrowthBonding(BONDS90).reward(_bonds90Amount);
			}
		}
		emit ClaimReward(msg.sender, _pid, _amount);
		return _amount;
	}

	function compoundReferral(uint256 _pid0) external nonReentrant returns (uint256 _amount)
	{
		{
			PoolInfo storage _poolInfo = poolInfo[_pid0];
			require(_pid0 % 4 >= 2 && _poolInfo.token == rewardToken, "invalid pid");
		}
		_amount = _updateReferral(msg.sender);
		if (_amount > 0) {
			allocReward -= _amount;
			IERC20(rewardToken).safeTransferFrom(faucet, address(this), _amount);
			_depositOnBehalfOf(address(this), _pid0, _amount, msg.sender, address(0));
		}
		emit CompoundReferral(msg.sender, _pid0, _amount);
		return _amount;
	}

	function compoundReward(uint256 _pid0, uint256 _pid) external nonReentrant returns (uint256 _amount)
	{

		{
			PoolInfo storage _poolInfo = poolInfo[_pid0];
			require(_pid0 % 4 >= 2 && _poolInfo.token == rewardToken, "invalid pid");
		}
		_amount = _updateReward(_pid, msg.sender);
		if (_amount > 0) {
			IERC20(rewardToken).safeTransferFrom(faucet, address(this), _amount);
			_depositOnBehalfOf(address(this), _pid0, _amount, msg.sender, address(0));
		}
		emit CompoundReward(msg.sender, _pid0, _pid, _amount);
		return _amount;
	}

	function compoundAll(uint256 _pid0, uint256[] memory _pidList) external nonReentrant returns (uint256 _amount)
	{
		{
			PoolInfo storage _poolInfo = poolInfo[_pid0];
			require(_pid0 % 4 >= 2 && _poolInfo.token == rewardToken, "invalid pid");
		}
		_amount = 0;
		for (uint256 _i = 0; _i < _pidList.length; _i++) {
			_amount += _updateReward(_pidList[_i], msg.sender);
		}
		if (_amount > 0) {
			IERC20(rewardToken).safeTransferFrom(faucet, address(this), _amount);
			_depositOnBehalfOf(address(this), _pid0, _amount, msg.sender, address(0));
		}
		emit CompoundAll(msg.sender, _pid0, _amount);
		return _amount;
	}

	function _updateReferral(address _account) internal returns (uint256 _amount)
	{
		_updateEpoch();
		require(epochIndex > 0, "unavailable");
		uint256 _lastEpoch = epochIndex - 1;
		uint256 _volume = userReferralVolume[_account][_lastEpoch];
		if (_volume == 0) return 0;
		userReferralVolume[_account][_lastEpoch] = 0;
		uint256 _index = _lastEpoch % 2;
		uint256 _totalVolume = referralInfo[_index].volume;
		uint256 _totalReward = referralInfo[_index].reward;
		_amount = _volume * _totalReward / _totalVolume;
		referralInfo[_index].volume = _totalVolume - _volume;
		referralInfo[_index].reward = _totalReward - _amount;
		return _amount;
	}

	function _updateReward(uint256 _pid, address _account) internal returns (uint256 _amount)
	{
		PoolInfo storage _poolInfo = poolInfo[_pid];
		UserInfo storage _userInfo = userInfo[_pid][_account];
		_updatePool(_pid);
		if (_userInfo.amount > 0) {
			{
				uint256 epochRewardDebt = _userInfo.amount * _poolInfo.epochAccRewardPerShare / 1e18;
				if (epochRewardDebt > _userInfo.rewardDebt) _userInfo.rewardDebt = epochRewardDebt;
			}
			uint256 _reward = _userInfo.amount * _poolInfo.accRewardPerShare / 1e18 - _userInfo.rewardDebt;
			if (_reward > 0) {
				allocReward -= _reward;
				_userInfo.unclaimedReward += _reward;
			}
		}
		_userInfo.rewardDebt = _userInfo.amount * _poolInfo.accRewardPerShare / 1e18;
		_amount = _userInfo.unclaimedReward;
		_userInfo.unclaimedReward = 0;
		return _amount;
	}

	function _massUpdatePools() internal
	{
		_updateEpoch();
		_massUpdatePools(block.timestamp, false);
	}

	function _updatePool(uint256 _pid) internal
	{
		_updateEpoch();
		_updatePool(_pid, block.timestamp, false);
	}

	function _updateEpoch() internal
	{
		if (block.timestamp < nextEpoch) return;

		uint256 _lastEpoch;
		do {
			_lastEpoch = nextEpoch;
			nextEpoch += epochLength(_lastEpoch);
		} while (nextEpoch <= block.timestamp);

		_massUpdatePools(_lastEpoch, true);

		uint256 _expiredReward = allocReward;

		allocReward = 0;

		epochIndex++;

		{
			uint256 _index = epochIndex % 2;
			referralInfo[_index].volume = 0;
			referralInfo[_index].reward = 0;
		}

		if (_expiredReward > 0) {
			uint256 _10percent = _expiredReward * 10e16 / 100e16;
			uint256 _20percent = _10percent + _10percent;
			uint256 _40percent = _20percent + _20percent;

			{
				uint256 _index = (epochIndex - 1) % 2;
				referralInfo[_index].reward = _20percent;
				allocReward += _20percent;
			}

			IERC20(rewardToken).safeTransferFrom(faucet, FURNACE, _expiredReward - _40percent);
			IERC20(rewardToken).safeTransferFrom(faucet, address(this), _20percent);

			IERC20(rewardToken).approve(farmingCompound, _10percent);
			FarmingCompound(farmingCompound).donateDrip(_10percent);

			IERC20(rewardToken).approve(farmingVolatile, _10percent);
			FarmingVolatile(farmingVolatile).donateDrip(_10percent);
		}
	}

	function _massUpdatePools(uint256 _when, bool _epochReset) internal
	{
		for (uint256 _pid = 0; _pid < poolInfo.length; _pid++) {
			_updatePool(_pid, _when, _epochReset);
		}
	}

	function _updatePool(uint256 _pid, uint256 _when, bool _epochReset) internal
	{
		PoolInfo storage _poolInfo = poolInfo[_pid];
		if (_when > _poolInfo.lastRewardTime) {
			if (_poolInfo.amount > 0 && _poolInfo.allocPoint > 0) {
				uint256 _reward = (_when - _poolInfo.lastRewardTime) * rewardPerSec * _poolInfo.allocPoint / totalAllocPoint;
				if (_reward > 0) {
					_poolInfo.accRewardPerShare += _reward * 1e18 / _poolInfo.amount;
					allocReward += _reward;
				}
			}
			if (_epochReset) {
				_poolInfo.epochAccRewardPerShare = _poolInfo.accRewardPerShare;
			}
			_poolInfo.lastRewardTime = _when;
		}
	}

	event Referral(address indexed _account, uint256 _epochIndex, uint256 _amount);
	event Deposit(address indexed _account, uint256 indexed _pid, uint256 _amount);
	event Withdraw(address indexed _account, uint256 indexed _pid, uint256 _amount);
	event EmergencyWithdraw(address indexed _account, uint256 indexed _pid, uint256 _amount);
	event ClaimReferral(address indexed _account, uint256 _amount);
	event ClaimReward(address indexed _account, uint256 _pid, uint256 _amount);
	event CompoundReferral(address indexed _account, uint256 indexed _pid0, uint256 _amount);
	event CompoundReward(address indexed _account, uint256 indexed _pid0, uint256 indexed _pid, uint256 _amount);
	event CompoundAll(address indexed _account, uint256 indexed _pid0, uint256 _amount);
}