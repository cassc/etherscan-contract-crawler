// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Initializable } from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";

contract HmineMain2 is Initializable, Ownable, ReentrancyGuard
{
	using Address for address;
	using SafeERC20 for IERC20;

	struct AccountInfo {
		string nickname; // user nickname
		uint256 amount; // xHMINE staked
		uint256 reward; // BUSD reward accumulated but not claimed
		uint256 accRewardDebt; // BUSD reward debt from PCS distribution algorithm
		uint16 period; // user selected grace period for expirations
		uint64 day; // the day index of the last user interaction
		bool whitelisted; // flag indicating whether or not account pays withdraw penalties
	}

	struct PeriodInfo {
		uint256 amount; // total amount staked for a given period
		uint256 fee; // the period percentual fee
		bool available; // whether or not the period is valid/available
		mapping(uint64 => DayInfo) dayInfo; // period info per day
	}

	struct DayInfo {
		uint256 accRewardPerShare; // BUSD reward debt from PCS distribution algorithm for a given period/day
		uint256 expiringReward; // BUSD reward to expire for a given period/day
	}

	address constant FURNACE = 0x000000000000000000000000000000000000dEaD;

	address constant DEFAULT_BANKROLL = 0x25be1fcF5F51c418a0C30357a4e8371dB9cf9369; // multisig
	address constant DEFAULT_BUYBACK = 0x7674D2a14076e8af53AC4ba9bBCf0c19FeBe8899;

	uint256 constant DAY = 1 days;
	uint256 constant TZ_OFFSET = 23 hours; // UTC-1

	address public hmineToken; // xHMINE
	address public rewardToken; // BUSD
	address public hmineMain1;

	address public bankroll = DEFAULT_BANKROLL;
	address public buyback = DEFAULT_BUYBACK;

	bool public whitelistAll = false;

	uint256 public totalStaked = 0; // total staked balance
	uint256 public totalReward = 0; // total reward balance

	uint64 public day = today();

	uint16[] public periodIndex;
	mapping(uint16 => PeriodInfo) public periodInfo;

	address[] public accountIndex;
	mapping(address => AccountInfo) public accountInfo;
	mapping(address => mapping(uint64 => uint256)) public bonus; // bonus per account/day

	bool public migrated = false;

	function periodIndexLength() external view returns (uint256 _length)
	{
		return periodIndex.length;
	}

	function accountIndexLength() external view returns (uint256 _length)
	{
		return accountIndex.length;
	}

	function getAccountByIndex(uint256 _index) external view returns (AccountInfo memory _accountInfo)
	{
		return accountInfo[accountIndex[_index]];
	}

	function dayInfo(uint16 _period, uint64 _day) external view returns (DayInfo memory _dayInfo)
	{
		return periodInfo[_period].dayInfo[_day];
	}

	function today() public view returns (uint64 _today)
	{
		return uint64((block.timestamp + TZ_OFFSET) / DAY);
	}

	constructor(address _hmineToken, address _rewardToken, address _hmineMain1)
	{
		initialize(msg.sender, _hmineToken, _rewardToken, _hmineMain1);
	}

	function initialize(address _owner, address _hmineToken, address _rewardToken, address _hmineMain1) public initializer
	{
		_transferOwnership(_owner);

		bankroll = DEFAULT_BANKROLL;
		buyback = DEFAULT_BUYBACK;

		whitelistAll = false;

		totalStaked = 0; // total staked balance
		totalReward = 0; // total reward balance

		day = today();

		migrated = false;

		require(_rewardToken != _hmineToken, "invalid token");
		hmineToken = _hmineToken;
		rewardToken = _rewardToken;
		hmineMain1 = _hmineMain1;

		periodIndex.push(1); periodInfo[1].fee = 0e16; periodInfo[1].available = true;
		periodIndex.push(2); periodInfo[2].fee = 10e16; periodInfo[2].available = true;
		periodIndex.push(4); periodInfo[4].fee = 15e16; periodInfo[4].available = true;
		periodIndex.push(7); periodInfo[7].fee = 20e16; periodInfo[7].available = true;
		periodIndex.push(30); periodInfo[30].fee = 50e16; periodInfo[30].available = true;
	}

	function migrate(uint256 _totalStaked, uint256 _totalReward, uint256[] calldata _periodAmounts, address[] calldata _accounts, AccountInfo[] calldata _accountInfo) external onlyOwner nonReentrant
	{
		require(_accounts.length == _accountInfo.length, "lenght mismatch");
		require(!migrated, "unavailable");
		migrated = true;
		totalStaked = _totalStaked;
		totalReward = _totalReward;
		for (uint256 _i = 0; _i < periodIndex.length; _i++) {
			uint16 _period = periodIndex[_i];
			periodInfo[_period].amount = _periodAmounts[_i];
		}
		for (uint256 _i = 0; _i < _accounts.length; _i++) {
			address _account = _accounts[_i];
			accountIndex.push(_account);
			accountInfo[_account] = _accountInfo[_i];
		}
		IERC20(hmineToken).safeTransferFrom(msg.sender, address(this), totalStaked);
		IERC20(rewardToken).safeTransferFrom(msg.sender, address(this), totalReward);
	}

	// updates the bankroll address
	function setBankroll(address _bankroll) external onlyOwner
	{
		require(_bankroll != address(0), "invalid address");
		bankroll = _bankroll;
	}

	// updates the buyback address
	function setBuyback(address _buyback) external onlyOwner
	{
		require(_buyback != address(0), "invalid address");
		buyback = _buyback;
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
		if (_token == hmineToken) _amount -= totalStaked;
		else
		if (_token == rewardToken) _amount -= totalReward;
		if (_amount > 0) {
			IERC20(_token).safeTransfer(msg.sender, _amount);
		}
	}

	// updates account nickname
	function updateNickname(string calldata _nickname) external
	{
		AccountInfo storage _accountInfo = accountInfo[msg.sender];
		require(_accountInfo.period != 0, "unknown account");
		_accountInfo.nickname = _nickname;
	}

	// updates account period
	function updatePeriod(address _account, uint16 _newPeriod) external nonReentrant
	{
		PeriodInfo storage _periodInfo = periodInfo[_newPeriod];
		require(_periodInfo.available, "unavailable");
		require(msg.sender == _account || msg.sender == owner() && _account.isContract(), "access denied");

		_updateDay();

		_updateAccount(_account, 0);

		AccountInfo storage _accountInfo = accountInfo[_account];
		uint16 _oldPeriod = _accountInfo.period;
		require(_newPeriod != _oldPeriod, "no change");

		periodInfo[_oldPeriod].amount -= _accountInfo.amount;
		_periodInfo.amount += _accountInfo.amount;

		DayInfo storage _dayInfo = _periodInfo.dayInfo[day];
		_accountInfo.accRewardDebt = _accountInfo.amount * _dayInfo.accRewardPerShare / 1e18;
		_accountInfo.period = _newPeriod;
	}

	// stakes xHMINE
	function deposit(uint256 _amount) external
	{
		depositOnBehalfOf(_amount, msg.sender);
	}

	// stakes xHMINE on behalf of another account
	function depositOnBehalfOf(uint256 _amount, address _account) public nonReentrant
	{
		require(_amount > 0, "invalid amount");

		_updateDay();

		_updateAccount(_account, int256(_amount));

		totalStaked += _amount;

		IERC20(hmineToken).safeTransferFrom(msg.sender, address(this), _amount);

		emit Deposit(_account, hmineToken, _amount);
	}

	// unstakes xHMINE
	function withdraw(uint256 _amount) external
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
			uint256 _10percent = _amount * 10e16 / 100e16;
			uint256 _netAmount = _amount - 2 * _10percent;
			IERC20(hmineToken).safeTransfer(FURNACE, _10percent);
			IERC20(hmineToken).safeTransfer(bankroll, _10percent);
			IERC20(hmineToken).safeTransfer(msg.sender, _netAmount);
		}

		emit Withdraw(msg.sender, hmineToken, _amount);
	}

	// claims BUSD rewards
	function claim() external returns (uint256 _amount)
	{
		return claimOnBehalfOf(msg.sender);
	}

	// claims BUSD rewards on behalf of a given user (available only to HmineMain1)
	function claimOnBehalfOf(address _account) public nonReentrant returns (uint256 _amount)
	{
		require(msg.sender == _account || msg.sender == hmineMain1, "access denied");

		_updateDay();

		_updateAccount(_account, 0);

		AccountInfo storage _accountInfo = accountInfo[_account];
		_amount = _accountInfo.reward;

		if (_amount > 0) {
			_accountInfo.reward = 0;

			uint256 _5percent = _amount * 5e16 / 100e16;
			uint256 _feeAmount = 5 * _5percent;
			uint256 _netAmount = _amount - _feeAmount;

			if (totalStaked > 0) {
				_feeAmount -= _5percent;

				for (uint256 _i = 0; _i < periodIndex.length; _i++) {
					uint16 _period = periodIndex[_i];
					PeriodInfo storage _periodInfo = periodInfo[_period];

					// splits proportionally by period
					uint256 _subamount = _5percent * _periodInfo.amount / totalStaked;
					if (_subamount == 0) continue;

					// rewards according to stake using PCS distribution algorithm
					DayInfo storage _dayInfo = _periodInfo.dayInfo[day];
					_dayInfo.accRewardPerShare += _subamount * 1e18 / _periodInfo.amount;
					_dayInfo.expiringReward += _subamount;
				}
			}

			totalReward -= _feeAmount + _netAmount;

			IERC20(rewardToken).safeTransfer(bankroll, _feeAmount);
			IERC20(rewardToken).safeTransfer(msg.sender, _netAmount);
		}

		emit Claim(_account, rewardToken, _amount);

		return _amount;
	}

	// sends BUSD to a set of accounts
	function reward(address[] calldata _accounts, uint256[] calldata _amounts) external nonReentrant
	{
		require(_accounts.length == _amounts.length, "lenght mismatch");

		_updateDay();

		uint256 _amount = 0;

		for (uint256 _i = 0; _i < _accounts.length; _i++) {
			address _account = _accounts[_i];
			uint256 _subamount = _amounts[_i];

			AccountInfo storage _accountInfo = accountInfo[_account];
			uint16 _period = _accountInfo.period;
			require(_period != 0, "invalid account");

			PeriodInfo storage _periodInfo = periodInfo[_period];
			DayInfo storage _dayInfo = _periodInfo.dayInfo[day];

			bonus[_account][day] += _subamount;

			_dayInfo.expiringReward += _subamount;

			emit Reward(_account, rewardToken, _subamount);

			_amount += _subamount;
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

		for (uint256 _i = 0; _i < periodIndex.length; _i++) {
			uint16 _period = periodIndex[_i];
			PeriodInfo storage _periodInfo = periodInfo[_period];

			// splits proportionally by period
			uint256 _subamount = _amount * _periodInfo.amount / totalStaked;
			if (_subamount == 0) continue;

			// rewards according to stake using PCS distribution algorithm
			DayInfo storage _dayInfo = _periodInfo.dayInfo[day];
			_dayInfo.accRewardPerShare += _subamount * 1e18 / _periodInfo.amount;
			_dayInfo.expiringReward += _subamount;
		}

		totalReward += _amount;

		IERC20(rewardToken).safeTransferFrom(msg.sender, address(this), _amount);

		emit RewardAll(msg.sender, rewardToken, _amount);
	}

	// sends BUSD to the top 20 stakers (list computed off-chain)
	function sendBonusDiv(uint256 _amount, address[] memory _topTen, address[] memory _topTwenty) external nonReentrant
	{
		require(_amount > 0, "invalid amount");
		require(_topTen.length == 10 && _topTwenty.length == 10, "invalid length");

		_updateDay();

		uint256 _topTenAmount = (_amount * 75e16 / 100e16) / _topTen.length;

		for (uint256 _i = 0; _i < _topTen.length; _i++) {
			address _account = _topTen[_i];
			AccountInfo storage _accountInfo = accountInfo[_account];
			uint16 _period = _accountInfo.period;
			require(_period != 0, "invalid account");

			PeriodInfo storage _periodInfo = periodInfo[_period];
			DayInfo storage _dayInfo = _periodInfo.dayInfo[day];

			bonus[_account][day] += _topTenAmount;

			_dayInfo.expiringReward += _topTenAmount;

			emit Reward(_account, rewardToken, _topTenAmount);
		}

		uint256 _topTwentyAmount = (_amount * 25e16 / 100e16) / _topTwenty.length;

		for (uint256 _i = 0; _i < _topTwenty.length; _i++) {
			address _account = _topTwenty[_i];
			AccountInfo storage _accountInfo = accountInfo[_account];
			uint16 _period = _accountInfo.period;
			require(_period != 0, "invalid account");

			PeriodInfo storage _periodInfo = periodInfo[_period];
			DayInfo storage _dayInfo = _periodInfo.dayInfo[day];

			bonus[_account][day] += _topTwentyAmount;

			_dayInfo.expiringReward += _topTwentyAmount;

			emit Reward(_account, rewardToken, _topTwentyAmount);
		}

		totalReward += _amount;

		IERC20(rewardToken).safeTransferFrom(msg.sender, address(this), _amount);
	}

	// performs the daily expiration of rewards from staking (BUSD)
	function updateDay() external nonReentrant
	{
		_updateDay();
	}

	// updates the user account as if he had interacted with this contract (available only to HmineMain1)
	function updateAccount(address _account) external nonReentrant
	{
		require(msg.sender == hmineMain1, "access denied");

		_updateDay();

		_updateAccount(_account, 0);
	}

	function _updateDay() internal
	{
		uint64 _today = today();

		if (day == _today) return;

		uint256 _amount = 0;

		for (uint256 _i = 0; _i < periodIndex.length; _i++) {
			uint16 _period = periodIndex[_i];
			PeriodInfo storage _periodInfo = periodInfo[_period];

			for (uint64 _day = day; _day < _today; _day++) {
				// carry over accRewardPerShare to the next day
				{
					_periodInfo.dayInfo[_day + 1].accRewardPerShare = _periodInfo.dayInfo[_day].accRewardPerShare;
				}

				// sum up the rewards that expired for a given day
				{
					DayInfo storage _dayInfo = _periodInfo.dayInfo[_day + 1 - _period];
					_amount += _dayInfo.expiringReward;
					_dayInfo.expiringReward = 0;
				}
			}
		}

		day = _today;

		if (_amount > 0) {
			totalReward -= _amount;

			IERC20(rewardToken).safeTransfer(buyback, _amount);
		}
	}

	function _updateAccount(address _account, int256 _amount) internal
	{
		AccountInfo storage _accountInfo = accountInfo[_account];
		uint16 _period = _accountInfo.period;
		if (_period == 0) {
			// initializes and adds account to index
			_period = 1;

			accountIndex.push(_account);

			_accountInfo.period = _period;
			_accountInfo.day = day;
		}
		PeriodInfo storage _periodInfo = periodInfo[_period];

		uint256 _rewardBefore = _accountInfo.reward;

		// if account rewards expire, then
		{
			// if rewards beyond reach, resets to the and of previous day
			if (_accountInfo.day < day + 1 - _period) {
				DayInfo storage _dayInfo = _periodInfo.dayInfo[day - 1];
				_accountInfo.accRewardDebt = _accountInfo.amount * _dayInfo.accRewardPerShare / 1e18;
			} else {
				// collects rewards for the past days
				for (uint64 _day = _accountInfo.day; _day < day; _day++) {
					DayInfo storage _dayInfo = _periodInfo.dayInfo[_day];
					uint256 _accRewardDebt = _accountInfo.amount * _dayInfo.accRewardPerShare / 1e18;
					uint256 _reward = _accRewardDebt - _accountInfo.accRewardDebt + bonus[_account][_day];
					_dayInfo.expiringReward -= _reward;
					_accountInfo.reward += _reward;
					_accountInfo.accRewardDebt = _accRewardDebt;
					bonus[_account][_day] = 0;
				}
			}
		}

		// collects rewards for the current day and adjusts balance
		{
			DayInfo storage _dayInfo = _periodInfo.dayInfo[day];
			uint256 _reward = _accountInfo.amount * _dayInfo.accRewardPerShare / 1e18 - _accountInfo.accRewardDebt + bonus[_account][day];
			_dayInfo.expiringReward -= _reward;
			_accountInfo.reward += _reward;
			if (_amount > 0) {
				_accountInfo.amount += uint256(_amount);
				_periodInfo.amount += uint256(_amount);
			}
			else
			if (_amount < 0) {
				_accountInfo.amount -= uint256(-_amount);
				_periodInfo.amount -= uint256(-_amount);
			}
			_accountInfo.accRewardDebt = _accountInfo.amount * _dayInfo.accRewardPerShare / 1e18;
			bonus[_account][day] = 0;
		}

		_accountInfo.day = day;

		// collect period fees from the account reward
		if (_periodInfo.fee > 0) {
			uint256 _rewardAfter = _accountInfo.reward;

			uint256 _reward = _rewardAfter - _rewardBefore;
			uint256 _fee = _reward * _periodInfo.fee / 1e18;
			if (_fee > 0) {
				_accountInfo.reward -= _fee;

				totalReward -= _fee;

				IERC20(rewardToken).safeTransfer(buyback, _fee);
			}
		}
	}

	event Deposit(address indexed _account, address indexed _hmineToken, uint256 _amount);
	event Withdraw(address indexed _account, address indexed _hmineToken, uint256 _amount);
	event Claim(address indexed _account, address indexed _rewardToken, uint256 _amount);
	event Reward(address indexed _account, address indexed _rewardToken, uint256 _amount);
	event RewardAll(address indexed _account, address indexed _rewardToken, uint256 _amount);
}