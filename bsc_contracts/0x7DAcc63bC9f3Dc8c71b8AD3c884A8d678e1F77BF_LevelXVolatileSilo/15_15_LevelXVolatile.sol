// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.9;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Initializable } from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import { LevelXToken } from "./LevelXToken.sol";
import { LevelXCompound } from "./LevelXCompound.sol";

contract LevelXVolatileSilo
{
	address public immutable owner;

	constructor(address _token)
	{
		owner = msg.sender;
		replenish(_token);
	}

	function replenish(address _token) public
	{
		IERC20(_token).approve(owner, type(uint256).max);
	}
}

/*
 Volatile VDC fees are 33% in and 33% out, they are distributed in the following way:
 30% to drip pool
 1% Instant dividends to stakers
 2% LVLX Boosted Stakers (1% to xGRO Boosters, 1% to xPERPS Boosters)
 Receive 1% of all LVLX deposited into Compound VDC
 Drip pool pays 1% of its balance daily to stakers proportional to their amount staked
 There is a claim tax of 20% and 10% of that goes to bankroll and 10% to compounders drip pool.
 */
contract LevelXVolatile is Initializable, Ownable, ReentrancyGuard
{
	using SafeERC20 for IERC20;

	struct RewardInfo {
		uint256 totalReward;
		uint256 accRewardPerShare;
	}

	struct AccountInfo {
		uint256 amount; // LVLX staked
		uint256 burned1; // xGRO burned
		uint256 burned2; // xPERPS burned
		uint256 reward; // LVLX reward from Compound VDC accumulated but not claimed
		uint256 drip1; // LVLX from drip pool accumulated but not claimed
		uint256 drip2; // LVLX from compound drip pool accumulated but not claimed
		uint256 boost1; // LVLX from xGRO boost accumulated but not claimed
		uint256 boost2; // LVLX from xPERPS boost accumulated but not claimed
		uint256 accRewardDebt; // LVLX reward debt from PCS distribution algorithm
		uint256 accDripDebt1; // LVLX drip pool debt from PCS distribution algorithm
		uint256 accDripDebt2; // LVLX compound drip pool debt from PCS distribution algorithm
		uint256 accBoostDebt1; // LVLX reward debt of xGRO boost from PCS distribution algorithm
		uint256 accBoostDebt2; // LVLX reward debt of xPERPS boost from PCS distribution algorithm
		bool exists; // flag to index account
	}

	struct AccountRewardInfo {
		uint256 rewardDebt;
		uint256 unclaimedReward;
	}

	address constant FURNACE = 0x000000000000000000000000000000000000dEaD;

	address constant DEFAULT_BANKROLL = 0x392681Eaf8AD9BC65e74BE37Afe7503D92802b7d; // multisig

	uint256 constant DEFAULT_LAUNCH_TIME = 1676563200; // 2023-02-16 4PM UTC
	uint256 constant DEFAULT_DRIP_RATE_PER_DAY_1 = 1e16; // 1% per day
	uint256 constant DEFAULT_DRIP_RATE_PER_DAY_2 = 1e16; // 1% per day

	uint256 constant DAY = 1 days;
	uint256 constant TZ_OFFSET = 22 hours + 30 minutes; // UTC-1.30

	address payable public reserveToken; // LVLX
	address public rewardToken; // LVLX
	address public boostToken1; // xGRO
	address public boostToken2; // xPERPS

	address public stakingVolatile;
	address public partnerVolatile;

	address public bankroll = DEFAULT_BANKROLL;

	uint256 public launchTime = DEFAULT_LAUNCH_TIME;

	uint256 public dripRatePerDay1 = DEFAULT_DRIP_RATE_PER_DAY_1;
	uint256 public dripRatePerDay2 = DEFAULT_DRIP_RATE_PER_DAY_2;

	bool public whitelistAll = false;
	mapping(address => bool) public whitelist; // flag indicating whether or not account pays withdraw penalties

	uint256 public totalStaked = 0; // total LVLX staked balance
	uint256 public totalBurned1 = 0; // total xGRO burned balance
	uint256 public totalBurned2 = 0; // total xPERPS burned balance

	uint256 public totalDrip1 = 0; // total drip pool balance
	uint256 public allocDrip1 = 0; // total drip pool balance allocated

	uint256 public totalDrip2 = 0; // total compound drip pool balance
	uint256 public allocDrip2 = 0; // total compound drip pool balance allocated

	uint256 public totalReward = 0; // total LVLX reward balance

	uint256 public totalBoost1 = 0; // total xGRO boost balance
	uint256 public totalBoost2 = 0; // total xPERPS boost balance

	uint256 public accRewardPerShare = 0; // cumulative reward LVLX per LVLX staked from PCS distribution algorithm
	uint256 public accDripPerShare1 = 0; // cumulative drip pool LVLX per LVLX staked from PCS distribution algorithm
	uint256 public accDripPerShare2 = 0; // cumulative compound drip pool LVLX per LVLX staked from PCS distribution algorithm
	uint256 public accBoostPerShare1 = 0; // cumulative boost LVLX per xGRO burned from PCS distribution algorithm
	uint256 public accBoostPerShare2 = 0; // cumulative boost LVLX per xPERPS burned from PCS distribution algorithm

	uint64 public day = today();

	address[] public accountIndex;
	mapping(address => AccountInfo) public accountInfo;

	address public silo;
	uint256 public totalActiveBalance = 0;
	mapping(address => uint256) public activeBalance;
	mapping(address => RewardInfo) public rewardInfo;
	mapping(address => mapping(address => AccountRewardInfo)) public accountRewardInfo;

	function accountIndexLength() external view returns (uint256 _length)
	{
		return accountIndex.length;
	}

	function getAccountByIndex(uint256 _index) external view returns (AccountInfo memory _accountInfo)
	{
		return accountInfo[accountIndex[_index]];
	}

	function today() public view returns (uint64 _today)
	{
		return uint64((block.timestamp + TZ_OFFSET) / DAY);
	}

	modifier hasLaunched()
	{
		require(block.timestamp >= launchTime, "unavailable");
		_;
	}

	constructor(address payable _reserveToken, address _boostToken1, address _boostToken2, address _stakingVolatile, address _partnerVolatile)
	{
		initialize(msg.sender, _reserveToken, _boostToken1, _boostToken2, _stakingVolatile, _partnerVolatile);
	}

	function initialize(address _owner, address payable _reserveToken, address _boostToken1, address _boostToken2, address _stakingVolatile, address _partnerVolatile) public initializer
	{
		_transferOwnership(_owner);

		bankroll = DEFAULT_BANKROLL;

		launchTime = DEFAULT_LAUNCH_TIME;

		dripRatePerDay1 = DEFAULT_DRIP_RATE_PER_DAY_1;
		dripRatePerDay2 = DEFAULT_DRIP_RATE_PER_DAY_2;

		whitelistAll = false;

		totalStaked = 0; // total LVLX staked balance
		totalBurned1 = 0; // total xGRO burned balance
		totalBurned2 = 0; // total xPERPS burned balance

		totalDrip1 = 0; // total drip pool balance
		allocDrip1 = 0; // total drip pool balance allocated

		totalDrip2 = 0; // total compound drip pool balance
		allocDrip2 = 0; // total compound drip pool balance allocated

		totalReward = 0; // total LVLX reward balance

		totalBoost1 = 0; // total xGRO boost balance
		totalBoost2 = 0; // total xPERPS boost balance

		accRewardPerShare = 0; // cumulative reward LVLX per LVLX staked from PCS distribution algorithm
		accDripPerShare1 = 0; // cumulative drip pool LVLX per LVLX staked from PCS distribution algorithm
		accDripPerShare2 = 0; // cumulative compound drip pool LVLX per LVLX staked from PCS distribution algorithm
		accBoostPerShare1 = 0; // cumulative boost LVLX per xGRO burned from PCS distribution algorithm
		accBoostPerShare2 = 0; // cumulative boost LVLX per xPERPS burned from PCS distribution algorithm

		day = today();

		silo = address(new LevelXVolatileSilo(_reserveToken));
		totalActiveBalance = 0;

		require(_boostToken1 != _reserveToken, "invalid token");
		require(_boostToken2 != _reserveToken, "invalid token");
		require(_boostToken1 != _boostToken2, "invalid token");
		reserveToken = _reserveToken;
		rewardToken = _reserveToken;
		boostToken1 = _boostToken1;
		boostToken2 = _boostToken2;
		stakingVolatile = _stakingVolatile;
		partnerVolatile = _partnerVolatile;
	}

	// updates the bankroll address
	function setBankroll(address _bankroll) external onlyOwner
	{
		require(_bankroll != address(0), "invalid address");
		bankroll = _bankroll;
	}

	// updates the volatile vdc address
	function setStakingVolatile(address _stakingVolatile) external onlyOwner
	{
		require(_stakingVolatile != address(0), "invalid address");
		stakingVolatile = _stakingVolatile;
	}

	// updates the volatile vdc address
	function setPartnerVolatile(address _partnerVolatile) external onlyOwner
	{
		require(_partnerVolatile != address(0), "invalid address");
		partnerVolatile = _partnerVolatile;
	}

	// updates the launch time
	function setLaunchTime(uint256 _launchTime) external onlyOwner
	{
		require(block.timestamp < launchTime, "unavailable");
		require(_launchTime >= block.timestamp, "invalid time");
		launchTime = _launchTime;
	}

	// updates the percentual rate of distribution from the drip pool
	function setDripRatePerDay1(uint256 _dripRatePerDay1) external onlyOwner
	{
		require(_dripRatePerDay1 <= 100e16, "invalid rate");
		dripRatePerDay1 = _dripRatePerDay1;
	}

	// updates the percentual rate of distribution from the compound drip pool
	function setDripRatePerDay2(uint256 _dripRatePerDay2) external onlyOwner
	{
		require(_dripRatePerDay2 <= 100e16, "invalid rate");
		dripRatePerDay2 = _dripRatePerDay2;
	}

	// flags all accounts for withdrawing without penalty (useful for migration)
	function updateWhitelistAll(bool _whitelistAll) external onlyOwner
	{
		whitelistAll = _whitelistAll;
	}

	// flags multiple accounts for withdrawing without penalty
	function updateWhitelist(address[] calldata _accounts, bool _whitelisted) external onlyOwner
	{
		for (uint256 _i; _i < _accounts.length; _i++) {
			whitelist[_accounts[_i]] = _whitelisted;
		}
	}

	function bumpLevel() external nonReentrant
	{
		uint256 _level = LevelXToken(reserveToken).computeLevelOf(address(this));
		uint256 _totalShares = LevelXToken(reserveToken).computeTotalShares();
		uint256 _totalActiveSupply = LevelXToken(reserveToken).computeTotalActiveSupply();
		uint256 _averageLevel = _totalShares * 1e18 / _totalActiveSupply;
		require(_level < _averageLevel, "not available");
		uint256 _amount = LevelXToken(reserveToken).burnAmountToBumpLevel();
		IERC20(reserveToken).safeTransferFrom(msg.sender, address(this), _amount);
		LevelXToken(reserveToken).bumpLevel();
		uint256 _newLevel = LevelXToken(reserveToken).computeLevelOf(address(this));
		emit BumpLevel(msg.sender, _amount, _newLevel - _level);
	}

	// burns xGRO
	function burn1(uint256 _amount) external
	{
		burnOnBehalfOf1(_amount, msg.sender);
	}

	// burns xGRO on behalf of another account
	function burnOnBehalfOf1(uint256 _amount, address _account) public hasLaunched nonReentrant
	{
		require(_amount > 0, "invalid amount");

		_updateDay();

		_updateAccount(_account, 0, _amount, 0);

		totalBurned1 += _amount;

		IERC20(boostToken1).safeTransferFrom(msg.sender, FURNACE, _amount);

		_distributeBalance();

		emit Burn(_account, boostToken1, _amount);
	}

	// burns xPERPS
	function burn2(uint256 _amount) external
	{
		burnOnBehalfOf2(_amount, msg.sender);
	}

	// burns xPERPS on behalf of another account
	function burnOnBehalfOf2(uint256 _amount, address _account) public hasLaunched nonReentrant
	{
		require(_amount > 0, "invalid amount");

		_updateDay();

		_updateAccount(_account, 0, 0, _amount);

		totalBurned2 += _amount;

		IERC20(boostToken2).safeTransferFrom(msg.sender, FURNACE, _amount);

		_distributeBalance();

		emit Burn(_account, boostToken2, _amount);
	}

	// stakes LVLX
	function deposit(uint256 _amount) external
	{
		depositOnBehalfOf(_amount, msg.sender);
	}

	// stakes LVLX on behalf of another account
	function depositOnBehalfOf(uint256 _amount, address _account) public hasLaunched nonReentrant
	{
		_updateDay();

		_deposit(msg.sender, _amount, _account);

		_distributeBalance();

		emit Deposit(_account, reserveToken, _amount);
	}

	function _deposit(address _sender, uint256 _amount, address _account) internal
	{
		require(_amount > 0, "invalid amount");

		uint256 _1percent = _amount * 1e16 / 100e16;
		uint256 _dripAmount = 31 * _1percent;
		uint256 _netAmount = _amount - (33 * _1percent);

		// 31% accounted for the drip pool
		totalDrip1 += _dripAmount;

		// 1% instant rewards (only 30% actually go to the drip pool)
		if (totalStaked > 0) {
			accDripPerShare1 += _1percent * 1e36 / totalStaked;
			allocDrip1 += _1percent;
		}

		// rewards users for xGRO burned
		if (totalBurned1 > 0) {
			accBoostPerShare1 += _1percent * 1e36 / totalBurned1;
			totalBoost1 += _1percent;
		}

		// rewards users for xPERPS burned
		if (totalBurned2 > 0) {
			accBoostPerShare2 += _1percent * 1e36 / totalBurned2;
			totalBoost2 += _1percent;
		}

		_updateAccount(_account, int256(_netAmount), 0, 0);

		totalStaked += _netAmount;

		if (_sender != address(this)) {
			IERC20(reserveToken).safeTransferFrom(_sender, address(this), _amount);
		}
	}

	// unstakes LVLX
	function withdraw(uint256 _amount) external nonReentrant
	{
		require(_amount > 0, "invalid amount");

		AccountInfo storage _accountInfo = accountInfo[msg.sender];
		require(_amount <= _accountInfo.amount, "insufficient balance");

		_updateDay();

		_updateAccount(msg.sender, -int256(_amount), 0, 0);

		totalStaked -= _amount;

		if (whitelist[msg.sender] || whitelistAll) {
			_ensureBalance(_amount);

			IERC20(reserveToken).safeTransfer(msg.sender, _amount);
		} else {
			uint256 _1percent = _amount * 1e16 / 100e16;
			uint256 _dripAmount = 31 * _1percent;
			uint256 _netAmount = _amount - (33 * _1percent);

			// 31% accounted for the drip pool
			totalDrip1 += _dripAmount;

			// 1% instant rewards (only 30% actually go to the drip pool)
			if (totalStaked > 0) {
				accDripPerShare1 += _1percent * 1e36 / totalStaked;
				allocDrip1 += _1percent;
			}

			// rewards users for xGRO burned
			if (totalBurned1 > 0) {
				accBoostPerShare1 += _1percent * 1e36 / totalBurned1;
				totalBoost1 += _1percent;
			}

			// rewards users for xPERPS burned
			if (totalBurned2 > 0) {
				accBoostPerShare2 += _1percent * 1e36 / totalBurned2;
				totalBoost2 += _1percent;
			}

			_ensureBalance(_netAmount);

			IERC20(reserveToken).safeTransfer(msg.sender, _netAmount);
		}

		_distributeBalance();

		emit Withdraw(msg.sender, reserveToken, _amount);
	}

	// claims all (LVLX, xGRO, EMP)
	function claimAll() external nonReentrant returns (uint256[] memory _rewardAmounts)
	{
		_updateDay();

		_updateAccount(msg.sender, 0, 0, 0);

		{
			uint256 _length = LevelXToken(reserveToken).rewardIndexLength();
			_rewardAmounts = new uint256[](_length);
			for (uint256 _i = 0; _i < _length; _i++) {
				_rewardAmounts[_i] = _claim(msg.sender, _i);
			}
		}

		{
			(uint256 _rewardAmount, uint256 _dripAmount1, uint256 _boostAmount1, uint256 _boostAmount2) = _claim(msg.sender);
			_rewardAmounts[0] += _rewardAmount + _dripAmount1 + _boostAmount1 + _boostAmount2;
		}

		_distributeBalance();

		return _rewardAmounts;
	}

	// claims a single reward (LVLX, xGRO, EMP)
	function claim(uint256 _i) external nonReentrant returns (uint256 _rewardAmount)
	{
		require(_i < LevelXToken(reserveToken).rewardIndexLength(), "invalid index");

		_updateDay();

		_updateAccount(msg.sender, 0, 0, 0);

		_rewardAmount = _claim(msg.sender, _i);

		if (_i == 0) {
			(uint256 _rewardAmount0, uint256 _dripAmount1, uint256 _boostAmount1, uint256 _boostAmount2) = _claim(msg.sender);
			_rewardAmount += _rewardAmount0 + _dripAmount1 + _boostAmount1 + _boostAmount2;
		}

		_distributeBalance();

		return _rewardAmount;
	}

	// compounds all (LVLX, xGRO, EMP)
	function compoundAll() external nonReentrant returns (uint256[] memory _rewardAmounts)
	{
		_updateDay();

		_updateAccount(msg.sender, 0, 0, 0);

		{
			uint256 _length = LevelXToken(reserveToken).rewardIndexLength();
			_rewardAmounts = new uint256[](_length);
			for (uint256 _i = 0; _i < _length; _i++) {
				_rewardAmounts[_i] = _compound(msg.sender, _i);
			}
		}

		{
			(uint256 _rewardAmount, uint256 _dripAmount1, uint256 _dripAmount2, uint256 _boostAmount1, uint256 _boostAmount2) = _compound(msg.sender);
			_rewardAmounts[0] += _rewardAmount + _dripAmount1 + _dripAmount2 + _boostAmount1 + _boostAmount2;
		}

		_distributeBalance();

		return _rewardAmounts;
	}

	// compound a single reward (LVLX, xGRO, EMP)
	function compound(uint256 _i) external nonReentrant returns (uint256 _rewardAmount)
	{
		require(_i < LevelXToken(reserveToken).rewardIndexLength(), "invalid index");

		_updateDay();

		_updateAccount(msg.sender, 0, 0, 0);

		_rewardAmount = _compound(msg.sender, _i);

		if (_i == 0) {
			(uint256 _rewardAmount0, uint256 _dripAmount1, uint256 _dripAmount2, uint256 _boostAmount1, uint256 _boostAmount2) = _compound(msg.sender);
			_rewardAmount += _rewardAmount0 + _dripAmount1 + _dripAmount2 + _boostAmount1 + _boostAmount2;
		}

		_distributeBalance();

		return _rewardAmount;
	}

	function _claim(address _account) internal returns (uint256 _rewardAmount, uint256 _dripAmount1, uint256 _boostAmount1, uint256 _boostAmount2)
	{
		AccountInfo storage _accountInfo = accountInfo[_account];

		_rewardAmount = _accountInfo.reward;
		_dripAmount1 = _accountInfo.drip1;
		uint256 _dripAmount2 = _accountInfo.drip2;
		_boostAmount1 = _accountInfo.boost1;
		_boostAmount2 = _accountInfo.boost2;

		if (_rewardAmount > 0) {
			_accountInfo.reward = 0;

			totalReward -= _rewardAmount;
		}

		if (_dripAmount1 > 0) {
			_accountInfo.drip1 = 0;

			totalDrip1 -= _dripAmount1;
			allocDrip1 -= _dripAmount1;
		}

		if (_dripAmount2 > 0) {
			_accountInfo.drip2 = 0;

			totalDrip2 -= _dripAmount2;
			allocDrip2 -= _dripAmount2;
		}

		if (_boostAmount1 > 0) {
			_accountInfo.boost1 = 0;

			totalBoost1 -= _boostAmount1;
		}

		if (_boostAmount2 > 0) {
			_accountInfo.boost2 = 0;

			totalBoost2 -= _boostAmount2;
		}

		if (_dripAmount2 > 0) {
			uint256 _halfAmount = _dripAmount2 / 2;
			totalDrip1 += _halfAmount;
			totalDrip2 += _halfAmount;
		}

		uint256 _amount = _rewardAmount + _dripAmount1 + _boostAmount1 + _boostAmount2;
		if (_amount > 0) {
			uint256 _feeAmount = _amount * 10e16 / 100e16;
			uint256 _netAmount = _amount - 2 * _feeAmount;
			totalDrip2 += _feeAmount;
			IERC20(reserveToken).safeTransferFrom(silo, bankroll, _feeAmount);
			IERC20(reserveToken).safeTransferFrom(silo, _account, _netAmount);
		}

		emit Claim(_account, reserveToken, _amount);

		return (_rewardAmount, _dripAmount1, _boostAmount1, _boostAmount2);
	}

	function _claim(address _account, uint256 _i) internal returns (uint256 _rewardAmount)
	{
		address _rewardToken = LevelXToken(reserveToken).rewardIndex(_i);
		AccountRewardInfo storage _accountRewardInfo = accountRewardInfo[_account][_rewardToken];
		_rewardAmount = _accountRewardInfo.unclaimedReward;
		if (_rewardAmount > 0) {
			_accountRewardInfo.unclaimedReward = 0;
			rewardInfo[_rewardToken].totalReward -= _rewardAmount;
			uint256 _feeAmount = _rewardAmount * 10e16 / 100e16;
			uint256 _netAmount = _rewardAmount - 2 * _feeAmount;
			if (_i == 0) {
				if (_feeAmount > 0) {
					totalDrip2 += _feeAmount;
					IERC20(_rewardToken).safeTransferFrom(silo, bankroll, _feeAmount);
				}
				IERC20(_rewardToken).safeTransferFrom(silo, _account, _netAmount);
			} else {
				if (_feeAmount > 0) {
					IERC20(_rewardToken).safeTransfer(bankroll, 2 * _feeAmount);
				}
				IERC20(_rewardToken).safeTransfer(_account, _netAmount);
			}
		}
		emit Claim(_account, _rewardToken, _rewardAmount);
		return _rewardAmount;
	}

	function _compound(address _account) internal returns (uint256 _rewardAmount, uint256 _dripAmount1, uint256 _dripAmount2, uint256 _boostAmount1, uint256 _boostAmount2)
	{
		AccountInfo storage _accountInfo = accountInfo[_account];

		_rewardAmount = _accountInfo.reward;
		_dripAmount1 = _accountInfo.drip1;
		_dripAmount2 = _accountInfo.drip2;
		_boostAmount1 = _accountInfo.boost1;
		_boostAmount2 = _accountInfo.boost2;

		if (_rewardAmount > 0) {
			_accountInfo.reward = 0;

			totalReward -= _rewardAmount;
		}

		if (_dripAmount1 > 0) {
			_accountInfo.drip1 = 0;

			totalDrip1 -= _dripAmount1;
			allocDrip1 -= _dripAmount1;
		}

		if (_dripAmount2 > 0) {
			_accountInfo.drip2 = 0;

			totalDrip2 -= _dripAmount2;
			allocDrip2 -= _dripAmount2;
		}

		if (_boostAmount1 > 0) {
			_accountInfo.boost1 = 0;

			totalBoost1 -= _boostAmount1;
		}

		if (_boostAmount2 > 0) {
			_accountInfo.boost2 = 0;

			totalBoost2 -= _boostAmount2;
		}

		uint256 _amount = _rewardAmount + _dripAmount1 + _dripAmount2 + _boostAmount1 + _boostAmount2;
		if (_amount > 0) {
			_deposit(address(this), _amount, _account);
		}

		emit Compound(_account, reserveToken, _amount);

		return (_rewardAmount, _dripAmount1, _dripAmount2, _boostAmount1, _boostAmount2);
	}

	function _compound(address _account, uint256 _i) internal returns (uint256 _rewardAmount)
	{
		address _rewardToken = LevelXToken(reserveToken).rewardIndex(_i);
		AccountRewardInfo storage _accountRewardInfo = accountRewardInfo[_account][_rewardToken];
		_rewardAmount = _accountRewardInfo.unclaimedReward;
		if (_rewardAmount > 0) {
			_accountRewardInfo.unclaimedReward = 0;
			rewardInfo[_rewardToken].totalReward -= _rewardAmount;
			if (_i == 0) {
				_deposit(address(this), _rewardAmount, _account);
			}
			else
			if (_i == 1) {
				IERC20(_rewardToken).safeApprove(stakingVolatile, _rewardAmount);
				LevelXVolatile(stakingVolatile).depositOnBehalfOf(_rewardAmount, _account);
			}
			else
			if (_i == 2) {
				IERC20(_rewardToken).safeApprove(partnerVolatile, _rewardAmount);
				LevelXVolatile(partnerVolatile).depositOnBehalfOf(_rewardAmount, _account);
			}
			else {
				revert("invalid index");
			}
		}
		emit Compound(_account, _rewardToken, _rewardAmount);
		return _rewardAmount;
	}

	// sends LVLX to a set of accounts
	function reward(address[] calldata _accounts, uint256[] calldata _amounts) external nonReentrant
	{
		require(_accounts.length == _amounts.length, "lenght mismatch");

		_updateDay();

		uint256 _amount = 0;

		for (uint256 _i = 0; _i < _accounts.length; _i++) {
			address _account = _accounts[_i];
			AccountInfo storage _accountInfo = accountInfo[_account];

			_accountInfo.reward += _amounts[_i];

			emit Reward(_account, rewardToken, _amounts[_i]);

			_amount += _amounts[_i];
		}

		if (_amount > 0) {
			totalReward += _amount;

			IERC20(rewardToken).safeTransferFrom(msg.sender, silo, _amount);
		}

		_distributeBalance();
	}

	// sends LVLX to all stakers
	function rewardAll(uint256 _amount) external nonReentrant
	{
		require(_amount > 0, "invalid amount");

		if (totalStaked == 0) {
			IERC20(rewardToken).safeTransferFrom(msg.sender, silo, _amount);
			return;
		}

		_updateDay();

		accRewardPerShare += _amount * 1e36 / totalStaked;

		totalReward += _amount;

		IERC20(rewardToken).safeTransferFrom(msg.sender, silo, _amount);

		_distributeBalance();

		emit RewardAll(msg.sender, rewardToken, _amount);
	}

	// sends LVLX to the drip pool
	function donateDrip1(uint256 _amount) external nonReentrant
	{
		require(_amount > 0, "invalid amount");

		_updateDay();

		totalDrip1 += _amount;

		IERC20(reserveToken).safeTransferFrom(msg.sender, address(this), _amount);

		_distributeBalance();

		emit DonateDrip1(msg.sender, reserveToken, _amount);
	}

	// sends LVLX to the compound drip pool
	function donateDrip2(uint256 _amount) external nonReentrant
	{
		require(_amount > 0, "invalid amount");

		_updateDay();

		totalDrip2 += _amount;

		IERC20(reserveToken).safeTransferFrom(msg.sender, address(this), _amount);

		_distributeBalance();

		emit DonateDrip2(msg.sender, reserveToken, _amount);
	}

	// claims any pending rewards
	function claimRewards() external nonReentrant
	{
		_updateDay();

		_claimRewards();

		_distributeBalance();
	}

	// performs the daily distribution from the drip pool (LVLX)
	function updateDay() external nonReentrant
	{
		_updateDay();

		_distributeBalance();
	}

	function _updateDay() internal
	{
		uint64 _today = today();

		if (day == _today) return;

		_claimRewards();

		_distributeBalance();

		uint256 _ratePerDay1 = dripRatePerDay1;
		if (_ratePerDay1 > 0) {
			// calculates the percentage of the drip pool and distributes
			{
				// formula: drip_reward = drip_pool_balance * (1 - (1 - drip_rate_per_day) ^ days_ellapsed)
				uint64 _days = _today - day;
				uint256 _rate = 100e16 - _exp(100e16 - _ratePerDay1, _days);
				uint256 _amount = (totalDrip1 - allocDrip1) * _rate / 100e16;

				if (totalStaked > 0) {
					accDripPerShare1 += _amount * 1e36 / totalStaked;
					allocDrip1 += _amount;
				}

				emit Drip1(reserveToken, _amount);
			}
		}

		uint256 _ratePerDay2 = dripRatePerDay2;
		if (_ratePerDay2 > 0) {
			// calculates the percentage of the compound drip pool and distributes
			{
				// formula: drip_reward = drip_pool_balance * (1 - (1 - drip_rate_per_day) ^ days_ellapsed)
				uint64 _days = _today - day;
				uint256 _rate = 100e16 - _exp(100e16 - _ratePerDay2, _days);
				uint256 _amount = (totalDrip2 - allocDrip2) * _rate / 100e16;

				if (totalStaked > 0) {
					accDripPerShare2 += _amount * 1e36 / totalStaked;
					allocDrip2 += _amount;
				}

				emit Drip2(reserveToken, _amount);
			}
		}

		day = _today;
	}

	// updates the account balances while accumulating reward/drip/boost using PCS distribution algorithm
	function _updateAccount(address _account, int256 _amount, uint256 _burned1, uint256 _burned2) internal
	{
		AccountInfo storage _accountInfo = accountInfo[_account];
		if (!_accountInfo.exists) {
			// adds account to index
			_accountInfo.exists = true;
			accountIndex.push(_account);
		}

		_accountInfo.reward += _accountInfo.amount * accRewardPerShare / 1e36 - _accountInfo.accRewardDebt;
		_accountInfo.drip1 += _accountInfo.amount * accDripPerShare1 / 1e36 - _accountInfo.accDripDebt1;
		_accountInfo.drip2 += _accountInfo.amount * accDripPerShare2 / 1e36 - _accountInfo.accDripDebt2;
		_accountInfo.boost1 += _accountInfo.burned1 * accBoostPerShare1 / 1e36 - _accountInfo.accBoostDebt1;
		_accountInfo.boost2 += _accountInfo.burned2 * accBoostPerShare2 / 1e36 - _accountInfo.accBoostDebt2;

		uint256 _oldActiveBalance = activeBalance[_account];
		if (_oldActiveBalance > 0) {
			uint256 _length = LevelXToken(reserveToken).rewardIndexLength();
			for (uint256 _i = 0; _i < _length; _i++) {
				address _rewardToken = LevelXToken(reserveToken).rewardIndex(_i);
				RewardInfo storage _rewardInfo = rewardInfo[_rewardToken];
				AccountRewardInfo storage _accountRewardInfo = accountRewardInfo[_account][_rewardToken];
				_accountRewardInfo.unclaimedReward +=_oldActiveBalance * _rewardInfo.accRewardPerShare / 1e36 - _accountRewardInfo.rewardDebt;
			}
		}

		if (_amount > 0) {
			_accountInfo.amount += uint256(_amount);
		}
		else
		if (_amount < 0) {
			_accountInfo.amount -= uint256(-_amount);
		}
		_accountInfo.burned1 += _burned1;
		_accountInfo.burned2 += _burned2;

		uint256 _newActiveBalance =  _accountInfo.amount >= LevelXToken(reserveToken).minimumBalanceForRewards() ? _accountInfo.amount : 0;
		activeBalance[_account] = _newActiveBalance;
		totalActiveBalance -= _oldActiveBalance;
		totalActiveBalance += _newActiveBalance;

		_accountInfo.accRewardDebt = _accountInfo.amount * accRewardPerShare / 1e36;
		_accountInfo.accDripDebt1 = _accountInfo.amount * accDripPerShare1 / 1e36;
		_accountInfo.accDripDebt2 = _accountInfo.amount * accDripPerShare2 / 1e36;
		_accountInfo.accBoostDebt1 = _accountInfo.burned1 * accBoostPerShare1 / 1e36;
		_accountInfo.accBoostDebt2 = _accountInfo.burned2 * accBoostPerShare2 / 1e36;

		{
			uint256 _length = LevelXToken(reserveToken).rewardIndexLength();
			for (uint256 _i = 0; _i < _length; _i++) {
				address _rewardToken = LevelXToken(reserveToken).rewardIndex(_i);
				RewardInfo storage _rewardInfo = rewardInfo[_rewardToken];
				AccountRewardInfo storage _accountRewardInfo = accountRewardInfo[_account][_rewardToken];
				_accountRewardInfo.rewardDebt = _newActiveBalance * _rewardInfo.accRewardPerShare / 1e36;
			}
		}
	}

	function _ensureBalance(uint256 _amount) internal
	{
		uint256 _balance = LevelXToken(reserveToken).computeBalanceOf(address(this));
		if (_balance < _amount) {
			IERC20(reserveToken).safeTransferFrom(silo, address(this), _amount - _balance);
		}
	}

	function _distributeBalance() internal
	{
		uint256 _activeAmount = totalActiveBalance + (totalDrip1 - allocDrip1) + (totalDrip2 - allocDrip2);
		uint256 _balance = LevelXToken(reserveToken).computeBalanceOf(address(this));
		if (_balance > _activeAmount) {
			IERC20(reserveToken).safeTransfer(silo, _balance - _activeAmount);
		}
		else
		if (_balance < _activeAmount) {
			IERC20(reserveToken).safeTransferFrom(silo, address(this), _activeAmount - _balance);
		}
	}

	function _claimRewards() internal
	{
		if (totalActiveBalance > 0) {
			{
				LevelXToken(reserveToken).claim(0);
				uint256 _balance = LevelXToken(reserveToken).computeBalanceOf(address(this)) + LevelXToken(reserveToken).computeBalanceOf(silo);
				RewardInfo storage _rewardInfo = rewardInfo[reserveToken];
				uint256 _amount = totalStaked + totalDrip1 + totalDrip2 + totalReward + totalBoost1 + totalBoost2 + _rewardInfo.totalReward;
				if (_balance > _amount) {
					uint256 _rewardAmount = _balance - _amount;
					uint256 _activeAmount = totalActiveBalance + (totalDrip1 - allocDrip1) + (totalDrip2 - allocDrip2);
					totalDrip1 += _rewardAmount * (totalDrip1 - allocDrip1) / _activeAmount;
					totalDrip2 += _rewardAmount * (totalDrip2 - allocDrip2) / _activeAmount;
					_rewardAmount = _rewardAmount * totalActiveBalance / _activeAmount;
					_rewardInfo.totalReward += _rewardAmount;
					_rewardInfo.accRewardPerShare += _rewardAmount * 1e36 / totalActiveBalance;
				}
			}
			uint256 _length = LevelXToken(reserveToken).rewardIndexLength();
			for (uint256 _i = 1; _i < _length; _i++) {
				LevelXToken(reserveToken).claim(_i);
				address _rewardToken = LevelXToken(reserveToken).rewardIndex(_i);
				RewardInfo storage _rewardInfo = rewardInfo[_rewardToken];
				uint256 _rewardBalance = IERC20(_rewardToken).balanceOf(address(this));
				uint256 _rewardAmount = _rewardBalance - _rewardInfo.totalReward;
				if (_rewardAmount > 0) {
					_rewardInfo.totalReward = _rewardBalance;
					_rewardInfo.accRewardPerShare += _rewardAmount * 1e36 / totalActiveBalance;
				}
			}
		}
	}

	// exponentiation with integer exponent
	function _exp(uint256 _x, uint256 _n) internal pure returns (uint256 _y)
	{
		_y = 1e18;
		while (_n > 0) {
			if (_n & 1 != 0) _y = _y * _x / 1e18;
			_n >>= 1;
			_x = _x * _x / 1e18;
		}
		return _y;
	}

	event BumpLevel(address indexed _account, uint256 _amount, uint256 _levelBump);
	event Burn(address indexed _account, address indexed _boostToken, uint256 _amount);
	event Deposit(address indexed _account, address indexed _reserveToken, uint256 _amount);
	event Withdraw(address indexed _account, address indexed _reserveToken, uint256 _amount);
	event Claim(address indexed _account, address indexed _reserveOrRewardToken, uint256 _amount);
	event Compound(address indexed _account, address indexed _reserveOrRewardToken, uint256 _amount);
	event Reward(address indexed _account, address indexed _rewardToken, uint256 _amount);
	event RewardAll(address indexed _account, address indexed _rewardToken, uint256 _amount);
	event DonateDrip1(address indexed _account, address indexed _reserveToken, uint256 _amount);
	event DonateDrip2(address indexed _account, address indexed _reserveToken, uint256 _amount);
	event Drip1(address indexed _reserveToken, uint256 _dripAmount1);
	event Drip2(address indexed _reserveToken, uint256 _dripAmount2);
}