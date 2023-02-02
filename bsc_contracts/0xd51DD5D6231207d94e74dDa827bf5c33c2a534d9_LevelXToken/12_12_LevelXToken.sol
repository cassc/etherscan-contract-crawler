// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.9;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Initializable } from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";

import { IUniswapV2Router } from "./IUniswapV2Router.sol";
import { IUniswapV2Factory } from "./IUniswapV2Factory.sol";
import { IUniswapV2Pair } from "./IUniswapV2Pair.sol";

contract LevelXToken is Initializable, Ownable, ERC20
{
	using Address for address;
	using SafeERC20 for IERC20;

	struct RewardInfo {
		bool exists; // existence flag
		address bankroll; // receiver of reward cut
		address[] path; // conversion path from BNB
		uint256 rewardBalance; // tracked balance
		mapping(uint256 => uint256) accRewardPerShare; // accumulated reward per share (by week/double precision)
	}

	struct AccountInfo {
		bool exists; // existence flag
		uint256 lastWeek; // timestamp of last week sync'ed
		uint256 weekIndex; // index of last week sync'ed
		uint256 lastEpoch; // timestamp of last epoch sync'ed
		uint256 epochIndex; // index of last epoch sync'ed
		uint256 level; // reward level (user's share multiplier for rewards)
		uint256 activeBalance; // 0 or user's balance (if above the minimum for rewards)
		mapping(address => AccountRewardInfo) rewardInfo;
	}

	struct AccountRewardInfo {
		uint256 rewardDebt; // base for reward distribution
		uint256 unclaimedReward; // reward balance available for claim
	}

	uint256 constant WEEK_OFFSET = 0; // week offset for level bumps
	uint256 constant WEEK_DURATION = 8 hours; // interval between automatic level bumps
	uint256 constant EPOCH_DURATION = 15 minutes; // interval between rebases

	uint256 constant INITIAL_SUPPLY = 500_000_000e18; // 500M

	uint256 constant DEFAULT_BUY_FEE = 10e16; // 10%
	uint256 constant DEFAULT_SELL_FEE = 15e16; // 15%

	uint256 constant DEFAULT_FEE_LIQUIDITY_CUT = 20e16; // 20% of fees

	uint256 constant DEFAULT_MINIMUM_FEE_BALANCE_TO_SWAP = 1e18; // 1 LVLX
	uint256 constant DEFAULT_MINIMUM_REWARD_BALANCE_TO_SWAP = 1e18; // 1 BNB

	uint256 constant DEFAULT_BURN_AMOUNT_TO_BUMP_LEVEL = 10_000e18; // 10k LVLX

	uint256 constant DEFAULT_MINIMUM_BALANCE_FOR_REWARDS = 10_000e18; // 10k LVLX

	uint256 constant DEFAULT_REBASE_RATE_PER_EPOCH = 0.01e16; // 0.01% every 15m

	uint256 constant DEFAULT_EXPANSION_TO_REWARD_FACTOR = 0.1e18; // 0.1x

	address constant INTERNAL_ADDRESS = address(1); // used internally to record pending rebase balances

	address constant FURNACE = 0x000000000000000000000000000000000000dEaD;

	// token name and symbol
	string private name_;
	string private symbol_;

	// internal flags
	bool private bypass_; // internal flag to bypass all token logic
	bool private inswap_; // internal flag to bypass buy/sell portions of token logic

	address public router; // PCS router
	address public WBNB; // wrapped BNB
	address public pair; // LVLX/BNB PCS liquidity pool

	address[] public pathWBNB; // route from LVLX to WBNB

	uint256 public buyFee; // percentage of LVLX transfer amount taken on buys
	uint256 public sellFee; // percentage of LVLX transfer amount taken on sells

	uint256 public feeLiquidityCut; // percentage of fees to be added as LVLX/BNB liquidity

	address public liquidityRecipient; // LVLX/BNB lp shares are sent to this address

	uint256 public minimumFeeBalanceToSwap; // minimum amount of LVLX to trigger BNB swap and LVLX/BNB liqudity injection
	uint256 public minimumRewardBalanceToSwap; // minimum amount of BNB to trigger rewards swap

	uint256 public burnAmountToBumpLevel; // amount of LVLX to be burned to increase level by one

	uint256 public minimumBalanceForRewards; // amount of LVLX to be hold to participate on rebases and receive rewards

	uint256 public lastWeek; // timestamp of last week sync'ed
	uint256 public weekIndex; // index of last week sync'ed

	uint256 public lastEpoch; // timestamp of last epoch sync'ed
	uint256 public epochIndex; // index of last epoch sync'ed

	uint256 public totalActiveSupply; // sum of active balances for all LVLX holders
	uint256 public totalShares; // sum of share (level * active balance) for all LVLX holders

	uint256 public nextRebaseRatePerEpoch; // rebase rate (per epoch) to apply when the next week boundary is reached
	mapping(uint256 => uint256) public rebaseRatePerEpoch; // rebase rate (per epock) by week

	address[] public rewardIndex; // list of reward tokens
	mapping(address => RewardInfo) public rewardInfo; // reward token attributes

	address[] public accountIndex; // list of all accounts that ever received LVLX
	mapping(address => AccountInfo) public accountInfo; // account attributes

	mapping(address => bool) public excludeFromTransferPenaltyAsSender; // whitelist to avoid 1 level penalty when LVLX is sent
	mapping(address => bool) public excludeFromTransferPenaltyAsReceiver; // whitelist to avoid 1 level penalty when LVLX is received

	mapping(address => bool) public excludeFromTradeFeeAsBuyer; // whitelist to avoid fees on LVLX buys
	mapping(address => bool) public excludeFromTradeFeeAsSeller; // whitelist to avoid fees on LVLX sells

	mapping(address => bool) public excludeFromRewardsDefaultBehavior; // whitelist to turn-off rebasing/rewards for EOA accounts or turn-on rebasing/rewards for contracts

	mapping(uint256 => mapping(uint256 => uint256)) public expCache; // caches exponential computations

	uint256 public expansionToRewardFactor; // the amount of additional LVLX to be minted as a factor of the rebase expansion amount

	function name() public view override returns (string memory _name)
	{
		return name_;
	}

	function symbol() public view override returns (string memory _symbol)
	{
		return symbol_;
	}

	function rewardIndexLength() external view returns (uint256 _length)
	{
		return rewardIndex.length;
	}

	function rewardPath(address _rewardToken) external view returns (address[] memory _path)
	{
		return rewardInfo[_rewardToken].path;
	}

	function accRewardPerShare(address _rewardToken, uint256 _weekIndex) external view returns (uint256 _accRewardPerShare)
	{
		return rewardInfo[_rewardToken].accRewardPerShare[_weekIndex];
	}

	function accountIndexLength() external view returns (uint256 _length)
	{
		return accountIndex.length;
	}

	function accountRewardInfo(address _account, address _rewardToken) external view returns (AccountRewardInfo memory _accountRewardInfo)
	{
		return accountInfo[_account].rewardInfo[_rewardToken];
	}

	function time() public view returns (uint256 _time)
	{
		return block.timestamp + WEEK_OFFSET;
	}

	function week() public view returns (uint256 _week)
	{
		return (time() / WEEK_DURATION) * WEEK_DURATION;
	}

	function epoch() public view returns (uint256 _epoch)
	{
		return (time() / EPOCH_DURATION) * EPOCH_DURATION;
	}

	constructor(string memory _name, string memory _symbol, address _router)
		ERC20("", "")
	{
		initialize(msg.sender, _name, _symbol, _router);
	}

	function initialize(address _owner, string memory _name, string memory _symbol, address _router) public initializer
	{
		require(WEEK_DURATION % EPOCH_DURATION == 0, "misaligned duration");

		_transferOwnership(_owner);

		name_ = _name;
		symbol_ = _symbol;

		bypass_ = false;
		inswap_ = false;

		router = _router;
		WBNB = IUniswapV2Router(router).WETH();
		pair = IUniswapV2Factory(IUniswapV2Router(router).factory()).createPair(WBNB, address(this));

		pathWBNB = new address[](2);
		pathWBNB[0] = address(this);
		pathWBNB[1] = WBNB;

		buyFee = DEFAULT_BUY_FEE;
		sellFee = DEFAULT_SELL_FEE;

		feeLiquidityCut = DEFAULT_FEE_LIQUIDITY_CUT;

		liquidityRecipient = _owner;

		minimumFeeBalanceToSwap = DEFAULT_MINIMUM_FEE_BALANCE_TO_SWAP;
		minimumRewardBalanceToSwap = DEFAULT_MINIMUM_REWARD_BALANCE_TO_SWAP;

		burnAmountToBumpLevel = DEFAULT_BURN_AMOUNT_TO_BUMP_LEVEL;

		minimumBalanceForRewards = DEFAULT_MINIMUM_BALANCE_FOR_REWARDS;

		lastWeek = week();
		weekIndex = 0;

		lastEpoch = epoch();
		epochIndex = 0;

		totalActiveSupply = 0;
		totalShares = 0;

		nextRebaseRatePerEpoch = DEFAULT_REBASE_RATE_PER_EPOCH;
		rebaseRatePerEpoch[weekIndex] = nextRebaseRatePerEpoch;

		expansionToRewardFactor = DEFAULT_EXPANSION_TO_REWARD_FACTOR;

		{
			RewardInfo storage _rewardInfo = rewardInfo[address(this)];
			_rewardInfo.exists = true;
			_rewardInfo.bankroll = address(0);
			_rewardInfo.path = new address[](0);
			rewardIndex.push(address(this));
		}

		excludeFromTransferPenaltyAsSender[pair] = true;
		excludeFromTransferPenaltyAsSender[address(this)] = true;
		excludeFromTransferPenaltyAsReceiver[address(this)] = true;

		excludeFromTradeFeeAsSeller[address(this)] = true;

		excludeFromRewardsDefaultBehavior[pair] = true;
		excludeFromRewardsDefaultBehavior[FURNACE] = true;

		_approve(address(this), router, type(uint256).max);
		IERC20(WBNB).approve(router, type(uint256).max);

		_mint(_owner, INITIAL_SUPPLY);
	}

	function migrate() external onlyOwner
	{
		rewardInfo[address(this)].accRewardPerShare[40] = 0;
	}

	function updateBuyFee(uint256 _buyFee) external onlyOwner
	{
		require(_buyFee <= 100e16, "invalid rate");
		buyFee = _buyFee;
		emit UpdateBuyFee(_buyFee);
	}

	function updateSellFee(uint256 _sellFee) external onlyOwner
	{
		require(_sellFee <= 100e16, "invalid rate");
		sellFee = _sellFee;
		emit UpdateSellFee(_sellFee);
	}

	function updateFeeLiquidityCut(uint256 _feeLiquidityCut) external onlyOwner
	{
		require(_feeLiquidityCut <= 100e16, "invalid rate");
		feeLiquidityCut = _feeLiquidityCut;
		emit UpdateFeeLiquidityCut(_feeLiquidityCut);
	}

	function updateLiquidityRecipient(address _liquidityRecipient) external onlyOwner
	{
		require(_liquidityRecipient != address(0), "invalid address");
		liquidityRecipient = _liquidityRecipient;
		emit UpdateLiquidityRecipient(_liquidityRecipient);
	}

	function updateMinimumFeeBalanceToSwap(uint256 _minimumFeeBalanceToSwap) external onlyOwner
	{
		minimumFeeBalanceToSwap = _minimumFeeBalanceToSwap;
		emit UpdateMinimumFeeBalanceToSwap(_minimumFeeBalanceToSwap);
	}

	function updateMinimumRewardBalanceToSwap(uint256 _minimumRewardBalanceToSwap) external onlyOwner
	{
		minimumRewardBalanceToSwap = _minimumRewardBalanceToSwap;
		emit UpdateMinimumRewardBalanceToSwap(_minimumRewardBalanceToSwap);
	}

	function addRewardToken(address _rewardToken, address _bankroll, address[] memory _path) external onlyOwner
	{
		require(_bankroll != address(0), "invalid address");
		require(_path.length >= 2 && _path[0] == WBNB && _path[_path.length - 1] == _rewardToken, "invalid path");
		for (uint256 _i = 1; _i <= _path.length - 2; _i++) {
			require(_path[_i] != address(this), "invalid path");
		}
		RewardInfo storage _rewardInfo = rewardInfo[_rewardToken];
		require(!_rewardInfo.exists, "already exists");
		_rewardInfo.exists = true;
		_rewardInfo.bankroll = _bankroll;
		_rewardInfo.path = _path;
		rewardIndex.push(_rewardToken);
		emit AddRewardToken(_rewardToken, _bankroll, _path);
	}

	function updateRewardBankroll(address _rewardToken, address _bankroll) external onlyOwner
	{
		require(_bankroll != address(0), "invalid address");
		RewardInfo storage _rewardInfo = rewardInfo[_rewardToken];
		require(_rewardInfo.exists, "unknown reward");
		_rewardInfo.bankroll = _bankroll;
		emit UpdateRewardBankroll(_rewardToken, _bankroll);
	}

	function updateRewardPath(address _rewardToken, address[] memory _path) external onlyOwner
	{
		require(_path.length >= 2 && _path[0] == WBNB && _path[_path.length - 1] == _rewardToken, "invalid path");
		for (uint256 _i = 1; _i <= _path.length - 2; _i++) {
			require(_path[_i] != address(this), "invalid path");
		}
		RewardInfo storage _rewardInfo = rewardInfo[_rewardToken];
		require(_rewardInfo.exists, "unknown reward");
		_rewardInfo.path = _path;
		emit UpdateRewardPath(_rewardToken, _path);
	}

	function updateBurnAmountToBumpLevel(uint256 _burnAmountToBumpLevel) external onlyOwner
	{
		burnAmountToBumpLevel = _burnAmountToBumpLevel;
		emit UpdateBurnAmountToBumpLevel(_burnAmountToBumpLevel);
	}

	function updateMinimumBalanceForRewards(uint256 _minimumBalanceForRewards, bool _forceUpdateAll) external onlyOwner
	{
		require(_minimumBalanceForRewards > 0, "invalid amount");
		minimumBalanceForRewards = _minimumBalanceForRewards;
		emit UpdateMinimumBalanceForRewards(_minimumBalanceForRewards);
		if (_forceUpdateAll) {
			// this is a costly operation not designed to be used regularly, should be avoided
			_updateEpoch();
			for (uint256 _i = 0; _i < accountIndex.length; _i++) {
				address _account = accountIndex[_i];
				_updateAccount(_account);
				_postUpdateAccount(_account, 0);
			}
		}
	}

	function updateNextRebaseRatePerEpoch(uint256 _nextRebaseRatePerEpoch) external onlyOwner
	{
		_updateEpoch();
		nextRebaseRatePerEpoch = _nextRebaseRatePerEpoch;
		emit UpdateNextRebaseRatePerEpoch(_nextRebaseRatePerEpoch);
	}

	function updateExpansionToRewardFactor(uint256 _expansionToRewardFactor) external onlyOwner
	{
		_updateEpoch();
		expansionToRewardFactor = _expansionToRewardFactor;
		emit UpdateExpansionToRewardFactor(_expansionToRewardFactor);
	}

	function updateExcludeFromTransferPenalty(address[] memory _accounts, bool _enabledAsSender, bool _enabledAsReceiver) external onlyOwner
	{
		for (uint256 _i = 0; _i < _accounts.length; _i++) {
			address _account = _accounts[_i];
			require(_account != address(this), "invalid address");
			excludeFromTransferPenaltyAsSender[_account] = _enabledAsSender;
			excludeFromTransferPenaltyAsReceiver[_account] = _enabledAsReceiver;
			emit UpdateExcludeFromTransferPenalty(_account, _enabledAsSender, _enabledAsReceiver);
		}
	}

	function updateExcludeFromTradeFee(address[] memory _accounts, bool _enabledAsBuyer, bool _enabledAsSeller) external onlyOwner
	{
		for (uint256 _i = 0; _i < _accounts.length; _i++) {
			address _account = _accounts[_i];
			require(_account != address(this), "invalid address");
			excludeFromTradeFeeAsBuyer[_account] = _enabledAsBuyer;
			excludeFromTradeFeeAsSeller[_account] = _enabledAsSeller;
			emit UpdateExcludeFromTradeFee(_account, _enabledAsBuyer, _enabledAsSeller);
		}
	}

	function updateExcludeFromRewardsDefaultBehavior(address[] memory _accounts, bool _enabled) external onlyOwner
	{
		_updateEpoch();
		for (uint256 _i = 0; _i < _accounts.length; _i++) {
			address _account = _accounts[_i];
			require(_account != address(this), "invalid address");
			_updateAccount(_account);
			excludeFromRewardsDefaultBehavior[_account] = _enabled;
			emit UpdateExcludeFromRewardsDefaultBehavior(_account, _enabled);
			_postUpdateAccount(_account, 0);
		}
	}

	function claimForPair(uint256 _i) external onlyOwner returns (uint256 _amount)
	{
		return _claim(pair, _i, msg.sender);
	}

	function activeBalanceOf(address _account) public view returns (uint256 _activeBalance)
	{
		AccountInfo storage _accountInfo = accountInfo[_account];
		return _accountInfo.activeBalance;
	}

	function levelOf(address _account) public view returns (uint256 _level)
	{
		AccountInfo storage _accountInfo = accountInfo[_account];
		return _accountInfo.exists ? _accountInfo.level : 1;
	}

	function stakeOf(address _account) public view returns (uint256 _stake)
	{
		AccountInfo storage _accountInfo = accountInfo[_account];
		uint256 _shares = _accountInfo.level * _accountInfo.activeBalance;
		return _shares * 1e18 / totalShares;
	}

	function computeTotalSupply() external returns (uint256 _totalSupply)
	{
		_updateEpoch();
		return totalSupply();
	}

	function computeTotalActiveSupply() external returns (uint256 _totalActiveSupply)
	{
		_updateEpoch();
		return totalActiveSupply;
	}

	function computeBalanceOf(address _account) external returns (uint256 _balance)
	{
		_updateEpoch();
		_updateAccount(_account);
		_postUpdateAccount(_account, 0);
		return balanceOf(_account);
	}

	function computeActiveBalanceOf(address _account) external returns (uint256 _activeBalance)
	{
		_updateEpoch();
		_updateAccount(_account);
		_postUpdateAccount(_account, 0);
		return activeBalanceOf(_account);
	}

	function computeLevelOf(address _account) external returns (uint256 _level)
	{
		_updateEpoch();
		_updateAccount(_account);
		_postUpdateAccount(_account, 0);
		return levelOf(_account);
	}

	function computeStakeOf(address _account) external returns (uint256 _stake)
	{
		_updateEpoch();
		_updateAccount(_account);
		_postUpdateAccount(_account, 0);
		return stakeOf(_account);
	}

	function bumpLevel() external
	{
		_updateEpoch();
		_updateAccount(msg.sender);
		{
			bypass_ = true;
			_burn(msg.sender, burnAmountToBumpLevel);
			bypass_ = false;
		}
		_postUpdateAccount(msg.sender, 1);
		emit BumpLevel(msg.sender);
	}

	function claim(uint256 _i) external returns (uint256 _amount)
	{
		return _claim(msg.sender, _i, msg.sender);
	}

	function _claim(address _account, uint256 _i, address _receiver) internal returns (uint256 _amount)
	{
		require(_i < rewardIndex.length, "invalid index");
		_updateEpoch();
		_updateAccount(_account);
		_postUpdateAccount(_account, 0);
		AccountInfo storage _accountInfo = accountInfo[_account];
		address _rewardToken = rewardIndex[_i];
		RewardInfo storage _rewardInfo = rewardInfo[_rewardToken];
		AccountRewardInfo storage _accountRewardInfo = _accountInfo.rewardInfo[_rewardToken];
		_amount = _accountRewardInfo.unclaimedReward;
		if (_amount > 0) {
			if (_amount > _rewardInfo.rewardBalance) { // check needed due to precision
				_amount = _rewardInfo.rewardBalance;
			}
			_accountRewardInfo.unclaimedReward = 0;
			_rewardInfo.rewardBalance -= _amount;
			if (_i == 0) {
				bypass_ = true;
				_transfer(INTERNAL_ADDRESS, _receiver, _amount);
				bypass_ = false;
			} else {
				IERC20(_rewardToken).safeTransfer(_receiver, _amount);
			}
		}
		emit Claim(_account, _rewardToken, _amount);
		return _amount;
	}

	function _updateEpoch() internal
	{
		uint256 _lastEpoch = epoch();

		if (_lastEpoch <= lastEpoch) return;

		uint256 _lastWeek = week();

		uint256 _totalActiveSupply = totalActiveSupply;

		// compute epoch changes along with week changes
		while (_lastWeek > lastWeek) {
			uint256 _nextWeek = lastWeek + WEEK_DURATION;
			uint256 _epochs = (_nextWeek - lastEpoch) / EPOCH_DURATION;
			{
				// perform rebases
				uint256 _rate = _cachedExp(100e16 + rebaseRatePerEpoch[weekIndex], _epochs);
				totalActiveSupply = totalActiveSupply * _rate / 100e16;
				totalShares = totalShares * _rate / 100e16;
				for (uint256 _i = 0; _i < rewardIndex.length; _i++) {
					address _rewardToken = rewardIndex[_i];
					RewardInfo storage _rewardInfo = rewardInfo[_rewardToken];
					_rewardInfo.accRewardPerShare[weekIndex] = _rewardInfo.accRewardPerShare[weekIndex] * 100e16 / _rate;
				}
			}
			lastEpoch = _nextWeek;
			epochIndex += _epochs;
			lastWeek = _nextWeek;
			weekIndex++;
			rebaseRatePerEpoch[weekIndex] = nextRebaseRatePerEpoch;
			{
				// accounts for level increments
				// sum((level_i + 1) * balance_i) = sum(level_i * balance_i) + sum(balance_i)
				totalShares += totalActiveSupply;
			}
		}

		// compute epoch changes within the last week
		if (_lastEpoch > lastEpoch) {
			uint256 _epochs = (_lastEpoch - lastEpoch) / EPOCH_DURATION;
			{
				// perform rebases
				uint256 _rate = _cachedExp(100e16 + rebaseRatePerEpoch[weekIndex], _epochs);
				totalActiveSupply = totalActiveSupply * _rate / 100e16;
				totalShares = totalShares * _rate / 100e16;
				for (uint256 _i = 0; _i < rewardIndex.length; _i++) {
					address _rewardToken = rewardIndex[_i];
					RewardInfo storage _rewardInfo = rewardInfo[_rewardToken];
					_rewardInfo.accRewardPerShare[weekIndex] = _rewardInfo.accRewardPerShare[weekIndex] * 100e16 / _rate;
				}
			}
			lastEpoch = _lastEpoch;
			epochIndex += _epochs;
		}

		uint256 _newActiveSupply = totalActiveSupply - _totalActiveSupply;

		// distribute new rewards
		uint256 _newReward = 0;
		if (totalShares > 0) {
			_newReward = _newActiveSupply * expansionToRewardFactor / 1e18;
			{
				address _rewardToken = rewardIndex[0];
				RewardInfo storage _rewardInfo = rewardInfo[_rewardToken];
				uint256 _rewardAmount = _newReward;
				if (_rewardAmount > 0) {
					_rewardInfo.rewardBalance += _rewardAmount;
					_rewardInfo.accRewardPerShare[weekIndex] += _rewardAmount * 1e36 / totalShares;
				}
			}
			for (uint256 _i = 1; _i < rewardIndex.length; _i++) {
				address _rewardToken = rewardIndex[_i];
				RewardInfo storage _rewardInfo = rewardInfo[_rewardToken];
				uint256 _rewardBalance = IERC20(_rewardToken).balanceOf(address(this));
				uint256 _rewardAmount = _rewardBalance - _rewardInfo.rewardBalance;
				if (_rewardAmount > 0) {
					_rewardInfo.rewardBalance = _rewardBalance;
					_rewardInfo.accRewardPerShare[weekIndex] += _rewardAmount * 1e36 / totalShares;
				}
			}
		}

		// allocate new supply
		uint256 _newSupply = _newActiveSupply + _newReward;
		if (_newSupply > 0) {
			bypass_ = true;
			_mint(INTERNAL_ADDRESS, _newSupply);
			bypass_ = false;
		}
	}

	function _updateAccount(address _account) internal
	{
		AccountInfo storage _accountInfo = accountInfo[_account];

		if (lastEpoch <= _accountInfo.lastEpoch) return;

		if (!_accountInfo.exists) {
			accountIndex.push(_account);
			_accountInfo.exists = true;
			_accountInfo.lastWeek = lastWeek;
			_accountInfo.weekIndex = weekIndex;
			_accountInfo.lastEpoch = lastEpoch;
			_accountInfo.epochIndex = epochIndex;
			_accountInfo.level = 1;
			_accountInfo.activeBalance = 0;
			return;
		}

		uint256 _activeBalance = _accountInfo.activeBalance;

		if (_activeBalance == 0) {
			// optimized for non active accounts
			uint256 _weeks = (lastWeek - _accountInfo.lastWeek) / WEEK_DURATION;
			uint256 _epochs = (lastEpoch - _accountInfo.lastEpoch) / EPOCH_DURATION;
			_accountInfo.lastWeek = lastWeek;
			_accountInfo.weekIndex += _weeks;
			_accountInfo.lastEpoch = lastEpoch;
			_accountInfo.epochIndex += _epochs;
			return;
		}

		// compute epoch changes along with week changes
		while (lastWeek > _accountInfo.lastWeek) {
			uint256 _nextWeek = _accountInfo.lastWeek + WEEK_DURATION;
			uint256 _epochs = (_nextWeek - _accountInfo.lastEpoch) / EPOCH_DURATION;
			{
				// perform rebases
				uint256 _rate = _cachedExp(100e16 + rebaseRatePerEpoch[_accountInfo.weekIndex], _epochs);
				_accountInfo.activeBalance = _accountInfo.activeBalance * _rate / 100e16;
				for (uint256 _i = 0; _i < rewardIndex.length; _i++) {
					address _rewardToken = rewardIndex[_i];
					RewardInfo storage _rewardInfo = rewardInfo[_rewardToken];
					AccountRewardInfo storage _accountRewardInfo = _accountInfo.rewardInfo[_rewardToken];
					uint256 _shares = _accountInfo.level * _accountInfo.activeBalance;
					uint256 _rewardDebt = _shares * _rewardInfo.accRewardPerShare[_accountInfo.weekIndex] / 1e36;
					if (_rewardDebt < _accountRewardInfo.rewardDebt) { // check needed due to precision
						_rewardDebt = _accountRewardInfo.rewardDebt;
					}
					uint256 _rewardAmount = _rewardDebt - _accountRewardInfo.rewardDebt;
					_accountRewardInfo.unclaimedReward += _rewardAmount;
					_accountRewardInfo.rewardDebt = 0; // for the next week
				}
			}
			_accountInfo.lastEpoch = _nextWeek;
			_accountInfo.epochIndex += _epochs;
			_accountInfo.lastWeek = _nextWeek;
			_accountInfo.weekIndex++;
			{
				// accounts for level increments
				_accountInfo.level++;
			}
		}

		// compute epoch changes within the last week
		if (lastEpoch > _accountInfo.lastEpoch) {
			uint256 _epochs = (lastEpoch - _accountInfo.lastEpoch) / EPOCH_DURATION;
			{
				// perform rebases
				uint256 _rate = _cachedExp(100e16 + rebaseRatePerEpoch[_accountInfo.weekIndex], _epochs);
				_accountInfo.activeBalance = _accountInfo.activeBalance * _rate / 100e16;
			}
			_accountInfo.lastEpoch = lastEpoch;
			_accountInfo.epochIndex += _epochs;
		}

		// collect rewards
		for (uint256 _i = 0; _i < rewardIndex.length; _i++) {
			address _rewardToken = rewardIndex[_i];
			RewardInfo storage _rewardInfo = rewardInfo[_rewardToken];
			AccountRewardInfo storage _accountRewardInfo = _accountInfo.rewardInfo[_rewardToken];
			uint256 _shares = _accountInfo.level * _accountInfo.activeBalance;
			uint256 _rewardDebt = _shares * _rewardInfo.accRewardPerShare[_accountInfo.weekIndex] / 1e36;
			if (_rewardDebt < _accountRewardInfo.rewardDebt) { // check needed due to precision
				_rewardDebt = _accountRewardInfo.rewardDebt;
			}
			uint256 _rewardAmount = _rewardDebt - _accountRewardInfo.rewardDebt;
			_accountRewardInfo.unclaimedReward += _rewardAmount;
			_accountRewardInfo.rewardDebt = _rewardDebt;
		}

		// transfer new balance
		uint256 _newBalance = _accountInfo.activeBalance - _activeBalance;
		if (_newBalance > 0) {
			uint256 _balance = balanceOf(INTERNAL_ADDRESS);
			if (_newBalance > _balance) { // check needed due to precision loss
				uint256 _excess = _newBalance - _balance;
				_accountInfo.activeBalance -= _excess;
				_newBalance = _balance;
			}
			bypass_ = true;
			_transfer(INTERNAL_ADDRESS, _account, _newBalance);
			bypass_ = false;
			if (_account == pair) {
				// syncs pool reserves with balances if possible
				try IUniswapV2Pair(pair).sync() {} catch {}
			}
		}
	}

	function _postUpdateAccount(address _account, int256 _levelBump) internal
	{
		// adjusts active supply/balance, level and share according to rules
		AccountInfo storage _accountInfo = accountInfo[_account];
		uint256 _balance = balanceOf(_account);
		bool _excludeFromRewards = _account.isContract() != excludeFromRewardsDefaultBehavior[_account];
		uint256 _oldActiveBalance = _accountInfo.activeBalance;
		uint256 _oldLevel = _accountInfo.level;
		uint256 _oldShares = _oldLevel * _oldActiveBalance;
		uint256 _newActiveBalance = _excludeFromRewards || _balance < minimumBalanceForRewards ? 0 : _balance;
		uint256 _newLevel = _levelBump >= 0 ? _oldLevel + uint256(_levelBump) : uint256(-_levelBump) >= _oldLevel ? 1 : _oldLevel - uint256(-_levelBump);
		uint256 _newShares = _newLevel * _newActiveBalance;
		_accountInfo.activeBalance = _newActiveBalance;
		_accountInfo.level = _newLevel;
		if (_newActiveBalance != _oldActiveBalance) {
			totalActiveSupply -= _oldActiveBalance;
			totalActiveSupply += _newActiveBalance;
		}
		if (_newShares != _oldShares) {
			totalShares -= _oldShares;
			totalShares += _newShares;
			for (uint256 _i = 0; _i < rewardIndex.length; _i++) {
				address _rewardToken = rewardIndex[_i];
				RewardInfo storage _rewardInfo = rewardInfo[_rewardToken];
				AccountRewardInfo storage _accountRewardInfo = _accountInfo.rewardInfo[_rewardToken];
				_accountRewardInfo.rewardDebt = _newShares * _rewardInfo.accRewardPerShare[weekIndex] / 1e36;
			}
		}
	}

	function _transfer(address _from, address _to, uint256 _amount) internal override
	{
		if (bypass_) {
			// internal transfer
			super._transfer(_from, _to, _amount);
			return;
		}

		if (inswap_) {
			// sell fee transfer
			super._transfer(_from, _to, _amount);
			return;
		}

		if (_from == pair) {
			// buying
			uint256 _feeAmount = excludeFromTradeFeeAsBuyer[_to] ? 0 : _amount * buyFee / 100e16;
			if (_feeAmount > 0) {
				super._transfer(_from, _to, _amount - _feeAmount);
				super._transfer(_from, address(this), _feeAmount);
			} else {
				super._transfer(_from, _to, _amount);
			}
			return;
		}

		if (_to == pair) {
			// selling
			uint256 _feeAmount = excludeFromTradeFeeAsSeller[_from] ? 0 : _amount * sellFee / 100e16;
			if (_feeAmount > 0) {
				super._transfer(_from, _to, _amount - _feeAmount);
				super._transfer(_from, address(this), _feeAmount);
			} else {
				super._transfer(_from, _to, _amount);
			}
			return;
		}

		// regular transfer
		super._transfer(_from, _to, _amount);

		{
			// piggyback operation
			// converts fees to BNB and injects as LVLX/BNB liquidity
			_updateAccount(address(this));
			_postUpdateAccount(address(this), 0);
			uint256 _balance = balanceOf(address(this));
			if (_balance >= minimumFeeBalanceToSwap) {
				inswap_ = true;
				uint256 _halfFeeLiquidityCut = feeLiquidityCut / 2;
				uint256 _swapAmount = _balance * (100e16 - _halfFeeLiquidityCut) / 100e16;
				uint256 _bnbAmount = _swapToBNB(_swapAmount);
				_injectWithBNB(_balance - _swapAmount, _bnbAmount * _halfFeeLiquidityCut / 100e16);
				inswap_ = false;
				return;
			}
		}

		{
			// piggyback operation
			// converts BNB to reward tokens, evenly
			uint256 _bnbAmount = address(this).balance;
			if (_bnbAmount > minimumRewardBalanceToSwap) {
				inswap_ = true;
				uint256 _bnbAmountSplit = _bnbAmount / (rewardIndex.length - 1);
				for (uint256 _i = 1; _i < rewardIndex.length; _i++) {
					address _rewardToken = rewardIndex[_i];
					_swapBNBToReward(_rewardToken, _bnbAmountSplit);
				}
				inswap_ = false;
				return;
			}
		}
	}

	function _beforeTokenTransfer(address _from, address _to, uint256 _amount) internal override
	{
		if (bypass_) return;
		_updateEpoch();
		if (_from != address(0)) {
			_updateAccount(_from);
		}
		if (_to != address(0)) {
			// internal address should never be used
			require(_to != INTERNAL_ADDRESS, "invalid address");
			_updateAccount(_to);
		}
		_amount; // silences warning
	}

	function _afterTokenTransfer(address _from, address _to, uint256 _amount) internal override
	{
		if (bypass_) return;
		if (_amount == 0) return;
		if (_from == _to) return;
		if (_from != address(0)) {
			_postUpdateAccount(_from, excludeFromTransferPenaltyAsSender[_from] || excludeFromTransferPenaltyAsReceiver[_to] ? int256(0) : -1);
		}
		if (_to != address(0)) {
			_postUpdateAccount(_to, 0);
		}
	}

	function _cachedExp(uint256 _x, uint256 _n) internal returns (uint256 _y)
	{
		_y = expCache[_x][_n];
		if (_y == 0) {
			_y = _exp(_x, _n);
			expCache[_x][_n] = _y;
		}
		return _y;
	}

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

	function _swapToBNB(uint256 _amount) internal returns (uint256 _bnbAmount)
	{
		// swaps LVLX to BNB
		uint256 _balance = address(this).balance;
		IUniswapV2Router(router).swapExactTokensForETHSupportingFeeOnTransferTokens(_amount, 0, pathWBNB, address(this), block.timestamp);
		return address(this).balance - _balance;
	}

	function _injectWithBNB(uint256 _amount, uint256 _bnbAmount) internal
	{
		// injects LVLX/BNB into the pool
		IUniswapV2Router(router).addLiquidityETH{value: _bnbAmount}(address(this), _amount, 0, 0, liquidityRecipient, block.timestamp);
	}

	function _swapBNBToReward(address _rewardToken, uint256 _bnbAmount) internal
	{
		// swaps BNB to reward
		// half is reflected, half is sent to bankroll
		RewardInfo storage _rewardInfo = rewardInfo[_rewardToken];
		uint256 _balance = IERC20(_rewardToken).balanceOf(address(this));
		IUniswapV2Router(router).swapExactETHForTokensSupportingFeeOnTransferTokens{value: _bnbAmount}(0, _rewardInfo.path, address(this), block.timestamp);
		uint256 _rewardAmount = IERC20(_rewardToken).balanceOf(address(this)) - _balance;
		IERC20(_rewardToken).safeTransfer(_rewardInfo.bankroll, _rewardAmount / 2);
	}

	receive() external payable {}

	event UpdateBuyFee(uint256 _buyFee);
	event UpdateSellFee(uint256 _sellFee);
	event UpdateFeeLiquidityCut(uint256 _feeLiquidityCut);
	event UpdateLiquidityRecipient(address _liquidityRecipient);
	event UpdateMinimumFeeBalanceToSwap(uint256 _minimumFeeBalanceToSwap);
	event UpdateMinimumRewardBalanceToSwap(uint256 _minimumRewardBalanceToSwap);
	event AddRewardToken(address indexed _rewardToken, address _bankroll, address[] _path);
	event UpdateRewardBankroll(address indexed _rewardToken, address _bankroll);
	event UpdateRewardPath(address indexed _rewardToken, address[] _path);
	event UpdateBurnAmountToBumpLevel(uint256 _burnAmountToBumpLevel);
	event UpdateMinimumBalanceForRewards(uint256 _minimumBalanceForRewards);
	event UpdateNextRebaseRatePerEpoch(uint256 _nextRebaseRatePerEpoch);
	event UpdateExpansionToRewardFactor(uint256 _expansionToRewardFactor);
	event UpdateExcludeFromTransferPenalty(address indexed _account, bool _enabledAsSender, bool _enabledAsReceiver);
	event UpdateExcludeFromTradeFee(address indexed _account, bool _enabledAsBuyer, bool _enabledAsSeller);
	event UpdateExcludeFromRewardsDefaultBehavior(address indexed _account, bool _enabled);
	event BumpLevel(address indexed _account);
	event Claim(address indexed _account, address indexed _rewardToken, uint256 _amount);
}