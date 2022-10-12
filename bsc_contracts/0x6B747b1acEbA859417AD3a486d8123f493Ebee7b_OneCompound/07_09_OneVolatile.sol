// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.9;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Initializable } from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import { OneCompound } from "./OneCompound.sol";

/*
 Volatile VDC fees are 33% in and 33% out, they are distributed in the following way:
 30% to drip pool
 1% Instant dividends to stakers
 1% xONE to xPERPS stakers
 1% Payout
 Does not receive incentives daily but does receive 1% of all xONE-S deposited into Compound VDC
 */
contract OneVolatile is Initializable, Ownable, ReentrancyGuard
{
	using SafeERC20 for IERC20;

	struct AccountInfo {
		uint256 amount; // xONE staked
		uint256 burned; // xPERPS burned
		uint256 reward; // xONE-S reward from Compound VDC accumulated but not claimed
		uint256 drip; // xONE from drip pool accumulated but not claimed
		uint256 boost; // xONE from boost accumulated but not claimed
		uint256 accRewardDebt; // xONE-S reward debt from PCS distribution algorithm
		uint256 accDripDebt; // xONE reward debt from PCS distribution algorithm
		uint256 accBoostDebt; // xONE reward debt from PCS distribution algorithm
		bool whitelisted; // flag indicating whether or not account pays withdraw penalties
		bool exists; // flag to index account
	}

	address constant FURNACE = 0x000000000000000000000000000000000000dEaD;

	address constant EARLY_DEPOSITOR = 0x2165fa4a32B9c228cD55713f77d2e977297D03e8; // ghost

	address constant DEFAULT_PAYOUT = 0x5c327D395D0617f5b6ad6E8Da5dCBb35A6Be5b11; // ghost

	uint256 constant DEFAULT_LAUNCH_TIME = 1665597600; // 2022-10-12 6PM UTC
	uint256 constant DEFAULT_DRIP_RATE_PER_DAY = 1e16; // 1% per day
	uint256 constant DEFAULT_DRIP_BOOST_RATE_PER_DAY = 0.5e16; // 0.5% per day

	uint256 constant DAY = 1 days;
	uint256 constant TZ_OFFSET = 22 hours + 30 minutes; // UTC-1.30

	address public reserveToken; // xONE
	address public rewardToken; // xONE-S
	address public boostToken; // xPERPS

	address public oneCompound;

	address public payout = DEFAULT_PAYOUT;

	uint256 public launchTime = DEFAULT_LAUNCH_TIME;

	uint256 public dripRatePerDay = DEFAULT_DRIP_RATE_PER_DAY;
	uint256 public dripBoostRatePerDay = DEFAULT_DRIP_BOOST_RATE_PER_DAY;

	bool public whitelistAll = false;

	uint256 public totalStaked = 0; // total staked balance
	uint256 public totalBurned = 0; // total burned balance

	uint256 public totalDrip = 0; // total drip pool balance
	uint256 public allocDrip = 0; // total drip pool balance allocated

	uint256 public totalReward = 0; // total reward balance

	uint256 public totalBoost = 0; // total boost balance

	uint256 public accRewardPerShare = 0; // cumulative reward xONE-S per xONE staked from PCS distribution algorithm
	uint256 public accDripPerShare = 0; // cumulative drip pool xONE per xONE staked from PCS distribution algorithm
	uint256 public accBoostPerShare = 0; // cumulative boost xONE per xPERPS burned from PCS distribution algorithm

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
		require(block.timestamp >= launchTime || msg.sender == EARLY_DEPOSITOR, "unavailable");
		_;
	}

	constructor(address _reserveToken, address _rewardToken, address _boostToken, address _oneCompound)
	{
		initialize(msg.sender, _reserveToken, _rewardToken, _boostToken, _oneCompound);
	}

	function initialize(address _owner, address _reserveToken, address _rewardToken, address _boostToken, address _oneCompound) public initializer
	{
		_transferOwnership(_owner);

		payout = DEFAULT_PAYOUT;

		launchTime = DEFAULT_LAUNCH_TIME;

		dripRatePerDay = DEFAULT_DRIP_RATE_PER_DAY;
		dripBoostRatePerDay = DEFAULT_DRIP_BOOST_RATE_PER_DAY;

		whitelistAll = false;

		totalStaked = 0; // total staked balance
		totalBurned = 0; // total burned balance

		totalDrip = 0; // total drip pool balance
		allocDrip = 0; // total drip pool balance allocated

		totalReward = 0; // total reward balance

		totalBoost = 0; // total boost balance

		accRewardPerShare = 0; // cumulative reward xONE-S per xONE staked from PCS distribution algorithm
		accDripPerShare = 0; // cumulative drip pool xONE per xONE staked from PCS distribution algorithm
		accBoostPerShare = 0; // cumulative boost xONE per xPERPS burned from PCS distribution algorithm

		day = today();

		require(_rewardToken != _reserveToken && _boostToken != _reserveToken && _boostToken != _rewardToken, "invalid token");
		reserveToken = _reserveToken;
		rewardToken = _rewardToken;
		boostToken = _boostToken;
		oneCompound = _oneCompound;
	}

	// updates the compound vdc address
	function setOneCompound(address _oneCompound) external onlyOwner
	{
		require(_oneCompound != address(0), "invalid address");
		oneCompound = _oneCompound;
	}

	// updates the payout address
	function setPayout(address _payout) external onlyOwner
	{
		require(_payout != address(0), "invalid address");
		payout = _payout;
	}

	// updates the launch time
	function setLaunchTime(uint256 _launchTime) external onlyOwner
	{
		require(block.timestamp < launchTime, "unavailable");
		require(_launchTime >= block.timestamp, "invalid time");
		launchTime = _launchTime;
	}

	// updates the percentual rate of distribution from the drip pool
	function setDripRatePerDay(uint256 _dripRatePerDay) external onlyOwner
	{
		require(_dripRatePerDay + dripBoostRatePerDay <= 100e16, "invalid rate");
		dripRatePerDay = _dripRatePerDay;
	}

	// updates the percentual rate of distribution from the drip pool
	function setDripBoostRatePerDay(uint256 _dripBoostRatePerDay) external onlyOwner
	{
		require(dripRatePerDay + _dripBoostRatePerDay <= 100e16, "invalid rate");
		dripBoostRatePerDay = _dripBoostRatePerDay;
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
		if (_token == rewardToken) _amount -= totalReward;
		if (_token == reserveToken) _amount -= totalStaked + totalDrip + totalBoost;
		require(_amount > 0, "no balance");
		IERC20(_token).safeTransfer(msg.sender, _amount);
	}

	// burns xPERPS
	function burn(uint256 _amount) external
	{
		burnOnBehalfOf(_amount, msg.sender);
	}

	// burns xPERPS on behalf of another account
	function burnOnBehalfOf(uint256 _amount, address _account) public nonReentrant
	{
		require(_amount > 0, "invalid amount");

		_updateAccount(_account, 0, _amount);

		totalBurned += _amount;

		IERC20(boostToken).safeTransferFrom(msg.sender, FURNACE, _amount);

		emit Burn(_account, boostToken, _amount);
	}

	// stakes xONE
	function deposit(uint256 _amount) external hasLaunched nonReentrant
	{
		_deposit(msg.sender, _amount, msg.sender);

		emit Deposit(msg.sender, reserveToken, _amount);
	}

	// stakes xONE on behalf of another account
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

		// 31% accounted for the drip pool
		totalDrip += _dripAmount;

		// 1% instant rewards (only 30% actually go to the drip pool)
		if (totalStaked > 0) {
			accDripPerShare += _1percent * 1e18 / totalStaked;
			allocDrip += _1percent;
		}

		// rewards users for xPERPS burned
		if (totalBurned > 0) {
			accBoostPerShare += _1percent * 1e18 / totalBurned;
			totalBoost += _1percent;
		}

		_updateAccount(_account, int256(_netAmount), 0);

		totalStaked += _netAmount;

		if (_sender == address(this)) {
			IERC20(reserveToken).safeTransfer(payout, _1percent);
		} else {
			IERC20(reserveToken).safeTransferFrom(_sender, address(this), _netAmount + _dripAmount + _1percent);
			IERC20(reserveToken).safeTransferFrom(_sender, payout, _1percent);
		}
	}

	// unstakes xONE
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

			// 31% accounted for the drip pool
			totalDrip += _dripAmount;

			// 1% instant rewards (only 30% actually go to the drip pool)
			if (totalStaked > 0) {
				accDripPerShare += _1percent * 1e18 / totalStaked;
				allocDrip += _1percent;
			}

			// rewards users for xPERPS burned
			if (totalBurned > 0) {
				accBoostPerShare += _1percent * 1e18 / totalBurned;
				totalBoost += _1percent;
			}

			IERC20(reserveToken).safeTransfer(payout, _1percent);

			IERC20(reserveToken).safeTransfer(msg.sender, _netAmount);
		}

		emit Withdraw(msg.sender, reserveToken, _amount);
	}

	// claims rewards only (xONE-S)
	function claimReward() external nonReentrant returns (uint256 _rewardAmount)
	{
		_updateDay();

		_updateAccount(msg.sender, 0, 0);

		AccountInfo storage _accountInfo = accountInfo[msg.sender];

		_rewardAmount = _accountInfo.reward;

		if (_rewardAmount > 0) {
			_accountInfo.reward = 0;

			totalReward -= _rewardAmount;

			IERC20(rewardToken).safeTransfer(msg.sender, _rewardAmount);
		}

		emit Claim(msg.sender, rewardToken, _rewardAmount);

		return _rewardAmount;
	}
