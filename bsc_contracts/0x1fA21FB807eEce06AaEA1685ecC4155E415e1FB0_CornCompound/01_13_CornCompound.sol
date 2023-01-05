// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.9;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Initializable } from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import { CornVolatile } from "./CornVolatile.sol";
import { PartnerCompound } from "./PartnerCompound.sol";
import { IClaimable } from "./IClaimable.sol";

/*
 Compound VDC fees are 11% in and 11% out, they are distributed in the following way:
 7% to drip pool
 1% Instant dividends to stakers
 1% BITCORN to xPERPS stakers
 1% Rehypothication
 1% Volatile VDC
 Receives incentives daily from BITCORN staking
 Drip pool pays 1% of its balance daily to stakers proportional to their amount staked
 Drip pool pays an extra 0.5% of its balance daily to stakers with Boosts, proportional to their xPERPS Boost position
 There is a claim tax of 20% and 10% of that goes to bankroll and 10% to compounders drip pool.
 */
contract CornCompound is Initializable, Ownable, ReentrancyGuard
{
	using SafeERC20 for IERC20;

	struct AccountInfo {
		uint256 amount; // BITCORN staked
		uint256 burned; // xPERPS burned
		uint256 reward; // ESHARE reward accumulated but not claimed
		uint256 drip1; // BITCORN from drip pool accumulated but not claimed
		uint256 drip2; // BITCORN from compound drip pool accumulated but not claimed
		uint256 boost; // BITCORN from boost accumulated but not claimed
		uint256 accRewardDebt; // BITCORN reward debt from PCS distribution algorithm
		uint256 accDripDebt1; // BITCORN drip pool debt from PCS distribution algorithm
		uint256 accDripDebt2; // BITCORN compound drip pool debt from PCS distribution algorithm
		uint256 accBoostDebt; // BITCORN reward debt from PCS distribution algorithm
		bool whitelisted; // flag indicating whether or not account pays withdraw penalties
		bool exists; // flag to index account
		uint256 reserved0;
		uint256 reserved1;
	}

	address constant FURNACE = 0x000000000000000000000000000000000000dEaD;

	address constant DEFAULT_BANKROLL = 0x392681Eaf8AD9BC65e74BE37Afe7503D92802b7d; // multisig
	address constant DEFAULT_REHYPOTHECATOR = 0x2165fa4a32B9c228cD55713f77d2e977297D03e8; // ghost

	uint256 constant DEFAULT_LAUNCH_TIME = 1672941600; // 2023-01-05 6PM UTC
	uint256 constant DEFAULT_DRIP_RATE_PER_DAY_1 = 1e16; // 1% per day
	uint256 constant DEFAULT_DRIP_RATE_PER_DAY_2 = 1e16; // 1% per day
	uint256 constant DEFAULT_DRIP_BOOST_RATE_PER_DAY_1 = 0.5e16; // 0.5% per day
	uint256 constant DEFAULT_DRIP_BOOST_RATE_PER_DAY_2 = 0e16; // 0% per day

	uint256 constant DAY = 1 days;
	uint256 constant TZ_OFFSET = 22 hours + 30 minutes; // UTC-1.30

	address public reserveToken; // BITCORN
	address public rewardToken; // ESHARE
	address public boostToken; // xPERPS

	address public cornVolatile;
	address public partnerCompound;

	address public bankroll = DEFAULT_BANKROLL;
	address public rehypothecator = DEFAULT_REHYPOTHECATOR;

	uint256 public launchTime = DEFAULT_LAUNCH_TIME;

	uint256 public dripRatePerDay1 = DEFAULT_DRIP_RATE_PER_DAY_1;
	uint256 public dripRatePerDay2 = DEFAULT_DRIP_RATE_PER_DAY_2;
	uint256 public dripBoostRatePerDay1 = DEFAULT_DRIP_BOOST_RATE_PER_DAY_1;
	uint256 public dripBoostRatePerDay2 = DEFAULT_DRIP_BOOST_RATE_PER_DAY_2;

	bool public whitelistAll = false;

	uint256 public totalStaked = 0; // total staked balance
	uint256 public totalBurned = 0; // total burned balance

	uint256 public totalDrip1 = 0; // total drip pool balance
	uint256 public allocDrip1 = 0; // total drip pool balance allocated

	uint256 public totalDrip2 = 0; // total compound drip pool balance
	uint256 public allocDrip2 = 0; // total compound drip pool balance allocated

	uint256 public totalReward = 0; // total reward balance

	uint256 public totalBoost = 0; // total boost balance

	uint256 public accRewardPerShare = 0; // cumulative reward BITCORN per BITCORN staked from PCS distribution algorithm
	uint256 public accDripPerShare1 = 0; // cumulative drip pool BITCORN per BITCORN staked from PCS distribution algorithm
	uint256 public accDripPerShare2 = 0; // cumulative compound drip pool BITCORN per BITCORN staked from PCS distribution algorithm
	uint256 public accBoostPerShare = 0; // cumulative boost BITCORN per xPERPS burned from PCS distribution algorithm

	uint64 public day = today();

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

	function today() public view returns (uint64 _today)
	{
		return uint64((block.timestamp + TZ_OFFSET) / DAY);
	}

	modifier hasLaunched()
	{
		require(block.timestamp >= launchTime, "unavailable");
		_;
	}

	constructor(address _reserveToken, address _rewardToken, address _boostToken, address _cornVolatile, address _partnerCompound)
	{
		initialize(msg.sender, _reserveToken, _rewardToken, _boostToken, _cornVolatile, _partnerCompound);
	}

	function initialize(address _owner, address _reserveToken, address _rewardToken, address _boostToken, address _cornVolatile, address _partnerCompound) public initializer
	{
		_transferOwnership(_owner);

		bankroll = DEFAULT_BANKROLL;
		rehypothecator = DEFAULT_REHYPOTHECATOR;

		launchTime = DEFAULT_LAUNCH_TIME;

		dripRatePerDay1 = DEFAULT_DRIP_RATE_PER_DAY_1;
		dripRatePerDay2 = DEFAULT_DRIP_RATE_PER_DAY_2;
		dripBoostRatePerDay1 = DEFAULT_DRIP_BOOST_RATE_PER_DAY_1;
		dripBoostRatePerDay2 = DEFAULT_DRIP_BOOST_RATE_PER_DAY_2;

		whitelistAll = false;

		totalStaked = 0; // total staked balance
		totalBurned = 0; // total burned balance

		totalDrip1 = 0; // total drip pool balance
		allocDrip1 = 0; // total drip pool balance allocated

		totalDrip2 = 0; // total compound drip pool balance
		allocDrip2 = 0; // total compound drip pool balance allocated

		totalReward = 0; // total reward balance

		totalBoost = 0; // total boost balance

		accRewardPerShare = 0; // cumulative reward BITCORN per BITCORN staked from PCS distribution algorithm
		accDripPerShare1 = 0; // cumulative drip pool BITCORN per BITCORN staked from PCS distribution algorithm
		accDripPerShare2 = 0; // cumulative compound drip pool BITCORN per BITCORN staked from PCS distribution algorithm
		accBoostPerShare = 0; // cumulative boost BITCORN per xPERPS burned from PCS distribution algorithm

		day = today();

		require(_rewardToken != _reserveToken, "invalid token");
		require(_boostToken != _reserveToken, "invalid token");
		require(_boostToken != _rewardToken, "invalid token");
		reserveToken = _reserveToken;
		rewardToken = _rewardToken;
		boostToken = _boostToken;
		cornVolatile = _cornVolatile;
		partnerCompound = _partnerCompound;
	}

	// updates the bankroll address
	function setBankroll(address _bankroll) external onlyOwner
	{
		require(_bankroll != address(0), "invalid address");
		bankroll = _bankroll;
	}

	// updates the bankroll address
	function setRehypothecator(address _rehypothecator) external onlyOwner
	{
		require(_rehypothecator != address(0), "invalid address");
		rehypothecator = _rehypothecator;
	}

	// updates the volatile vdc address
	function setCornVolatile(address _cornVolatile) external onlyOwner
	{
		require(_cornVolatile != address(0), "invalid address");
		cornVolatile = _cornVolatile;
	}

	// updates the compound vdc address
	function setPartnerCompound(address _partnerCompound) external onlyOwner
	{
		require(_partnerCompound != address(0), "invalid address");
		partnerCompound = _partnerCompound;
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
		require(_dripRatePerDay1 + dripBoostRatePerDay1 <= 100e16, "invalid rate");
		dripRatePerDay1 = _dripRatePerDay1;
	}

	// updates the percentual rate of distribution from the compound drip pool
	function setDripRatePerDay2(uint256 _dripRatePerDay2) external onlyOwner
	{
		require(_dripRatePerDay2 + dripBoostRatePerDay2 <= 100e16, "invalid rate");
		dripRatePerDay2 = _dripRatePerDay2;
	}

	// updates the percentual rate of distribution from the drip pool
	function setDripBoostRatePerDay1(uint256 _dripBoostRatePerDay1) external onlyOwner
	{
		require(dripRatePerDay1 + _dripBoostRatePerDay1 <= 100e16, "invalid rate");
		dripBoostRatePerDay1 = _dripBoostRatePerDay1;
	}

	// updates the percentual rate of distribution from the drip pool
	function setDripBoostRatePerDay2(uint256 _dripBoostRatePerDay2) external onlyOwner
	{
		require(dripRatePerDay2 + _dripBoostRatePerDay2 <= 100e16, "invalid rate");
		dripBoostRatePerDay2 = _dripBoostRatePerDay2;
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
			accountInfo[_accounts[_i]].whitelisted = _whitelisted;
		}
	}

	// this is a safety net method for recovering funds that are not being used
	function recoverFunds(address _token) external onlyOwner nonReentrant
	{
		uint256 _amount = IERC20(_token).balanceOf(address(this));
		if (_token == reserveToken) _amount -= totalStaked + totalDrip1 + totalDrip2 + totalBoost;
		else
		if (_token == rewardToken) _amount -= totalReward;
		require(_amount > 0, "no balance");
		IERC20(_token).safeTransfer(msg.sender, _amount);
	}

	// burns xPERPS
	function burn(uint256 _amount) external
	{
		burnOnBehalfOf(_amount, msg.sender);
	}

	// burns xPERPS on behalf of another account
	function burnOnBehalfOf(uint256 _amount, address _account) public hasLaunched nonReentrant
	{
		require(_amount > 0, "invalid amount");

		_updateDay();

		_updateAccount(_account, 0, _amount);

		totalBurned += _amount;

		IERC20(boostToken).safeTransferFrom(msg.sender, FURNACE, _amount);

		emit Burn(_account, boostToken, _amount);
	}

	// stakes BITCORN
	function deposit(uint256 _amount) external
	{
		depositOnBehalfOf(_amount, msg.sender);
	}

	// stakes BITCORN on behalf of another account
	function depositOnBehalfOf(uint256 _amount, address _account) public hasLaunched nonReentrant
	{
		_deposit(msg.sender, _amount, _account);

		emit Deposit(_account, reserveToken, _amount);
	}

	function _deposit(address _sender, uint256 _amount, address _account) internal
	{
		require(_amount > 0, "invalid amount");

		_updateDay();

		uint256 _1percent = _amount * 1e16 / 100e16;
		uint256 _dripAmount = 8 * _1percent;
		uint256 _netAmount = _amount - (11 * _1percent);

		// 8% accounted for the drip pool
		totalDrip1 += _dripAmount;

		// 1% instant rewards (only 7% actually go to the drip pool)
		if (totalStaked > 0) {
			accDripPerShare1 += _1percent * 1e18 / totalStaked;
			allocDrip1 += _1percent;
		}

		// rewards users for xPERPS burned
		if (totalBurned > 0) {
			accBoostPerShare += _1percent * 1e18 / totalBurned;
			totalBoost += _1percent;
		}

		_updateAccount(_account, int256(_netAmount), 0);

		totalStaked += _netAmount;

		if (_sender == address(this)) {
			IERC20(reserveToken).safeTransfer(rehypothecator, _1percent);
		} else {
			_safeTransferFrom(reserveToken, _sender, address(this), _netAmount + _dripAmount + _1percent + _1percent);
			IERC20(reserveToken).safeTransferFrom(_sender, rehypothecator, _1percent);
		}

		// rewards Volatile VDC users
		IERC20(reserveToken).safeApprove(cornVolatile, _1percent);
		CornVolatile(cornVolatile).__rewardAll(_1percent);
	}

	// unstakes BITCORN
	function withdraw(uint256 _amount) external nonReentrant
	{
		require(_amount > 0, "invalid amount");

		AccountInfo storage _accountInfo = accountInfo[msg.sender];
		require(_amount <= _accountInfo.amount, "insufficient balance");

		_updateDay();

		_updateAccount(msg.sender, -int256(_amount), 0);

		totalStaked -= _amount;

		if (_accountInfo.whitelisted || whitelistAll) {
			IERC20(reserveToken).safeTransfer(msg.sender, _amount);
		} else {
			uint256 _1percent = _amount * 1e16 / 100e16;
			uint256 _dripAmount = 8 * _1percent;
			uint256 _netAmount = _amount - (11 * _1percent);

			// 8% accounted for the drip pool
			totalDrip1 += _dripAmount;

			// 1% instant rewards (only 7% actually go to the drip pool)
			if (totalStaked > 0) {
				accDripPerShare1 += _1percent * 1e18 / totalStaked;
				allocDrip1 += _1percent;
			}

			// rewards users for PERPS burned
			if (totalBurned > 0) {
				accBoostPerShare += _1percent * 1e18 / totalBurned;
				totalBoost += _1percent;
			}

			IERC20(reserveToken).safeTransfer(rehypothecator, _1percent);

			// rewards Volatile VDC users
			IERC20(reserveToken).safeApprove(cornVolatile, _1percent);
			CornVolatile(cornVolatile).rewardAll(_1percent);

			IERC20(reserveToken).safeTransfer(msg.sender, _netAmount);
		}

		emit Withdraw(msg.sender, reserveToken, _amount);
	}

	// claims all (BITCORN AND ESHARE)
	function claimAll() external nonReentrant returns (uint256 _rewardAmount, uint256 _dripAmount1, uint256 _boostAmount)
	{
		_updateDay();

		_updateAccount(msg.sender, 0, 0);

		AccountInfo storage _accountInfo = accountInfo[msg.sender];

		_rewardAmount = _accountInfo.reward;
		_dripAmount1 = _accountInfo.drip1;
		uint256 _dripAmount2 = _accountInfo.drip2;
		_boostAmount = _accountInfo.boost;

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

		if (_boostAmount > 0) {
			_accountInfo.boost = 0;

			totalBoost -= _boostAmount;
		}

		if (_dripAmount2 > 0) {
			uint256 _halfAmount = _dripAmount2 / 2;
			totalDrip1 += _halfAmount;
			totalDrip2 += _halfAmount;
		}

		if (_rewardAmount > 0) {
			uint256 _feeAmount = _rewardAmount * 10e16 / 100e16;
			uint256 _netAmount = _rewardAmount - 2 * _feeAmount;
			if (_feeAmount > 0) {
				IERC20(rewardToken).safeApprove(partnerCompound, _feeAmount);
				PartnerCompound(partnerCompound).donateDrip2(_feeAmount);
			}
			IERC20(rewardToken).safeTransfer(bankroll, _feeAmount);
			IERC20(rewardToken).safeTransfer(msg.sender, _netAmount);
		}

		uint256 _drip1PlusBoostAmount = _dripAmount1 + _boostAmount;
		if (_drip1PlusBoostAmount > 0) {
			uint256 _feeAmount = _drip1PlusBoostAmount * 10e16 / 100e16;
			uint256 _netAmount = _drip1PlusBoostAmount - 2 * _feeAmount;
			totalDrip2 += _feeAmount;
			IERC20(reserveToken).safeTransfer(bankroll, _feeAmount);
			IERC20(reserveToken).safeTransfer(msg.sender, _netAmount);
		}

		emit Claim(msg.sender, rewardToken, _rewardAmount);
		emit Claim(msg.sender, reserveToken, _drip1PlusBoostAmount);

		return (_rewardAmount, _dripAmount1, _boostAmount);
	}

	// compounds all (BITCORN and ESHARE)
	function compoundAll() external nonReentrant returns (uint256 _rewardAmount, uint256 _dripAmount1, uint256 _dripAmount2, uint256 _boostAmount)
	{
		_updateDay();

		_updateAccount(msg.sender, 0, 0);

		AccountInfo storage _accountInfo = accountInfo[msg.sender];

		_rewardAmount = _accountInfo.reward;
		_dripAmount1 = _accountInfo.drip1;
		_dripAmount2 = _accountInfo.drip2;
		_boostAmount = _accountInfo.boost;

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

		if (_boostAmount > 0) {
			_accountInfo.boost = 0;

			totalBoost -= _boostAmount;
		}

		if (_rewardAmount > 0) {
			IERC20(rewardToken).safeApprove(partnerCompound, _rewardAmount);
			PartnerCompound(partnerCompound).depositOnBehalfOf(_rewardAmount, msg.sender);
		}

		uint256 _drip1PlusDrip2BoostAmount = _dripAmount1 + _dripAmount2 + _boostAmount;
		if (_drip1PlusDrip2BoostAmount > 0) {
			_deposit(address(this), _drip1PlusDrip2BoostAmount, msg.sender);
		}

		emit Compound(msg.sender, rewardToken, _rewardAmount);
		emit Compound(msg.sender, reserveToken, _drip1PlusDrip2BoostAmount);

		return (_rewardAmount, _dripAmount1, _dripAmount2, _boostAmount);
	}

	// sends BITCORN to a set of accounts
	function reward(address[] calldata _accounts, uint256[] calldata _amounts) external nonReentrant
	{
		require(_accounts.length == _amounts.length, "lenght mismatch");

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

			_safeTransferFrom(rewardToken, msg.sender, address(this), _amount);
		}
	}

	// sends BITCORN to all stakers
	function rewardAll(uint256 _amount) external nonReentrant
	{
		require(_amount > 0, "invalid amount");

		if (totalStaked == 0) {
			IERC20(rewardToken).safeTransferFrom(msg.sender, address(this), _amount);
			return;
		}

		_updateDay();

		accRewardPerShare += _amount * 1e18 / totalStaked;

		totalReward += _amount;

		_safeTransferFrom(rewardToken, msg.sender, address(this), _amount);

		emit RewardAll(msg.sender, rewardToken, _amount);
	}

	// sends BITCORN to the drip pool
	function donateDrip1(uint256 _amount) external nonReentrant
	{
		require(_amount > 0, "invalid amount");

		_updateDay();

		totalDrip1 += _amount;

		_safeTransferFrom(reserveToken, msg.sender, address(this), _amount);

		emit DonateDrip1(msg.sender, reserveToken, _amount);
	}

	// sends BITCORN to the compound drip pool
	function donateDrip2(uint256 _amount) external nonReentrant
	{
		require(_amount > 0, "invalid amount");

		_updateDay();

		totalDrip2 += _amount;

		_safeTransferFrom(reserveToken, msg.sender, address(this), _amount);

		emit DonateDrip2(msg.sender, reserveToken, _amount);
	}

	// performs the daily distribution from the drip pool (BITCORN)
	function updateDay() external nonReentrant
	{
		_updateDay();
	}

	function _updateDay() internal
	{
		uint64 _today = today();

		if (day == _today) return;

		// claims ESHARE rewards from BITCORN
		{
			IClaimable(reserveToken).claim();
			uint256 _balance = IERC20(rewardToken).balanceOf(address(this));
			uint256 _amount = _balance - totalReward;
			if (totalStaked > 0) {
				accRewardPerShare += _amount * 1e18 / totalStaked;
				totalReward += _amount;
			}
		}	

		uint256 _ratePerDay1 = dripRatePerDay1 + dripBoostRatePerDay1;
		if (_ratePerDay1 > 0) {
			// calculates the percentage of the drip pool and distributes
			{
				// formula: drip_reward = drip_pool_balance * (1 - (1 - drip_rate_per_day) ^ days_ellapsed)
				uint64 _days = _today - day;
				uint256 _rate = 100e16 - _exp(100e16 - _ratePerDay1, _days);
				uint256 _amount = (totalDrip1 - allocDrip1) * _rate / 100e16;

				uint256 _amountDrip = _amount * dripRatePerDay1 / _ratePerDay1;
				if (totalStaked > 0) {
					accDripPerShare1 += _amountDrip * 1e18 / totalStaked;
					allocDrip1 += _amountDrip;
				}

				uint256 _amountBoost = _amount - _amountDrip;
				if (totalBurned > 0) {
					accBoostPerShare += _amountBoost * 1e18 / totalBurned;
					totalDrip1 -= _amountBoost;
					totalBoost += _amountBoost;
				}

				emit Drip1(reserveToken, _amountDrip, _amountBoost);
			}
		}

		uint256 _ratePerDay2 = dripRatePerDay2 + dripBoostRatePerDay2;
		if (_ratePerDay2 > 0) {
			// calculates the percentage of the compound drip pool and distributes
			{
				// formula: drip_reward = drip_pool_balance * (1 - (1 - drip_rate_per_day) ^ days_ellapsed)
				uint64 _days = _today - day;
				uint256 _rate = 100e16 - _exp(100e16 - _ratePerDay2, _days);
				uint256 _amount = (totalDrip2 - allocDrip2) * _rate / 100e16;

				uint256 _amountDrip = _amount * dripRatePerDay2 / _ratePerDay2;
				if (totalStaked > 0) {
					accDripPerShare2 += _amountDrip * 1e18 / totalStaked;
					allocDrip2 += _amountDrip;
				}

				uint256 _amountBoost = _amount - _amountDrip;
				if (totalBurned > 0) {
					accBoostPerShare += _amountBoost * 1e18 / totalBurned;
					totalDrip2 -= _amountBoost;
					totalBoost += _amountBoost;
				}

				emit Drip2(reserveToken, _amountDrip, _amountBoost);
			}
		}

		day = _today;
	}

	// updates the account balances while accumulating reward/drip/boost using PCS distribution algorithm
	function _updateAccount(address _account, int256 _amount, uint256 _burned) internal
	{
		AccountInfo storage _accountInfo = accountInfo[_account];
		if (!_accountInfo.exists) {
			// adds account to index
			_accountInfo.exists = true;
			accountIndex.push(_account);
		}

		_accountInfo.reward += _accountInfo.amount * accRewardPerShare / 1e18 - _accountInfo.accRewardDebt;
		_accountInfo.drip1 += _accountInfo.amount * accDripPerShare1 / 1e18 - _accountInfo.accDripDebt1;
		_accountInfo.drip2 += _accountInfo.amount * accDripPerShare2 / 1e18 - _accountInfo.accDripDebt2;
		_accountInfo.boost += _accountInfo.burned * accBoostPerShare / 1e18 - _accountInfo.accBoostDebt;
		if (_amount > 0) {
			_accountInfo.amount += uint256(_amount);
		}
		else
		if (_amount < 0) {
			_accountInfo.amount -= uint256(-_amount);
		}
		_accountInfo.burned += _burned;
		_accountInfo.accRewardDebt = _accountInfo.amount * accRewardPerShare / 1e18;
		_accountInfo.accDripDebt1 = _accountInfo.amount * accDripPerShare1 / 1e18;
		_accountInfo.accDripDebt2 = _accountInfo.amount * accDripPerShare2 / 1e18;
		_accountInfo.accBoostDebt = _accountInfo.burned * accBoostPerShare / 1e18;
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

	// transfer with balance check
	function _safeTransferFrom(address _token, address _from, address _to, uint256 _amount) internal
	{
		uint256 _balanceBefore = IERC20(_token).balanceOf(_to);
		IERC20(_token).safeTransferFrom(_from, _to, _amount);
		uint256 _balanceAfter = IERC20(_token).balanceOf(_to);
		require(_balanceAfter - _balanceBefore == _amount, "inconsistent balance");
	}

	event Burn(address indexed _account, address indexed _boostToken, uint256 _amount);
	event Deposit(address indexed _account, address indexed _reserveToken, uint256 _amount);
	event Withdraw(address indexed _account, address indexed _reserveToken, uint256 _amount);
	event Claim(address indexed _account, address indexed _reserveOrRewardToken, uint256 _amount);
	event Compound(address indexed _account, address indexed _reserveOrRewardToken, uint256 _amount);
	event Reward(address indexed _account, address indexed _rewardToken, uint256 _amount);
	event RewardAll(address indexed _account, address indexed _rewardToken, uint256 _amount);
	event DonateDrip1(address indexed _account, address indexed _reserveToken, uint256 _amount);
	event DonateDrip2(address indexed _account, address indexed _reserveToken, uint256 _amount);
	event Drip1(address indexed _reserveToken, uint256 _dripAmount1, uint256 _boostAmount);
	event Drip2(address indexed _reserveToken, uint256 _dripAmount2, uint256 _boostAmount);
}