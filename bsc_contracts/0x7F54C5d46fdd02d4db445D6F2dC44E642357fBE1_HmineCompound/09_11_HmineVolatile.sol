// SPDX-License-Identifier: UNLICENSED
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
 1% HMINE Bankroll
 1% Burnt
 Does not receive BUSD daily but does receive 1% of all HMINE deposited into COMPOUND VDC
 */
contract HmineVolatile is Initializable, Ownable, ReentrancyGuard
{
	using SafeERC20 for IERC20;

	struct AccountInfo {
		uint256 amount; // xHMINE staked
		uint256 reward; // xHMINE reward from Volatile VDC accumulated but not claimed
		uint256 drip; // xHMINE from drip pool accumulated but not claimed
		uint256 accRewardDebt; // xHMINE reward debt from PCS distribution algorithm
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
	address public rewardToken; // xHMINE

	address public bankroll = DEFAULT_BANKROLL;

	uint256 public dripRatePerDay = DEFAULT_DRIP_RATE_PER_DAY;

	bool public whitelistAll = false;

	uint256 public totalStaked = 0; // total staked balance

	uint256 public totalDrip = 0; // total drip pool balance
	uint256 public allocDrip = 0; // total drip pool balance allocated

	uint256 public totalReward = 0; // total reward balance

	uint256 public accRewardPerShare = 0; // cumulative reward xHMINE per xHMINE staked from PCS distribution algorithm
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

	constructor(address _hmineToken)
	{
		initialize(msg.sender, _hmineToken);
	}

	function initialize(address _owner, address _hmineToken) public initializer
	{
		_transferOwnership(_owner);

		bankroll = DEFAULT_BANKROLL;

		dripRatePerDay = DEFAULT_DRIP_RATE_PER_DAY;

		whitelistAll = false;

		totalStaked = 0; // total staked balance

		totalDrip = 0; // total drip pool balance
		allocDrip = 0; // total drip pool balance allocated

		totalReward = 0; // total reward balance

		accRewardPerShare = 0; // cumulative reward xHMINE per xHMINE staked from PCS distribution algorithm
		accDripPerShare = 0; // cumulative drip pool xHMINE per xHMINE staked from PCS distribution algorithm

		day = today();

		migrated = false;

		hmineToken = _hmineToken;
		rewardToken = _hmineToken;
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
		IERC20(hmineToken).safeTransferFrom(msg.sender, address(this), totalStaked + totalDrip + totalReward);
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
		if (_token == hmineToken) _amount -= totalStaked + totalDrip + totalReward;
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
		uint256 _dripAmount = 31 * _1percent;
		uint256 _netAmount = _amount - (33 * _1percent);

		// 31% accounted for the drip pool
		totalDrip += _dripAmount;

		// 1% instant rewards (only 30% actually go to the drip pool)
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
			IERC20(hmineToken).safeTransferFrom(_sender, address(this), _netAmount + _dripAmount);
			IERC20(hmineToken).safeTransferFrom(_sender, FURNACE, _1percent);
			IERC20(hmineToken).safeTransferFrom(_sender, bankroll, _1percent);
		}
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
			uint256 _dripAmount = 31 * _1percent;
			uint256 _netAmount = _amount - (33 * _1percent);

			// 31% accounted for the drip pool
			totalDrip += _dripAmount;

			// 1% instant rewards (only 30% actually go to the drip pool)
			if (totalStaked > 0) {
				accDripPerShare += _1percent * 1e18 / totalStaked;
				allocDrip += _1percent;
			}

			IERC20(hmineToken).safeTransfer(FURNACE, _1percent);
			IERC20(hmineToken).safeTransfer(bankroll, _1percent);

			IERC20(hmineToken).safeTransfer(msg.sender, _netAmount);
		}

		emit Withdraw(msg.sender, hmineToken, _amount);
	}

	// claims rewards only (xHMINE)
	function claimReward() external nonReentrant returns (uint256 _rewardAmount)
	{
		_updateDay();

		_updateAccount(msg.sender, 0);

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

	// claims all (xHMINE)
	function claimAll() external nonReentrant returns (uint256 _rewardAmount, uint256 _dripAmount)
	{
		_updateDay();

		_updateAccount(msg.sender, 0);

		AccountInfo storage _accountInfo = accountInfo[msg.sender];

		_rewardAmount = _accountInfo.reward;
		_dripAmount = _accountInfo.drip;

		if (_rewardAmount > 0) {
			_accountInfo.reward = 0;

			totalReward -= _rewardAmount;
		}

		if (_dripAmount > 0) {
			_accountInfo.drip = 0;

			totalDrip -= _dripAmount;
			allocDrip -= _dripAmount;
		}

		uint256 _rewardPlusDripAmount = _rewardAmount + _dripAmount;
		if (_rewardPlusDripAmount > 0) {
			IERC20(hmineToken).safeTransfer(msg.sender, _rewardPlusDripAmount);
		}

		emit Claim(msg.sender, rewardToken, _rewardAmount);
		emit Claim(msg.sender, hmineToken, _dripAmount);

		return (_rewardAmount, _dripAmount);
	}

	// compounds rewards only (xHMINE)
	function compoundReward() external nonReentrant
	{
		_updateDay();

		_updateAccount(msg.sender, 0);

		AccountInfo storage _accountInfo = accountInfo[msg.sender];

		uint256 _rewardAmount = _accountInfo.reward;

		if (_rewardAmount > 0) {
			_accountInfo.reward = 0;

			totalReward -= _rewardAmount;

			_deposit(address(this), _rewardAmount, msg.sender);
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

	// compounds all (xHMINE)
	function compoundAll() external nonReentrant
	{
		_updateDay();

		_updateAccount(msg.sender, 0);

		AccountInfo storage _accountInfo = accountInfo[msg.sender];

		uint256 _rewardAmount = _accountInfo.reward;
		uint256 _dripAmount = _accountInfo.drip;

		if (_rewardAmount > 0) {
			_accountInfo.reward = 0;

			totalReward -= _rewardAmount;
		}

		if (_dripAmount > 0) {
			_accountInfo.drip = 0;

			totalDrip -= _dripAmount;
			allocDrip -= _dripAmount;
		}

		uint256 _rewardPlusDripAmount = _rewardAmount + _dripAmount;
		if (_rewardPlusDripAmount > 0) {
			_deposit(address(this), _rewardPlusDripAmount, msg.sender);
		}

		emit Compound(msg.sender, rewardToken, _rewardAmount);
		emit Compound(msg.sender, hmineToken, _dripAmount);
	}

	// sends xHMINE to a set of accounts
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

	// sends xHMINE to all stakers
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

	// performs the daily distribution the drip pool (xHMINE)
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