/*
	// claims drip only (xONE)
	function claimDrip() external nonReentrant returns (uint256 _dripAmount)
	{
		_updateDay();

		_updateAccount(msg.sender, 0, 0);

		AccountInfo storage _accountInfo = accountInfo[msg.sender];

		_dripAmount = _accountInfo.drip;

		if (_dripAmount > 0) {
			_accountInfo.drip = 0;

			totalDrip -= _dripAmount;
			allocDrip -= _dripAmount;

			IERC20(reserveToken).safeTransfer(msg.sender, _dripAmount);
		}

		emit Claim(msg.sender, reserveToken, _dripAmount);

		return _dripAmount;
	}

	// claims boost only (xONE)
	function claimBoost() external nonReentrant returns (uint256 _boostAmount)
	{
		_updateDay();

		_updateAccount(msg.sender, 0, 0);

		AccountInfo storage _accountInfo = accountInfo[msg.sender];

		_boostAmount = _accountInfo.boost;

		if (_boostAmount > 0) {
			_accountInfo.boost = 0;

			totalBoost -= _boostAmount;

			IERC20(reserveToken).safeTransfer(msg.sender, _boostAmount);
		}

		emit Claim(msg.sender, reserveToken, _boostAmount);

		return _boostAmount;
	}
*/
	// claims drip and boost (xONE)
	function claimDripAndBoost() external nonReentrant returns (uint256 _dripAmount, uint256 _boostAmount)
	{
		_updateDay();

		_updateAccount(msg.sender, 0, 0);

		AccountInfo storage _accountInfo = accountInfo[msg.sender];

		_dripAmount = _accountInfo.drip;
		_boostAmount = _accountInfo.boost;

		if (_dripAmount > 0) {
			_accountInfo.drip = 0;

			totalDrip -= _dripAmount;
			allocDrip -= _dripAmount;
		}

		if (_boostAmount > 0) {
			_accountInfo.boost = 0;

			totalBoost -= _boostAmount;
		}

		uint256 _dripPlusBoostAmount = _dripAmount + _boostAmount;
		if (_dripPlusBoostAmount > 0) {
			IERC20(reserveToken).safeTransfer(msg.sender, _dripPlusBoostAmount);
		}

		emit Claim(msg.sender, reserveToken, _dripAmount);
		emit Claim(msg.sender, reserveToken, _boostAmount);

		return (_dripAmount, _boostAmount);
	}

	// claims all (xONE and xONE-S)
	function claimAll() external nonReentrant returns (uint256 _rewardAmount, uint256 _dripAmount, uint256 _boostAmount)
	{
		_updateDay();

		_updateAccount(msg.sender, 0, 0);

		AccountInfo storage _accountInfo = accountInfo[msg.sender];

		_rewardAmount = _accountInfo.reward;
		_dripAmount = _accountInfo.drip;
		_boostAmount = _accountInfo.boost;

		if (_rewardAmount > 0) {
			_accountInfo.reward = 0;

			totalReward -= _rewardAmount;
		}

		if (_dripAmount > 0) {
			_accountInfo.drip = 0;

			totalDrip -= _dripAmount;
			allocDrip -= _dripAmount;
		}

		if (_boostAmount > 0) {
			_accountInfo.boost = 0;

			totalBoost -= _boostAmount;
		}

		if (_rewardAmount > 0) {
			IERC20(rewardToken).safeTransfer(msg.sender, _rewardAmount);
		}

		uint256 _dripPlusBoostAmount = _dripAmount + _boostAmount;
		if (_dripPlusBoostAmount > 0) {
			IERC20(reserveToken).safeTransfer(msg.sender, _dripPlusBoostAmount);
		}

		emit Claim(msg.sender, rewardToken, _rewardAmount);
		emit Claim(msg.sender, reserveToken, _dripAmount);
		emit Claim(msg.sender, reserveToken, _boostAmount);

		return (_rewardAmount, _dripAmount, _boostAmount);
	}

	// compounds rewards only (xONE-S)
	function compoundReward() external nonReentrant
	{
		_updateDay();

		_updateAccount(msg.sender, 0, 0);

		AccountInfo storage _accountInfo = accountInfo[msg.sender];

		uint256 _rewardAmount = _accountInfo.reward;

		if (_rewardAmount > 0) {
			_accountInfo.reward = 0;

			totalReward -= _rewardAmount;

			IERC20(rewardToken).safeApprove(oneCompound, _rewardAmount);
			OneCompound(oneCompound).depositOnBehalfOf(_rewardAmount, msg.sender);
		}

		emit Compound(msg.sender, rewardToken, _rewardAmount);
	}
