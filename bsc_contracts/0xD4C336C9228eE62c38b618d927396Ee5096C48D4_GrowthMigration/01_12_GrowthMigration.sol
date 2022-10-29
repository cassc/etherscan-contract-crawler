// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.9;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Initializable } from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";

import { IUniswapV2Router } from "../farming/IUniswapV2Router.sol";
import { IUniswapV2Factory } from "../farming/IUniswapV2Factory.sol";
import { StakingCompound } from "./StakingCompound.sol";

interface ICultivator
{
	function depositFor(address _account, uint256 _amount) external;
	function winNowFor(address _account) external;
}

contract GrowthMigration is Initializable, Ownable, ReentrancyGuard
{
	using Address for address payable;
	using SafeERC20 for IERC20;

	struct AccountInfo {
		uint256 locked; // xGRO locked
		uint256 amount; // xGRO staked/unlocked
		uint256 burned; // xPERPS burned
		uint256 cultivated; // xGRO/BNB sent to the cultivator
		uint256 drip; // xGRO from drip pool accumulated but not claimed
		uint256 accDripDebt; // xGRO reward debt from PCS distribution algorithm
		bool whitelisted; // flag indicating whether or not account pays withdraw penalties
		bool exists; // flag to index account
	}

	address constant FURNACE = 0x000000000000000000000000000000000000dEaD;
	address constant WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;

	address constant ROUTER = 0x10ED43C718714eb63d5aA57B78B54704E256024E; // pancake swap router
	address constant CULTIVATOR = 0xD649685E7ce349336F8B04EB033f82A4e98337E6; // emp money cultivator
	address constant CULTIVATOR_FARMER = 0x121183FB38813D24e2C489FBf224C8a1D7fad58E; // emp money cultivator farmer

	uint256 constant DEFAULT_LAUNCH_TIME = 1666980000; // 2022-10-28 6PM UTC
	uint256 constant DEFAULT_DRIP_RATE_PER_DAY = 1e16; // 1% per day
	uint256 constant DEFAULT_CLAIM_FEE = 15e16; // 15%

	uint256 constant DAY = 1 days;
	uint256 constant TZ_OFFSET = 22 hours + 30 minutes; // UTC-1.30

	address public reserveToken; // xGRO
	address public burnToken; // xPERPS
	address public cultivatorToken; // xGRO/WBNB

	address public stakingCompound;

	uint256 public launchTime = DEFAULT_LAUNCH_TIME;

	uint256 public dripRatePerDay = DEFAULT_DRIP_RATE_PER_DAY;

	uint256 public claimFee = DEFAULT_CLAIM_FEE;

	bool public whitelistAll = false;

	uint256 public totalLocked = 0; // total locked balance
	uint256 public totalStaked = 0; // total staked balance
	uint256 public totalBurned = 0; // total burned balance
	uint256 public totalCultivated = 0; // total cultivated balance

	uint256 public totalDrip = 0; // total drip pool balance
	uint256 public allocDrip = 0; // total drip pool balance allocated

	uint256 public accDripPerShare = 0; // cumulative drip pool xGRO per xGRO staked from PCS distribution algorithm

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

	constructor(address _reserveToken, address _burnToken, address _stakingCompound)
	{
		initialize(msg.sender, _reserveToken, _burnToken, _stakingCompound);
	}

	function initialize(address _owner, address _reserveToken, address _burnToken, address _stakingCompound) public initializer
	{
		_transferOwnership(_owner);

		launchTime = DEFAULT_LAUNCH_TIME;

		dripRatePerDay = DEFAULT_DRIP_RATE_PER_DAY;

		claimFee = DEFAULT_CLAIM_FEE;

		whitelistAll = false;

		totalLocked = 0; // total locked balance
		totalStaked = 0; // total staked balance
		totalBurned = 0; // total burned balance
		totalCultivated = 0; // total cultivated balance

		totalDrip = 0; // total drip pool balance
		allocDrip = 0; // total drip pool balance allocated

		accDripPerShare = 0; // cumulative drip pool xGRO per xGRO staked from PCS distribution algorithm

		day = today();

		require(_burnToken != _reserveToken, "invalid token");
		reserveToken = _reserveToken;
		burnToken = _burnToken;
		stakingCompound = _stakingCompound;
		cultivatorToken = IUniswapV2Factory(IUniswapV2Router(ROUTER).factory()).getPair(reserveToken, WBNB);
	}

	function migrate(address[] calldata _accounts, uint256[] calldata _amounts) external onlyOwner nonReentrant
	{
		require(_accounts.length == _amounts.length, "lenght mismatch");

		_updateDay();

		uint256 _totalAmount = 0;
		for (uint256 _i = 0; _i < _accounts.length; _i++) {
			address _account = _accounts[_i];
			uint256 _amount = _amounts[_i];

			_updateAccount(_account, 0);

			AccountInfo storage _accountInfo = accountInfo[_account];
			_accountInfo.locked += _amount;

			_totalAmount += _amount;
		}

		totalLocked += _totalAmount;

		IERC20(reserveToken).safeTransferFrom(msg.sender, address(this), _totalAmount);
	}

	// updates the volatile vdc address
	function setStakingCompound(address _stakingCompound) external onlyOwner
	{
		require(_stakingCompound != address(0), "invalid address");
		stakingCompound = _stakingCompound;
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
		require(_dripRatePerDay <= 100e16, "invalid rate");
		dripRatePerDay = _dripRatePerDay;
	}

	function setClaimFee(uint256 _claimFee) external onlyOwner
	{
		require(_claimFee <= 100e16, "invalid rate");
		claimFee = _claimFee;
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
		if (_token == reserveToken) _amount -= totalLocked + totalStaked + totalDrip;
		require(_amount > 0, "no balance");
		IERC20(_token).safeTransfer(msg.sender, _amount);
	}

	function burnAndUnlock(uint256 _amount, uint256 _minUnlockAmount) external hasLaunched nonReentrant returns (uint256 _unlockAmount)
	{
		require(_amount > 0, "invalid amount");

		address[] memory _path = new address[](3);
		_path[0] = burnToken;
		_path[1] = WBNB;
		_path[2] = reserveToken;
		_unlockAmount = 2 * IUniswapV2Router(ROUTER).getAmountsOut(_amount, _path)[2];
		require(_unlockAmount >= _minUnlockAmount, "high slippage");

		_updateDay();

		_updateAccount(msg.sender, 0);

		AccountInfo storage _accountInfo = accountInfo[msg.sender];
		require(_unlockAmount <= _accountInfo.locked, "insufficient balance");
		_accountInfo.locked -= _unlockAmount;

		totalLocked -= _unlockAmount;

		_updateAccount(msg.sender, int256(_unlockAmount));

		totalStaked += _unlockAmount;

		totalBurned += _amount;
		_accountInfo.burned += _amount;

		IERC20(burnToken).safeTransferFrom(msg.sender, FURNACE, _amount);

		emit Burn(msg.sender, burnToken, _amount);
		emit Unlock(msg.sender, reserveToken, _unlockAmount);

		return _unlockAmount;
	}

	function cultivate(uint256 _maxAmount) external payable hasLaunched nonReentrant returns (uint256 _amount, uint256 _shares)
	{
		require(_maxAmount > 0, "invalid amount");

		_updateDay();

		_updateAccount(msg.sender, 0);

		AccountInfo storage _accountInfo = accountInfo[msg.sender];
		require(_maxAmount <= _accountInfo.locked + _accountInfo.amount, "insufficient balance");

		IERC20(reserveToken).safeApprove(ROUTER, _maxAmount);
		(_amount,, _shares) = IUniswapV2Router(ROUTER).addLiquidityETH{value: msg.value}(reserveToken, _maxAmount, 1, msg.value, address(this), block.timestamp);
		IERC20(reserveToken).safeApprove(ROUTER, 0);

		if (_amount <= _accountInfo.locked) {
			_accountInfo.locked -= _amount;

			totalLocked -= _amount;
		} else {
			uint256 _excess = _amount - _accountInfo.locked;

			totalLocked -= _accountInfo.locked;

			_accountInfo.locked = 0;

			_updateAccount(msg.sender, -int256(_excess));

			totalStaked -= _excess;
		}

		totalCultivated += _shares;
		_accountInfo.cultivated += _shares;

		IERC20(cultivatorToken).safeApprove(CULTIVATOR_FARMER, _shares);
		ICultivator(CULTIVATOR).depositFor(msg.sender, _shares);
		IERC20(cultivatorToken).safeApprove(CULTIVATOR_FARMER, 0);

		emit Cultivate(msg.sender, reserveToken, _amount, msg.value, _shares);

		return (_amount, _shares);
	}

	function cultivateWin(uint256 _maxAmount) external payable hasLaunched nonReentrant returns (uint256 _amount, uint256 _shares)
	{
		require(_maxAmount > 0, "invalid amount");

		_updateDay();

		_updateAccount(msg.sender, 0);

		AccountInfo storage _accountInfo = accountInfo[msg.sender];
		require(_maxAmount <= _accountInfo.locked + _accountInfo.amount, "insufficient balance");

		IERC20(reserveToken).safeApprove(ROUTER, _maxAmount);
		(_amount,, _shares) = IUniswapV2Router(ROUTER).addLiquidityETH{value: msg.value}(reserveToken, _maxAmount, 1, msg.value, address(this), block.timestamp);
		IERC20(reserveToken).safeApprove(ROUTER, 0);

		if (_amount <= _accountInfo.locked) {
			_accountInfo.locked -= _amount;

			totalLocked -= _amount;
		} else {
			uint256 _excess = _amount - _accountInfo.locked;

			totalLocked -= _accountInfo.locked;

			_accountInfo.locked = 0;

			_updateAccount(msg.sender, -int256(_excess));

			totalStaked -= _excess;
		}

		totalCultivated += _shares;
		_accountInfo.cultivated += _shares;

		IERC20(cultivatorToken).safeApprove(CULTIVATOR_FARMER, _shares);
		ICultivator(CULTIVATOR).winNowFor(msg.sender);
		uint256 _balance = IERC20(cultivatorToken).balanceOf(address(this));
		if (_balance > 0) {
			ICultivator(CULTIVATOR).depositFor(msg.sender, _balance);
		}
		IERC20(cultivatorToken).safeApprove(CULTIVATOR_FARMER, 0);

		emit CultivateWin(msg.sender, reserveToken, _amount, msg.value, _shares - _balance);
		if (_balance > 0) {
			emit Cultivate(msg.sender, reserveToken, _amount, msg.value, _balance);
		}

		return (_amount, _shares);
	}

	function withdraw(uint256 _amount) external hasLaunched nonReentrant
	{
		require(_amount > 0, "invalid amount");

		_updateDay();

		_updateAccount(msg.sender, 0);

		AccountInfo storage _accountInfo = accountInfo[msg.sender];
		require(_amount <= _accountInfo.locked + _accountInfo.amount, "insufficient balance");

		if (_amount <= _accountInfo.locked) {
			_accountInfo.locked -= _amount;

			totalLocked -= _amount;
		} else {
			uint256 _excess = _amount - _accountInfo.locked;

			totalLocked -= _accountInfo.locked;

			_accountInfo.locked = 0;

			_updateAccount(msg.sender, -int256(_excess));

			totalStaked -= _excess;
		}

		if (_accountInfo.whitelisted || whitelistAll) {
			IERC20(reserveToken).safeTransfer(msg.sender, _amount);
		} else {
			uint256 _1percent = _amount * 1e16 / 100e16;
			uint256 _dripAmount = 45 * _1percent;
			uint256 _burnAmount = 45 * _1percent;
			uint256 _netAmount = _amount - (_dripAmount + _burnAmount);

			totalDrip += _dripAmount;

			IERC20(reserveToken).safeTransfer(FURNACE, _burnAmount);

			IERC20(reserveToken).safeTransfer(msg.sender, _netAmount);
		}

		emit Withdraw(msg.sender, reserveToken, _amount);
	}

	// claims drip (xGRO)
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

			uint256 _dripFeeAmount = _dripAmount * claimFee / 1e18;
			uint256 _dripNetAmount = _dripAmount - _dripFeeAmount;

			IERC20(reserveToken).safeTransfer(msg.sender, _dripNetAmount);

			IERC20(reserveToken).safeApprove(stakingCompound, _dripFeeAmount);
			StakingCompound(stakingCompound).donateDrip(_dripFeeAmount);
		}

		emit Claim(msg.sender, reserveToken, _dripAmount);

		return _dripAmount;
	}

	// compounds drip (xGRO)
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

			IERC20(reserveToken).safeApprove(stakingCompound, _dripAmount);
			StakingCompound(stakingCompound).depositOnBehalfOf(_dripAmount, msg.sender);
		}

		emit Compound(msg.sender, reserveToken, _dripAmount);
	}

	// sends xGRO to the drip pool
	function donateDrip(uint256 _amount) external nonReentrant
	{
		require(_amount > 0, "invalid amount");

		_updateDay();

		totalDrip += _amount;

		IERC20(reserveToken).safeTransferFrom(msg.sender, address(this), _amount);

		emit DonateDrip(msg.sender, reserveToken, _amount);
	}

	// performs the daily distribution from the drip pool (xGRO)
	function updateDay() external nonReentrant
	{
		_updateDay();
	}

	function _updateDay() internal
	{
		uint64 _today = today();

		if (day == _today) return;

		uint256 _ratePerDay = dripRatePerDay;
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
			}
		}

		day = _today;
	}

	// updates the account balances while accumulating drip using PCS distribution algorithm
	function _updateAccount(address _account, int256 _amount) internal
	{
		AccountInfo storage _accountInfo = accountInfo[_account];
		if (!_accountInfo.exists) {
			// adds account to index
			_accountInfo.exists = true;
			accountIndex.push(_account);
		}

		_accountInfo.drip += _accountInfo.amount * accDripPerShare / 1e18 - _accountInfo.accDripDebt;
		if (_amount > 0) {
			_accountInfo.amount += uint256(_amount);
		}
		else
		if (_amount < 0) {
			_accountInfo.amount -= uint256(-_amount);
		}
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

	event Burn(address indexed _account, address indexed _burnToken, uint256 _amount);
	event Unlock(address indexed _account, address indexed _reserveToken, uint256 _amount);
	event Cultivate(address indexed _account, address indexed _reserveToken, uint256 _amount, uint256 _value, uint256 _shares);
	event CultivateWin(address indexed _account, address indexed _reserveToken, uint256 _amount, uint256 _value, uint256 _shares);
	event Withdraw(address indexed _account, address indexed _reserveToken, uint256 _amount);
	event Claim(address indexed _account, address indexed _rewardToken, uint256 _amount);
	event Compound(address indexed _account, address indexed _rewardToken, uint256 _amount);
	event DonateDrip(address indexed _account, address indexed _reserveToken, uint256 _amount);
}