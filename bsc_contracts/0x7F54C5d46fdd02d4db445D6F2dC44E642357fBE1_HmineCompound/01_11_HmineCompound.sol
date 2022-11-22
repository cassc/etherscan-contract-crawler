// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Initializable } from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import { HmineMain1 } from "./HmineMain1.sol";
import { HmineMain2 } from "./HmineMain2.sol";
import { HmineVolatile } from "./HmineVolatile.sol";

/*
 Compound VDC fees are 11% in and 11% out, they are distributed in the following way:
 7% to drip pool
 1% Instant dividends to stakers
 1% HMINE Bankroll
 1% Burnt
 1% Volatile VDC
 Receives BUSD daily from HMINE staking
 */
contract HmineCompound is Initializable, Ownable, ReentrancyGuard
{
	using SafeERC20 for IERC20;

	struct AccountInfo {
		uint256 amount; // xHMINE staked
		uint256 reward; // BUSD reward accumulated but not claimed
		uint256 drip; // xHMINE from drip pool accumulated but not claimed
		uint256 accRewardDebt; // BUSD reward debt from PCS distribution algorithm
		uint256 accDripDebt; // xHMINE reward debt from PCS distribution algorithm
		bool whitelisted; // flag indicating whether or not account pays withdraw penalties
		bool exists; // flag to index account
	}

	address constant FURNACE = 0x000000000000000000000000000000000000dEaD;

	address constant DEFAULT_BANKROLL = 0x25be1fcF5F51c418a0C30357a4e8371dB9cf9369; // multisig

	uint256 constant DEFAULT_DRIP_RATE_PER_DAY = 1e16; // 1% per day

	uint256 constant DAY = 1 days;
	uint256 constant TZ_OFFSET = 22 hours + 30 minutes; // UTC-1.30
	uint256 constant LAUNCH_TIME = 1660845600; // 2022-08-18 6PM UTC

	address public hmineToken; // xHMINE
	address public rewardToken; // BUSD

	address public hmineMain1;
	address public hmineMain2;
	address public hmineVolatile;

	address public bankroll = DEFAULT_BANKROLL;

	uint256 public dripRatePerDay = DEFAULT_DRIP_RATE_PER_DAY;

	bool public whitelistAll = false;

	uint256 public totalStaked = 0; // total staked balance

	uint256 public totalDrip = 0; // total drip pool balance
	uint256 public allocDrip = 0; // total drip pool balance allocated

	uint256 public totalReward = 0; // total reward balance

	uint256 public accRewardPerShare = 0; // cumulative reward BUSD per xHMINE staked from PCS distribution algorithm
	uint256 public accDripPerShare = 0; // cumulative drip pool xHMINE per xHMINE staked from PCS distribution algorithm

	uint64 public day = today();

	address[] public accountIndex;
	mapping(address => AccountInfo) public accountInfo;

	bool public migrated = false;

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
		require(block.timestamp >= LAUNCH_TIME, "unavailable");
		_;
	}

	constructor(address _hmineToken, address _rewardToken, address _hmineMain1, address _hmineMain2, address _hmineVolatile)
	{
		initialize(msg.sender, _hmineToken, _rewardToken, _hmineMain1, _hmineMain2, _hmineVolatile);
	}

	function initialize(address _owner, address _hmineToken, address _rewardToken, address _hmineMain1, address _hmineMain2, address _hmineVolatile) public initializer
	{
		_transferOwnership(_owner);

		bankroll = DEFAULT_BANKROLL;

		dripRatePerDay = DEFAULT_DRIP_RATE_PER_DAY;

		whitelistAll = false;

		totalStaked = 0; // total staked balance

		totalDrip = 0; // total drip pool balance
		allocDrip = 0; // total drip pool balance allocated

		totalReward = 0; // total reward balance

		accRewardPerShare = 0; // cumulative reward BUSD per xHMINE staked from PCS distribution algorithm
		accDripPerShare = 0; // cumulative drip pool xHMINE per xHMINE staked from PCS distribution algorithm

		day = today();

		migrated = false;

		require(_rewardToken != _hmineToken, "invalid token");
		hmineToken = _hmineToken;
		rewardToken = _rewardToken;
		hmineMain1 = _hmineMain1;
		hmineMain2 = _hmineMain2;
		hmineVolatile = _hmineVolatile;
	}

	function migrate(uint256 _totalStaked, uint256 _totalDrip, uint256 _allocDrip, uint256 _totalReward, uint256 _accRewardPerShare, uint256 _accDripPerShare, address[] calldata _accounts, AccountInfo[] calldata _accountInfo) external onlyOwner nonReentrant
	{
		require(_accounts.length == _accountInfo.length, "lenght mismatch");
		require(!migrated, "unavailable");
		migrated = true;
		totalStaked = _totalStaked;
		totalDrip = _totalDrip;
		allocDrip = _allocDrip;
		totalReward = _totalReward;
		accRewardPerShare = _accRewardPerShare;
		accDripPerShare = _accDripPerShare;
		for (uint256 _i = 0; _i < _accounts.length; _i++) {
			address _account = _accounts[_i];
			accountIndex.push(_account);
			accountInfo[_account] = _accountInfo[_i];
		}
		IERC20(hmineToken).safeTransferFrom(msg.sender, address(this), totalStaked + totalDrip);
		IERC20(rewardToken).safeTransferFrom(msg.sender, address(this), totalReward);
	}

	// updates the xHMINE main exchange contract
	function setHmineMain1(address _hmineMain1) external onlyOwner
	{
		require(_hmineMain1 != address(0), "invalid address");
		hmineMain1 = _hmineMain1;
	}

	// updates the xHMINE main staking contract
	function setHmineMain2(address _hmineMain2) external onlyOwner
	{
		require(_hmineMain2 != address(0), "invalid address");
		hmineMain2 = _hmineMain2;
	}

	// updates the volatile vdc address
	function setHmineVolatile(address _hmineVolatile) external onlyOwner
	{
		require(_hmineVolatile != address(0), "invalid address");
		hmineVolatile = _hmineVolatile;
	}

	// updates the bankroll address
	function setBankroll(address _bankroll) external onlyOwner
	{
		require(_bankroll != address(0), "invalid address");
		bankroll = _bankroll;
	}

	// updates the percentual rate of distribution from the drip pool
	function setDripRatePerDay(uint256 _dripRatePerDay) external onlyOwner
	{
		require(_dripRatePerDay <= 100e16, "invalid rate");
		dripRatePerDay = _dripRatePerDay;
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
		if (_token == hmineToken) _amount -= totalStaked + totalDrip;
		require(_amount > 0, "no balance");
		IERC20(_token).safeTransfer(msg.sender, _amount);
	}

	// stakes xHMINE
	function deposit(uint256 _amount) external hasLaunched nonReentrant
	{
		_deposit(msg.sender, _amount, msg.sender);

		emit Deposit(msg.sender, hmineToken, _amount);
	}

	// stakes xHMINE on behalf of another account
	function depositOnBehalfOf(uint256 _amount, address _account) external hasLaunched nonReentrant
	{
		_deposit(msg.sender, _amount, _account);

		emit Deposit(_account, hmineToken, _amount);
	}

	function _deposit(address _sender, uint256 _amount, address _account) internal
	{
		require(_amount > 0, "invalid amount");

		_updateDay();

		uint256 _1percent = _amount * 1e16 / 100e16;
		uint256 _dripAmount = 8 * _1percent;
		uint256 _netAmount = _amount - (11 * _1percent);

		// 8% accounted for the drip pool
		totalDrip += _dripAmount;

		// 1% instant rewards (only 7% actually go to the drip pool)
		if (totalStaked > 0) {
			accDripPerShare += _1percent * 1e18 / totalStaked;
			allocDrip += _1percent;
		}

		_updateAccount(_account, int256(_netAmount));

		totalStaked += _netAmount;

		if (_sender == address(this)) {
			IERC20(hmineToken).safeTransfer(FURNACE, _1percent);
			IERC20(hmineToken).safeTransfer(bankroll, _1percent);
		} else {
			IERC20(hmineToken).safeTransferFrom(_sender, address(this), _netAmount + _dripAmount + _1percent);
			IERC20(hmineToken).safeTransferFrom(_sender, FURNACE, _1percent);
			IERC20(hmineToken).safeTransferFrom(_sender, bankroll, _1percent);
		}

		// rewards Volatile VDC users
		IERC20(hmineToken).safeApprove(hmineVolatile, _1percent);
		HmineVolatile(hmineVolatile).rewardAll(_1percent);
	}

	// unstakes xHMINE
	function withdraw(uint256 _amount) external nonReentrant
	{
		require(_amount > 0, "invalid amount");

		AccountInfo storage _accountInfo = accountInfo[msg.sender];
		require(_amount <= _accountInfo.amount, "insufficient balance");

		_updateDay();

		_updateAccount(msg.sender, -int256(_amount));

		totalStaked -= _amount;

		if (_accountInfo.whitelisted || whitelistAll) {
			IERC20(hmineToken).safeTransfer(msg.sender, _amount);
		} else {
			uint256 _1percent = _amount * 1e16 / 100e16;
			uint256 _dripAmount = 8 * _1percent;
			uint256 _netAmount = _amount - (11 * _1percent);

			// 8% accounted for the drip pool
			totalDrip += _dripAmount;

			// 1% instant rewards (only 7% actually go to the drip pool)
			if (totalStaked > 0) {
				accDripPerShare += _1percent * 1e18 / totalStaked;
				allocDrip += _1percent;
			}

			IERC20(hmineToken).safeTransfer(FURNACE, _1percent);
			IERC20(hmineToken).safeTransfer(bankroll, _1percent);

			// rewards Volatile VDC users
			IERC20(hmineToken).safeApprove(hmineVolatile, _1percent);
			HmineVolatile(hmineVolatile).rewardAll(_1percent);

			IERC20(hmineToken).safeTransfer(msg.sender, _netAmount);
		}

		emit Withdraw(msg.sender, hmineToken, _amount);
	}

	// claims rewards only (BUSD)
	function claimReward() external nonReentrant returns (uint256 _rewardAmount)
	{
		_updateDay();

		_updateAccount(msg.sender, 0);

		AccountInfo storage _accountInfo = accountInfo[msg.sender];

		_rewardAmount = _accountInfo.reward;

		if (_rewardAmount > 0) {
			_accountInfo.reward = 0;

			uint256 _5percent = _rewardAmount * 5e16 / 100e16;
			uint256 _feeRewardAmount = 5 * _5percent;
			uint256 _netRewardAmount = _rewardAmount - _feeRewardAmount;

			if (totalStaked > 0) {
				_feeRewardAmount -= _5percent;

				accRewardPerShare += _5percent * 1e18 / totalStaked;
			}

			totalReward -= _feeRewardAmount + _netRewardAmount;

			IERC20(rewardToken).safeTransfer(bankroll, _feeRewardAmount);
			IERC20(rewardToken).safeTransfer(msg.sender, _netRewardAmount);
		}

		emit Claim(msg.sender, rewardToken, _rewardAmount);

		return _rewardAmount;
	}

	// claims drip only (xHMINE)
	function claimDrip() external nonReentrant returns (uint256 _dripAmount)
	{
		_updateDay();

		_updateAccount(msg.sender, 0);

		AccountInfo storage _accountInfo = accountInfo[msg.sender];

		_dripAmount = _accountInfo.drip;

		if (_dripAmount > 0) {
			_accountInfo.drip = 0;

			totalDrip -= _dripAmount;
			allocDrip -= _dripAmount;

			IERC20(hmineToken).safeTransfer(msg.sender, _dripAmount);
		}

		emit Claim(msg.sender, hmineToken, _dripAmount);

		return _dripAmount;
	}

	// claims all (BUSD and xHMINE)
	function claimAll() external nonReentrant returns (uint256 _rewardAmount, uint256 _dripAmount)
	{
		_updateDay();

		_updateAccount(msg.sender, 0);

		AccountInfo storage _accountInfo = accountInfo[msg.sender];

		_rewardAmount = _accountInfo.reward;
		_dripAmount = _accountInfo.drip;

		if (_rewardAmount > 0) {
			_accountInfo.reward = 0;

			uint256 _5percent = _rewardAmount * 5e16 / 100e16;
			uint256 _feeRewardAmount = 5 * _5percent;
			uint256 _netRewardAmount = _rewardAmount - _feeRewardAmount;

			if (totalStaked > 0) {
				_feeRewardAmount -= _5percent;

				accRewardPerShare += _5percent * 1e18 / totalStaked;
			}

			totalReward -= _feeRewardAmount + _netRewardAmount;

			IERC20(rewardToken).safeTransfer(bankroll, _feeRewardAmount);
			IERC20(rewardToken).safeTransfer(msg.sender, _netRewardAmount);
		}

		if (_dripAmount > 0) {
			_accountInfo.drip = 0;

			totalDrip -= _dripAmount;
			allocDrip -= _dripAmount;

			IERC20(hmineToken).safeTransfer(msg.sender, _dripAmount);
		}

		emit Claim(msg.sender, rewardToken, _rewardAmount);
		emit Claim(msg.sender, hmineToken, _dripAmount);

		return (_rewardAmount, _dripAmount);
	}

	// compounds rewards only (BUSD)
	function compoundReward() external nonReentrant
	{
		_updateDay();

		_updateAccount(msg.sender, 0);

		AccountInfo storage _accountInfo = accountInfo[msg.sender];

		uint256 _rewardAmount = _accountInfo.reward;

		if (_rewardAmount > 0) {
			_accountInfo.reward = 0;

			totalReward -= _rewardAmount;

			IERC20(rewardToken).approve(hmineMain1, _rewardAmount);
			uint256 _convertedRewardAmount = HmineMain1(hmineMain1).buy(_rewardAmount);

			(,,,,,,bool _whitelisted) = HmineMain2(hmineMain2).accountInfo(address(this));
			require(_whitelisted, "not whitelisted");
			HmineMain2(hmineMain2).withdraw(_convertedRewardAmount);

			_deposit(address(this), _convertedRewardAmount, msg.sender);
		}

		emit Compound(msg.sender, rewardToken, _rewardAmount);
	}

	// compounds drip only (xHMINE)
	function compoundDrip() external nonReentrant
	{
		_updateDay();

		_updateAccount(msg.sender, 0);

		AccountInfo storage _accountInfo = accountInfo[msg.sender];

		uint256 _dripAmount = _accountInfo.drip;

		if (_dripAmount > 0) {
			_accountInfo.drip = 0;

			totalDrip -= _dripAmount;
			allocDrip -= _dripAmount;

			_deposit(address(this), _dripAmount, msg.sender);
		}

		emit Compound(msg.sender, hmineToken, _dripAmount);
	}

	// compounds all (BUSD and xHMINE)
	function compoundAll() external nonReentrant
	{
		_updateDay();

		_updateAccount(msg.sender, 0);

		AccountInfo storage _accountInfo = accountInfo[msg.sender];

		uint256 _rewardAmount = _accountInfo.reward;
		uint256 _dripAmount = _accountInfo.drip;

		uint256 _convertedRewardAmount = 0;
		if (_rewardAmount > 0) {
			_accountInfo.reward = 0;

			totalReward -= _rewardAmount;

			IERC20(rewardToken).approve(hmineMain1, _rewardAmount);
			_convertedRewardAmount = HmineMain1(hmineMain1).buy(_rewardAmount);

			(,,,,,,bool _whitelisted) = HmineMain2(hmineMain2).accountInfo(address(this));
			require(_whitelisted, "not whitelisted");
			HmineMain2(hmineMain2).withdraw(_convertedRewardAmount);
		}

		if (_dripAmount > 0) {
			_accountInfo.drip = 0;

			totalDrip -= _dripAmount;
			allocDrip -= _dripAmount;
		}

		uint256 _convertedRewardPlusDripAmount = _convertedRewardAmount + _dripAmount;
		if (_convertedRewardPlusDripAmount > 0) {
			_deposit(address(this), _convertedRewardPlusDripAmount, msg.sender);
		}

		emit Compound(msg.sender, rewardToken, _rewardAmount);
		emit Compound(msg.sender, hmineToken, _dripAmount);
	}

	// sends BUSD to a set of accounts
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

	// sends BUSD to all stakers
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

	// performs the daily distribution from staking (BUSD) and the drip pool (xHMINE)
	function updateDay() external nonReentrant
	{
		_updateDay();
	}

	function _updateDay() internal
	{
		uint64 _today = today();

		if (day == _today) return;

		if (totalStaked > 0) {
			// calculates the percentage of the drip pool and distributes
			{
				// formula: drip_reward = drip_pool_balance * (1 - (1 - drip_rate_per_day) ^ days_ellapsed)
				uint64 _days = _today - day;
				uint256 _rate = 100e16 - _exp(100e16 - dripRatePerDay, _days);
				uint256 _amount = (totalDrip - allocDrip) * _rate / 100e16;
				accDripPerShare += _amount * 1e18 / totalStaked;
				allocDrip += _amount;
			}
		}

		day = _today;
	}

	// updates the account balances while accumulating reward/drip using PCS distribution algorithm
	function _updateAccount(address _account, int256 _amount) internal
	{
		AccountInfo storage _accountInfo = accountInfo[_account];
		if (!_accountInfo.exists) {
			// adds account to index
			_accountInfo.exists = true;
			accountIndex.push(_account);
		}

		_accountInfo.reward += _accountInfo.amount * accRewardPerShare / 1e18 - _accountInfo.accRewardDebt;
		_accountInfo.drip += _accountInfo.amount * accDripPerShare / 1e18 - _accountInfo.accDripDebt;
		if (_amount > 0) {
			_accountInfo.amount += uint256(_amount);
		}
		else
		if (_amount < 0) {
			_accountInfo.amount -= uint256(-_amount);
		}
		_accountInfo.accRewardDebt = _accountInfo.amount * accRewardPerShare / 1e18;
		_accountInfo.accDripDebt = _accountInfo.amount * accDripPerShare / 1e18;
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

	event Deposit(address indexed _account, address indexed _hmineToken, uint256 _amount);
	event Withdraw(address indexed _account, address indexed _hmineToken, uint256 _amount);
	event Claim(address indexed _account, address indexed _rewardToken, uint256 _amount);
	event Compound(address indexed _account, address indexed _rewardToken, uint256 _amount);
	event Reward(address indexed _account, address indexed _rewardToken, uint256 _amount);
	event RewardAll(address indexed _account, address indexed _rewardToken, uint256 _amount);
}