/*
	// compounds drip only (xONE)
	function compoundDrip() external nonReentrant
	{
		_updateDay();

		_updateAccount(msg.sender, 0, 0);

		AccountInfo storage _accountInfo = accountInfo[msg.sender];

		uint256 _dripAmount = _accountInfo.drip;

		if (_dripAmount > 0) {
			_accountInfo.drip = 0;

			totalDrip -= _dripAmount;
			allocDrip -= _dripAmount;

			_deposit(address(this), _dripAmount, msg.sender);
		}

		emit Compound(msg.sender, reserveToken, _dripAmount);
	}

	// compounds boost only (xONE)
	function compoundBoost() external nonReentrant
	{
		_updateDay();

		_updateAccount(msg.sender, 0, 0);

		AccountInfo storage _accountInfo = accountInfo[msg.sender];

		uint256 _boostAmount = _accountInfo.boost;

		if (_boostAmount > 0) {
			_accountInfo.boost = 0;

			totalBoost -= _boostAmount;

			_deposit(address(this), _boostAmount, msg.sender);
		}

		emit Compound(msg.sender, reserveToken, _boostAmount);
	}
*/
	// compounds drip and boost (xONE)
	function compoundDripAndBoost() external nonReentrant
	{
		_updateDay();

		_updateAccount(msg.sender, 0, 0);

		AccountInfo storage _accountInfo = accountInfo[msg.sender];

		uint256 _dripAmount = _accountInfo.drip;
		uint256 _boostAmount = _accountInfo.boost;

		if (_dripAmount > 0) {
			_accountInfo.drip = 0;

			totalDrip -= _dripAmount;
			allocDrip -= _dripAmount;
		}

		if (_boostAmount > 0) {
			_accountInfo.boost = 0;

			totalBoost -= _boostAmount;
		}

		uint256 _dripPlusBoostAmount = _dripAmount + _boostAmount;
		if (_dripPlusBoostAmount > 0) {
			_deposit(address(this), _dripPlusBoostAmount, msg.sender);
		}

		emit Compound(msg.sender, reserveToken, _dripAmount);
		emit Compound(msg.sender, reserveToken, _boostAmount);
	}

	// compounds all (xONE and xONE-S)
	function compoundAll() external nonReentrant
	{
		_updateDay();

		_updateAccount(msg.sender, 0, 0);

		AccountInfo storage _accountInfo = accountInfo[msg.sender];

		uint256 _rewardAmount = _accountInfo.reward;
		uint256 _dripAmount = _accountInfo.drip;
		uint256 _boostAmount = _accountInfo.boost;

		if (_rewardAmount > 0) {
			_accountInfo.reward = 0;

			totalReward -= _rewardAmount;
		}

		if (_dripAmount > 0) {
			_accountInfo.drip = 0;

			totalDrip -= _dripAmount;
			allocDrip -= _dripAmount;
		}

		if (_boostAmount > 0) {
			_accountInfo.boost = 0;

			totalBoost -= _boostAmount;
		}

		if (_rewardAmount > 0) {
			IERC20(rewardToken).safeApprove(oneCompound, _rewardAmount);
			OneCompound(oneCompound).depositOnBehalfOf(_rewardAmount, msg.sender);
		}

		uint256 _dripPlusBoostAmount = _dripAmount + _boostAmount;
		if (_dripPlusBoostAmount > 0) {
			_deposit(address(this), _dripPlusBoostAmount, msg.sender);
		}

		emit Compound(msg.sender, rewardToken, _rewardAmount);
		emit Compound(msg.sender, reserveToken, _dripAmount);
		emit Compound(msg.sender, reserveToken, _boostAmount);
	}

	// sends xONE-S to a set of accounts
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

			IERC20(rewardToken).safeTransferFrom(msg.sender, address(this), _amount);
		}
	}

	// sends xONE-S to all stakers
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

		IERC20(rewardToken).safeTransferFrom(msg.sender, address(this), _amount);

		emit RewardAll(msg.sender, rewardToken, _amount);
	}

	// performs the daily distribution from the drip pool (xONE)
	function updateDay() external nonReentrant
	{
		_updateDay();
	}

	function _updateDay() internal
	{
		uint64 _today = today();

		if (day == _today) return;

		uint256 _ratePerDay = dripRatePerDay + dripBoostRatePerDay;
		if (_ratePerDay > 0) {
			// calculates the percentage of the drip pool and distributes
			{
				// formula: drip_reward = drip_pool_balance * (1 - (1 - drip_rate_per_day) ^ days_ellapsed)
				uint64 _days = _today - day;
				uint256 _rate = 100e16 - _exp(100e16 - _ratePerDay, _days);
				uint256 _amount = (totalDrip - allocDrip) * _rate / 100e16;

				uint256 _amountDrip = _amount * dripRatePerDay / _ratePerDay;
				if (totalStaked > 0) {
					accDripPerShare += _amountDrip * 1e18 / totalStaked;
					allocDrip += _amountDrip;
				}

				uint256 _amountBoost = _amount - _amountDrip;
				if (totalBurned > 0) {
					accBoostPerShare += _amountBoost * 1e18 / totalBurned;
					totalDrip -= _amountBoost;
					totalBoost += _amountBoost;
				}
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
		_accountInfo.drip += _accountInfo.amount * accDripPerShare / 1e18 - _accountInfo.accDripDebt;
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
		_accountInfo.accDripDebt = _accountInfo.amount * accDripPerShare / 1e18;
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

	event Burn(address indexed _account, address indexed _boostToken, uint256 _amount);
	event Deposit(address indexed _account, address indexed _reserveToken, uint256 _amount);
	event Withdraw(address indexed _account, address indexed _reserveToken, uint256 _amount);
	event Claim(address indexed _account, address indexed _rewardToken, uint256 _amount);
	event Compound(address indexed _account, address indexed _rewardToken, uint256 _amount);
	event Reward(address indexed _account, address indexed _rewardToken, uint256 _amount);
	event RewardAll(address indexed _account, address indexed _rewardToken, uint256 _amount);
}