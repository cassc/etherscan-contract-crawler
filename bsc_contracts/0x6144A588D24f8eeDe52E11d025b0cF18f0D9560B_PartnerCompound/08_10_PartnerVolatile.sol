// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.9;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Initializable } from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/*
 Volatile VDC fees are 33% in and 33% out, they are distributed in the following way:
 30% to drip pool
 1% Instant dividends to stakers
 1% EMP to xGRO burners
 1% Rehypothecated
 Does not receive incentives daily but does receive 1% of all EMP deposited into Compound VDC

 Add a daily detonation time, whereby users lose all divs that are not claimed by 12:10 AM UTC
 There will be a separate drip pool which will only be accessible to people compounding.. If you claim you will not get divs from that second drip pool..
 Out of the detonated divs, 10% will go to MGMT, (To our Multisig) 45% back to the main drip pool, 45% to the compounders drip pool
 */
contract PartnerVolatile is Initializable, Ownable, ReentrancyGuard
{
	using SafeERC20 for IERC20;

	struct AccountInfo {
		uint256 amount; // EMP staked
		uint256 burned; // xGRO burned
		uint256 reward; // EMP reward from Compound VDC accumulated but not claimed
		uint256 drip1; // EMP from drip pool accumulated but not claimed
		uint256 drip2; // EMP from compound drip pool accumulated but not claimed
		uint256 boost; // EMP from boost accumulated but not claimed
		uint256 bonus; // EMP reward sent directly to top stakers
		uint256 accRewardDebt; // EMP reward debt from PCS distribution algorithm
		uint256 accDripDebt1; // EMP drip pool debt from PCS distribution algorithm
		uint256 accDripDebt2; // EMP compound drip pool debt from PCS distribution algorithm
		uint256 accBoostDebt; // EMP boost debt from PCS distribution algorithm
		uint64 day; // the day index of the last user interaction
		bool whitelisted; // flag indicating whether or not account pays withdraw penalties
		bool exists; // flag to index account
	}

	struct DayInfo {
		uint256 accRewardPerShare; // cumulative reward EMP per EMP staked from PCS distribution algorithm for a given period/day
		uint256 accDripPerShare1; // cumulative drip pool EMP per EMP staked from PCS distribution algorithm for a given period/day
		uint256 accDripPerShare2; // cumulative compound drip pool EMP per EMP staked from PCS distribution algorithm for a given period/day
		uint256 accBoostPerShare; // cumulative boost EMP per xGRO burned from PCS distribution algorithm for a given period/day
		uint256 expiringReward; // EMP reward to expire for a given period/day
		uint256 expiringDrip1; // EMP from drip pool to expire for a given period/day
		uint256 expiringDrip2; // EMP from compound drip pool to expire for a given period/day
		uint256 expiringBoost; // EMP boost to expire for a given period/day
	}

	address constant FURNACE = 0x000000000000000000000000000000000000dEaD;

	address constant DEFAULT_BANKROLL = 0x392681Eaf8AD9BC65e74BE37Afe7503D92802b7d; // multisig
	address constant DEFAULT_REHYPOTHECATOR = 0x2165fa4a32B9c228cD55713f77d2e977297D03e8; // ghost

	uint256 constant DEFAULT_LAUNCH_TIME = 1670605200; // 2022-12-09 5PM UTC
	uint256 constant DEFAULT_DRIP_RATE_PER_DAY_1 = 1e16; // 1% per day
	uint256 constant DEFAULT_DRIP_RATE_PER_DAY_2 = 1e16; // 1% per day
	uint256 constant DEFAULT_DRIP_BOOST_RATE_PER_DAY_1 = 0.5e16; // 0.5% per day
	uint256 constant DEFAULT_DRIP_BOOST_RATE_PER_DAY_2 = 0e16; // 0% per day

	uint256 constant DAY = 30 minutes;
	uint256 constant TZ_OFFSET = 0;

	address public reserveToken; // EMP
	address public rewardToken; // EMP
	address public boostToken; // xGRO

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

	uint256 public totalReward = 0; // total reward balance

	uint256 public totalDrip1 = 0; // total drip pool balance
	uint256 public allocDrip1 = 0; // total drip pool balance allocated

	uint256 public totalDrip2 = 0; // total compound drip pool balance
	uint256 public allocDrip2 = 0; // total compound drip pool balance allocated

	uint256 public totalBoost = 0; // total boost balance

	uint64 public day = today();

	mapping(uint64 => DayInfo) public dayInfo; // info per day

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

	constructor(address _reserveToken, address _boostToken)
	{
		initialize(msg.sender, _reserveToken, _boostToken);
	}

	function initialize(address _owner, address _reserveToken, address _boostToken) public initializer
	{
		_transferOwnership(_owner);

		bankroll = DEFAULT_BANKROLL;

		launchTime = DEFAULT_LAUNCH_TIME;

		dripRatePerDay1 = DEFAULT_DRIP_RATE_PER_DAY_1;
		dripRatePerDay2 = DEFAULT_DRIP_RATE_PER_DAY_2;
		dripBoostRatePerDay1 = DEFAULT_DRIP_BOOST_RATE_PER_DAY_1;
		dripBoostRatePerDay2 = DEFAULT_DRIP_BOOST_RATE_PER_DAY_2;

		whitelistAll = false;

		totalStaked = 0; // total staked balance
		totalBurned = 0; // total burned balance

		totalReward = 0; // total reward balance

		totalDrip1 = 0; // total drip pool balance
		allocDrip1 = 0; // total drip pool balance allocated

		totalDrip2 = 0; // total compound drip pool balance
		allocDrip2 = 0; // total compound drip pool balance allocated

		totalBoost = 0; // total boost balance

		day = today();

		require(_boostToken != _reserveToken, "invalid token");
		reserveToken = _reserveToken;
		rewardToken = _reserveToken;
		boostToken = _boostToken;
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
		if (_token == reserveToken) _amount -= totalStaked + totalDrip1 + totalDrip2 + totalReward + totalBoost;
		require(_amount > 0, "no balance");
		IERC20(_token).safeTransfer(msg.sender, _amount);
	}

	// burns xGRO
	function burn(uint256 _amount) external
	{
		burnOnBehalfOf(_amount, msg.sender);
	}

	// burns xGRO on behalf of another account
	function burnOnBehalfOf(uint256 _amount, address _account) public hasLaunched nonReentrant
	{
		require(_amount > 0, "invalid amount");

		_updateDay();

		_updateAccount(_account, 0, _amount);

		totalBurned += _amount;

		IERC20(boostToken).safeTransferFrom(msg.sender, FURNACE, _amount);

		emit Burn(_account, boostToken, _amount);
	}

	// stakes EMP
	function deposit(uint256 _amount) external hasLaunched nonReentrant
	{
		_deposit(msg.sender, _amount, msg.sender);

		emit Deposit(msg.sender, reserveToken, _amount);
	}

	// stakes EMP on behalf of another account
	function depositOnBehalfOf(uint256 _amount, address _account) external hasLaunched nonReentrant
	{
		_deposit(msg.sender, _amount, _account);

		emit Deposit(_account, reserveToken, _amount);
	}

	function _deposit(address _sender, uint256 _amount, address _account) internal
	{
		require(_amount > 0, "invalid amount");

		_updateDay();

		uint256 _1percent = _amount * 1e16 / 100e16;
		uint256 _dripAmount = 31 * _1percent;
		uint256 _netAmount = _amount - (33 * _1percent);

		DayInfo storage _dayInfo = dayInfo[day];

		// 31% accounted for the drip pool
		totalDrip1 += _dripAmount;

		// 1% instant rewards (only 30% actually go to the drip pool)
		if (totalStaked > 0) {
			_dayInfo.accDripPerShare1 += _1percent * 1e18 / totalStaked;
			_dayInfo.expiringDrip1 += _1percent;
			allocDrip1 += _1percent;
		}

		// rewards users for xGRO burned
		if (totalBurned > 0) {
			_dayInfo.accBoostPerShare += _1percent * 1e18 / totalBurned;
			_dayInfo.expiringBoost += _1percent;
			totalBoost += _1percent;
		}

		_updateAccount(_account, int256(_netAmount), 0);

		totalStaked += _netAmount;

		if (_sender == address(this)) {
			IERC20(reserveToken).safeTransfer(rehypothecator, _1percent);
		} else {
			IERC20(reserveToken).safeTransferFrom(_sender, address(this), _netAmount + _dripAmount + _1percent);
			IERC20(reserveToken).safeTransferFrom(_sender, rehypothecator, _1percent);
		}
	}

	// unstakes EMP
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
			uint256 _dripAmount = 31 * _1percent;
			uint256 _netAmount = _amount - (33 * _1percent);

			DayInfo storage _dayInfo = dayInfo[day];

			// 31% accounted for the drip pool
			totalDrip1 += _dripAmount;

			// 1% instant rewards (only 30% actually go to the drip pool)
			if (totalStaked > 0) {
				_dayInfo.accDripPerShare1 += _1percent * 1e18 / totalStaked;
				_dayInfo.expiringDrip1 += _1percent;
				allocDrip1 += _1percent;
			}

			// rewards users for xGRO burned
			if (totalBurned > 0) {
				_dayInfo.accBoostPerShare += _1percent * 1e18 / totalBurned;
				_dayInfo.expiringBoost += _1percent;
				totalBoost += _1percent;
			}

			IERC20(reserveToken).safeTransfer(rehypothecator, _1percent);

			IERC20(reserveToken).safeTransfer(msg.sender, _netAmount);
		}

		emit Withdraw(msg.sender, reserveToken, _amount);
	}

	// claims all (EMP)
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

			dayInfo[day].expiringDrip2 += _dripAmount2;
		}

		if (_boostAmount > 0) {
			_accountInfo.boost = 0;

			totalBoost -= _boostAmount;
		}

		uint256 _rewardPlusDripPlusBoostAmount = _rewardAmount + _dripAmount1 + _boostAmount;
		if (_rewardPlusDripPlusBoostAmount > 0) {
			IERC20(reserveToken).safeTransfer(msg.sender, _rewardPlusDripPlusBoostAmount);
		}

		emit Claim(msg.sender, rewardToken, _rewardAmount, _dripAmount1, _boostAmount);

		return (_rewardAmount, _dripAmount1, _boostAmount);
	}

	// compounds all (EMP)
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

		uint256 _rewardPlusDripPlusBoostAmount = _rewardAmount + _dripAmount1 + _dripAmount2 + _boostAmount;
		if (_rewardPlusDripPlusBoostAmount > 0) {
			_deposit(address(this), _rewardPlusDripPlusBoostAmount, msg.sender);
		}

		emit Compound(msg.sender, rewardToken, _rewardAmount, _dripAmount1, _dripAmount2, _boostAmount);

		return (_rewardAmount, _dripAmount1, _dripAmount2, _boostAmount);
	}

	// sends EMP to a set of accounts
	function reward(address[] calldata _accounts, uint256[] calldata _amounts) external nonReentrant
	{
		require(_accounts.length == _amounts.length, "lenght mismatch");

		_updateDay();

		uint256 _totalAmount = 0;

		for (uint256 _i = 0; _i < _accounts.length; _i++) {
			address _account = _accounts[_i];
			uint256 _amount = _amounts[_i];

			AccountInfo storage _accountInfo = accountInfo[_account];
			require(_accountInfo.exists, "invalid account");

			_accountInfo.bonus += _amount;

			emit Reward(_account, rewardToken, _amount);

			_totalAmount += _amount;
		}

		if (_totalAmount > 0) {
			dayInfo[day].expiringReward += _totalAmount;

			totalReward += _totalAmount;

			IERC20(rewardToken).safeTransferFrom(msg.sender, address(this), _totalAmount);
		}
	}

	// sends EMP to all stakers
	function rewardAll(uint256 _amount) external nonReentrant
	{
		require(_amount > 0, "invalid amount");

		if (totalStaked == 0) {
			IERC20(rewardToken).safeTransferFrom(msg.sender, address(this), _amount);
			return;
		}

		_updateDay();

		DayInfo storage _dayInfo = dayInfo[day];

		_dayInfo.accRewardPerShare += _amount * 1e18 / totalStaked;
		_dayInfo.expiringReward += _amount;

		totalReward += _amount;

		IERC20(rewardToken).safeTransferFrom(msg.sender, address(this), _amount);

		emit RewardAll(msg.sender, rewardToken, _amount);
	}

	// sends EMP to the drip pool
	function donateDrip1(uint256 _amount) external nonReentrant
	{
		require(_amount > 0, "invalid amount");

		_updateDay();

		totalDrip1 += _amount;

		IERC20(reserveToken).safeTransferFrom(msg.sender, address(this), _amount);

		emit DonateDrip1(msg.sender, reserveToken, _amount);
	}

	// sends EMP to the compound drip pool
	function donateDrip2(uint256 _amount) external nonReentrant
	{
		require(_amount > 0, "invalid amount");

		_updateDay();

		totalDrip2 += _amount;

		IERC20(reserveToken).safeTransferFrom(msg.sender, address(this), _amount);

		emit DonateDrip2(msg.sender, reserveToken, _amount);
	}

	// performs the daily distribution from the drip pool (EMP)
	function updateDay() external nonReentrant
	{
		_updateDay();
	}

	function _updateDay() internal
	{
		uint64 _today = today();

		if (day == _today) return;

		uint256 _feeAmount = 0;

		{
			DayInfo storage _dayInfo = dayInfo[day];

			uint256 _rewardAmount = _dayInfo.expiringReward;
			uint256 _dripAmount1 = _dayInfo.expiringDrip1;
			uint256 _dripAmount2 = _dayInfo.expiringDrip2;
			uint256 _boostAmount = _dayInfo.expiringBoost;

			if (_rewardAmount > 0) {
				_dayInfo.expiringReward = 0;

				totalReward -= _rewardAmount;
			}

			if (_dripAmount1 > 0) {
				_dayInfo.expiringDrip1 = 0;

				totalDrip1 -= _dripAmount1;
				allocDrip1 -= _dripAmount1;
			}

			if (_dripAmount2 > 0) {
				_dayInfo.expiringDrip2 = 0;

				totalDrip2 -= _dripAmount2;
				allocDrip2 -= _dripAmount2;
			}

			if (_boostAmount > 0) {
				_dayInfo.expiringBoost = 0;

				totalBoost -= _boostAmount;
			}

			uint256 _expiredAmount = _rewardAmount + _dripAmount1 + _dripAmount2 + _boostAmount;
			if (_expiredAmount > 0) {
				_feeAmount = _expiredAmount * 10e16 / 100e16;

				uint256 _halfAmount = (_expiredAmount - _feeAmount) / 2;

				totalDrip1 += _halfAmount;
				totalDrip2 += _halfAmount;
			}

			for (uint64 _day = day + 1; _day <= _today; _day++) {
				DayInfo storage _nextDayInfo = dayInfo[_day];
				_nextDayInfo.accRewardPerShare = _dayInfo.accRewardPerShare;
				_nextDayInfo.accDripPerShare1 = _dayInfo.accDripPerShare1;
				_nextDayInfo.accDripPerShare2 = _dayInfo.accDripPerShare2;
				_nextDayInfo.accBoostPerShare = _dayInfo.accBoostPerShare;
			}

			emit Expire(msg.sender, rewardToken, _rewardAmount, _dripAmount1, _dripAmount2, _boostAmount);
		}

		{
			DayInfo storage _dayInfo = dayInfo[_today];

			// calculates the percentage of the drip pool and distributes
			uint256 _ratePerDay = dripRatePerDay1 + dripBoostRatePerDay1;
			if (_ratePerDay > 0) {
				// formula: drip_reward = drip_pool_balance * (1 - (1 - drip_rate_per_day) ^ days_ellapsed)
				uint64 _days = _today - day;
				uint256 _rate = 100e16 - _exp(100e16 - _ratePerDay, _days);
				uint256 _amount = (totalDrip1 - allocDrip1) * _rate / 100e16;

				uint256 _amountDrip = _amount * dripRatePerDay1 / _ratePerDay;
				if (totalStaked > 0) {
					_dayInfo.accDripPerShare1 += _amountDrip * 1e18 / totalStaked;
					_dayInfo.expiringDrip1 += _amountDrip;
					allocDrip1 += _amountDrip;
				}

				uint256 _amountBoost = _amount - _amountDrip;
				if (totalBurned > 0) {
					_dayInfo.accBoostPerShare += _amountBoost * 1e18 / totalBurned;
					_dayInfo.expiringBoost += _amountBoost;
					totalDrip1 -= _amountBoost;
					totalBoost += _amountBoost;
				}

				emit Drip1(rewardToken, _amountDrip, _amountBoost);
			}
		}

		{
			DayInfo storage _dayInfo = dayInfo[_today];

			// calculates the percentage of the compound drip pool and distributes
			uint256 _ratePerDay = dripRatePerDay2 + dripBoostRatePerDay2;
			if (_ratePerDay > 0) {
				// formula: drip_reward = drip_pool_balance * (1 - (1 - drip_rate_per_day) ^ days_ellapsed)
				uint64 _days = _today - day;
				uint256 _rate = 100e16 - _exp(100e16 - _ratePerDay, _days);
				uint256 _amount = (totalDrip2 - allocDrip2) * _rate / 100e16;

				uint256 _amountDrip = _amount * dripRatePerDay2 / _ratePerDay;
				if (totalStaked > 0) {
					_dayInfo.accDripPerShare2 += _amountDrip * 1e18 / totalStaked;
					_dayInfo.expiringDrip2 += _amountDrip;
					allocDrip2 += _amountDrip;
				}

				uint256 _amountBoost = _amount - _amountDrip;
				if (totalBurned > 0) {
					_dayInfo.accBoostPerShare += _amountBoost * 1e18 / totalBurned;
					_dayInfo.expiringBoost += _amountBoost;
					totalDrip2 -= _amountBoost;
					totalBoost += _amountBoost;
				}

				emit Drip2(rewardToken, _amountDrip, _amountBoost);
			}
		}

		day = _today;

		if (_feeAmount > 0) {
			IERC20(rewardToken).safeTransfer(bankroll, _feeAmount);
		}
	}

	// updates the account balances while accumulating reward/drip/boost using PCS distribution algorithm
	function _updateAccount(address _account, int256 _amount, uint256 _burned) internal
	{
		AccountInfo storage _accountInfo = accountInfo[_account];
		if (!_accountInfo.exists) {
			// adds account to index
			_accountInfo.exists = true;
			_accountInfo.day = day;
			accountIndex.push(_account);
		}

		// if account rewards expired, then resets to the previous day
		if (_accountInfo.day < day) {
			DayInfo storage _dayInfo = dayInfo[day - 1];
			_accountInfo.bonus = 0;
			_accountInfo.accRewardDebt = _accountInfo.amount * _dayInfo.accRewardPerShare / 1e18;
			_accountInfo.accDripDebt1 = _accountInfo.amount * _dayInfo.accDripPerShare1 / 1e18;
			_accountInfo.accDripDebt2 = _accountInfo.amount * _dayInfo.accDripPerShare2 / 1e18;
			_accountInfo.accBoostDebt = _accountInfo.burned * _dayInfo.accBoostPerShare / 1e18;
			_accountInfo.day = day;
		}

		// collects rewards for the current day and adjusts balance
		{
			DayInfo storage _dayInfo = dayInfo[day];
			uint256 _rewardAmount = _accountInfo.amount * _dayInfo.accRewardPerShare / 1e18 - _accountInfo.accRewardDebt + _accountInfo.bonus;
			uint256 _drip1Amount = _accountInfo.amount * _dayInfo.accDripPerShare1 / 1e18 - _accountInfo.accDripDebt1;
			uint256 _drip2Amount = _accountInfo.amount * _dayInfo.accDripPerShare2 / 1e18 - _accountInfo.accDripDebt2;
			uint256 _boostAmount = _accountInfo.burned * _dayInfo.accBoostPerShare / 1e18 - _accountInfo.accBoostDebt;
			_dayInfo.expiringReward -= _rewardAmount;
			_dayInfo.expiringDrip1 -= _drip1Amount;
			_dayInfo.expiringDrip2 -= _drip2Amount;
			_dayInfo.expiringBoost -= _boostAmount;
			_accountInfo.reward += _rewardAmount;
			_accountInfo.drip1 += _drip1Amount;
			_accountInfo.drip2 += _drip2Amount;
			_accountInfo.boost += _boostAmount;
			if (_amount > 0) {
				_accountInfo.amount += uint256(_amount);
			}
			else
			if (_amount < 0) {
				_accountInfo.amount -= uint256(-_amount);
			}
			_accountInfo.burned += _burned;
			_accountInfo.bonus = 0;
			_accountInfo.accRewardDebt = _accountInfo.amount * _dayInfo.accRewardPerShare / 1e18;
			_accountInfo.accDripDebt1 = _accountInfo.amount * _dayInfo.accDripPerShare1 / 1e18;
			_accountInfo.accDripDebt2 = _accountInfo.amount * _dayInfo.accDripPerShare2 / 1e18;
			_accountInfo.accBoostDebt = _accountInfo.burned * _dayInfo.accBoostPerShare / 1e18;
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

	event Burn(address indexed _account, address indexed _boostToken, uint256 _amount);
	event Deposit(address indexed _account, address indexed _reserveToken, uint256 _amount);
	event Withdraw(address indexed _account, address indexed _reserveToken, uint256 _amount);
	event Claim(address indexed _account, address indexed _rewardToken, uint256 _rewardAmount, uint256 _dripAmount1, uint256 _boostAmount);
	event Compound(address indexed _account, address indexed _rewardToken, uint256 _rewardAmount, uint256 _dripAmount1, uint256 _dripAmount2, uint256 _boostAmount);
	event Reward(address indexed _account, address indexed _rewardToken, uint256 _amount);
	event RewardAll(address indexed _account, address indexed _rewardToken, uint256 _amount);
	event DonateDrip1(address indexed _account, address indexed _reserveToken, uint256 _amount);
	event DonateDrip2(address indexed _account, address indexed _reserveToken, uint256 _amount);
	event Expire(address indexed _account, address indexed _rewardToken, uint256 _rewardAmount, uint256 _dripAmount1, uint256 _dripAmount2, uint256 _boostAmount);
	event Drip1(address indexed _rewardToken, uint256 _dripAmount1, uint256 _boostAmount);
	event Drip2(address indexed _rewardToken, uint256 _dripAmount2, uint256 _boostAmount);
}