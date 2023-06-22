// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/SafeCastUpgradeable.sol";

import "./interfaces/IConcentratorGeneralVault.sol";
import "./interfaces/IConcentratorStrategy.sol";

import "../common/FeeCustomization.sol";
import "./ConcentratorBase.sol";

// solhint-disable no-empty-blocks
// solhint-disable reason-string
// solhint-disable not-rely-on-time

abstract contract ConcentratorGeneralVault is
  OwnableUpgradeable,
  ReentrancyGuardUpgradeable,
  FeeCustomization,
  ConcentratorBase,
  IConcentratorGeneralVault
{
  using SafeMathUpgradeable for uint256;
  using SafeERC20Upgradeable for IERC20Upgradeable;

  /// @notice Emitted when pool fee ratios are updated.
  /// @param _pid The pool id to update.
  /// @param _withdrawFeeRatio The new withdraw fee ratio updated.
  /// @param _platformFeeRatio The new platform fee ratio updated.
  /// @param _harvestBountyRatio The new harvest bounty ratio updated.
  event UpdatePoolFeeRatio(
    uint256 indexed _pid,
    uint32 _withdrawFeeRatio,
    uint32 _platformFeeRatio,
    uint32 _harvestBountyRatio
  );

  /// @notice Emitted when the platform address is updated.
  /// @param _platform The new platform address.
  event UpdatePlatform(address indexed _platform);

  /// @notice Emitted when pool assets migrated.
  /// @param _pid The pool id to migrate.
  /// @param _oldStrategy The address of old strategy.
  /// @param _newStrategy The address of current strategy.
  event Migrate(uint256 indexed _pid, address _oldStrategy, address _newStrategy);

  /// @notice Emitted when the length of reward period is updated.
  /// @param _pid The pool id to update.
  /// @param _period The new reward period.
  event UpdateRewardPeriod(uint256 indexed _pid, uint32 _period);

  /// @notice Emitted when the list of reward tokens is updated.
  /// @param _pid The pool id to update.
  /// @param _rewardTokens The new list of reward tokens.
  event UpdatePoolRewardTokens(uint256 indexed _pid, address[] _rewardTokens);

  /// @notice Emitted when a new pool is added.
  /// @param _pid The pool id added.
  /// @param _underlying The corresponding convex pool id.
  /// @param _strategy The list of reward tokens.
  event AddPool(uint256 indexed _pid, address _underlying, address _strategy);

  /// @notice Emitted when deposit is paused for the pool.
  /// @param _pid The pool id to update.
  /// @param _status The new status.
  event PausePoolDeposit(uint256 indexed _pid, bool _status);

  /// @notice Emitted when withdraw is paused for the pool.
  /// @param _pid The pool id to update.
  /// @param _status The new status.
  event PausePoolWithdraw(uint256 indexed _pid, bool _status);

  /// @dev Compiler will pack this into two `uint256`.
  struct PoolRewardInfo {
    // The current reward rate per second.
    uint128 rate;
    // The length of reward period in seconds.
    // If the value is zero, the reward will be distributed immediately.
    uint32 periodLength;
    // The timesamp in seconds when reward is updated.
    uint48 lastUpdate;
    // The finish timestamp in seconds of current reward period.
    uint48 finishAt;
    // The accumulated acrv reward per share, with 1e18 precision.
    uint256 accRewardPerShare;
  }

  /// @dev Compiler will pack this into single `uint256`.
  struct PoolSupplyInfo {
    // The amount of total deposited token.
    uint128 totalUnderlying;
    // The amount of total deposited shares.
    uint128 totalShare;
  }

  /// @dev Compiler will pack this into single `uint256`.
  struct PoolFeeInfo {
    // The withdraw fee rate, with 1e9 precision.
    uint32 withdrawFeeRatio;
    // The platform fee rate, with 1e9 precision.
    uint32 platformFeeRatio;
    // The harvest bounty rate, with 1e9 precision.
    uint32 harvestBountyRatio;
    // reserved entry for future use.
    uint160 reserved;
  }

  /// @dev Compiler will pack this into two `uint256`.
  struct PoolStrategyInfo {
    // The address of staking token.
    address token;
    // The address of strategy contract.
    address strategy;
    // Whether deposit for the pool is paused.
    bool pauseDeposit;
    // Whether withdraw for the pool is paused.
    bool pauseWithdraw;
  }

  struct PoolInfo {
    PoolSupplyInfo supply; // 1 uint256
    PoolStrategyInfo strategy; // 2 uint256
    PoolRewardInfo reward; // 2 uint256
    PoolFeeInfo fee; // 1 uint256
  }

  struct UserInfo {
    // The amount of shares the user deposited.
    uint128 shares;
    // The amount of current accrued rewards.
    uint128 rewards;
    // The reward per share already paid for the user, with 1e18 precision.
    uint256 rewardPerSharePaid;
    // mapping from spender to allowance.
    mapping(address => uint256) allowances;
  }

  /// @dev The type for withdraw fee, used in FeeCustomization.
  bytes32 internal constant WITHDRAW_FEE_TYPE = keccak256("ConcentratorGeneralVault.WithdrawFee");

  /// @dev The precision used to calculate accumulated rewards.
  uint256 internal constant REWARD_PRECISION = 1e18;

  /// @dev The maximum percentage of withdraw fee.
  uint256 internal constant MAX_WITHDRAW_FEE = 1e8; // 10%

  /// @dev The maximum percentage of platform fee.
  uint256 internal constant MAX_PLATFORM_FEE = 2e8; // 20%

  /// @dev The maximum percentage of harvest bounty.
  uint256 internal constant MAX_HARVEST_BOUNTY = 1e8; // 10%

  /// @dev The number of seconds in one week.
  uint256 internal constant WEEK = 86400 * 7;

  /// @notice Mapping from pool id to pool information.
  mapping(uint256 => PoolInfo) public poolInfo;

  /// @notice Mapping from pool id to account address to user share info.
  mapping(uint256 => mapping(address => UserInfo)) public userInfo;

  /// @dev The next unused pool id.
  uint256 private poolIndex;

  /// @notice The address of recipient of platform fee
  address public platform;

  /// @notice The address of ZAP contract, will be used to swap tokens.
  address public zap;

  /// @dev The reserved slots.
  uint256[45] private __gap;

  modifier onlyExistPool(uint256 _pid) {
    require(_pid < poolIndex, "Concentrator: pool not exist");
    _;
  }

  // fallback function to receive eth.
  receive() external payable {}

  function _initialize(address _zap, address _platform) internal {
    OwnableUpgradeable.__Ownable_init();
    ReentrancyGuardUpgradeable.__ReentrancyGuard_init();

    require(_zap != address(0), "Concentrator: zero zap address");
    require(_platform != address(0), "Concentrator: zero platform address");

    platform = _platform;
    zap = _zap;
  }

  /********************************** View Functions **********************************/

  /// @inheritdoc IConcentratorGeneralVault
  function rewardToken() public view virtual override returns (address) {}

  /// @notice Returns the number of pools.
  function poolLength() external view returns (uint256 pools) {
    pools = poolIndex;
  }

  /// @inheritdoc IConcentratorGeneralVault
  function pendingReward(uint256 _pid, address _account) public view override returns (uint256) {
    PoolInfo storage _pool = poolInfo[_pid];
    PoolRewardInfo memory _reward = _pool.reward;
    PoolSupplyInfo memory _supply = _pool.supply;

    if (_reward.periodLength > 0) {
      uint256 _currentTime = _reward.finishAt;
      if (_currentTime > block.timestamp) _currentTime = block.timestamp;
      uint256 _duration = _currentTime >= _reward.lastUpdate ? _currentTime - _reward.lastUpdate : 0;
      if (_duration > 0 && _supply.totalShare > 0) {
        _reward.accRewardPerShare = _reward.accRewardPerShare.add(
          _duration.mul(_reward.rate).mul(REWARD_PRECISION) / _supply.totalShare
        );
      }
    }

    return _pendingReward(_pid, _account, _reward.accRewardPerShare);
  }

  /// @inheritdoc IConcentratorGeneralVault
  function pendingRewardAll(address _account) external view override returns (uint256) {
    uint256 _length = poolIndex;
    uint256 _pending;
    for (uint256 i = 0; i < _length; i++) {
      _pending += pendingReward(i, _account);
    }
    return _pending;
  }

  /// @inheritdoc IConcentratorGeneralVault
  function getUserShare(uint256 _pid, address _account) external view override returns (uint256) {
    return userInfo[_pid][_account].shares;
  }

  /// @inheritdoc IConcentratorGeneralVault
  function underlying(uint256 _pid) external view override returns (address) {
    return poolInfo[_pid].strategy.token;
  }

  /// @inheritdoc IConcentratorGeneralVault
  function getTotalUnderlying(uint256 _pid) external view override returns (uint256) {
    return poolInfo[_pid].supply.totalUnderlying;
  }

  /// @inheritdoc IConcentratorGeneralVault
  function getTotalShare(uint256 _pid) external view override returns (uint256) {
    return poolInfo[_pid].supply.totalShare;
  }

  /// @inheritdoc IConcentratorGeneralVault
  function allowance(
    uint256 _pid,
    address _owner,
    address _spender
  ) external view override returns (uint256) {
    UserInfo storage _info = userInfo[_pid][_owner];
    return _info.allowances[_spender];
  }

  /********************************** Mutated Functions **********************************/

  /// @inheritdoc IConcentratorGeneralVault
  function approve(
    uint256 _pid,
    address _spender,
    uint256 _amount
  ) external override {
    _approve(_pid, msg.sender, _spender, _amount);
  }

  /// @inheritdoc IConcentratorGeneralVault
  function deposit(
    uint256 _pid,
    address _recipient,
    uint256 _assetsIn
  ) public override onlyExistPool(_pid) nonReentrant returns (uint256) {
    PoolStrategyInfo memory _strategy = poolInfo[_pid].strategy;
    require(!_strategy.pauseDeposit, "Concentrator: deposit paused");

    if (_assetsIn == uint256(-1)) {
      _assetsIn = IERC20Upgradeable(_strategy.token).balanceOf(msg.sender);
    }
    require(_assetsIn > 0, "Concentrator: deposit zero amount");

    // 1. update rewards
    _updateRewards(_pid, _recipient);

    // 2. transfer user token
    uint256 _before = IERC20Upgradeable(_strategy.token).balanceOf(_strategy.strategy);
    IERC20Upgradeable(_strategy.token).safeTransferFrom(msg.sender, _strategy.strategy, _assetsIn);
    _assetsIn = IERC20Upgradeable(_strategy.token).balanceOf(_strategy.strategy) - _before;

    // 3. deposit
    return _deposit(_pid, _recipient, _assetsIn);
  }

  /// @inheritdoc IConcentratorGeneralVault
  function withdraw(
    uint256 _pid,
    uint256 _sharesIn,
    address _recipient,
    address _owner
  ) public override onlyExistPool(_pid) nonReentrant returns (uint256) {
    if (_sharesIn == uint256(-1)) {
      _sharesIn = userInfo[_pid][_owner].shares;
    }
    require(_sharesIn > 0, "Concentrator: withdraw zero share");

    if (msg.sender != _owner) {
      UserInfo storage _info = userInfo[_pid][_owner];
      uint256 _allowance = _info.allowances[msg.sender];
      require(_allowance >= _sharesIn, "Concentrator: withdraw exceeds allowance");
      if (_allowance != uint256(-1)) {
        // decrease allowance if it is not max
        _approve(_pid, _owner, msg.sender, _allowance - _sharesIn);
      }
    }

    // 1. update rewards
    PoolInfo storage _pool = poolInfo[_pid];
    require(!_pool.strategy.pauseWithdraw, "Concentrator: withdraw paused");
    _updateRewards(_pid, _owner);

    // 2. withdraw lp token
    return _withdraw(_pid, _sharesIn, _owner, _recipient);
  }

  /// @inheritdoc IConcentratorGeneralVault
  function claim(
    uint256 _pid,
    address _recipient,
    uint256 _minOut,
    address _claimAsToken
  ) public override onlyExistPool(_pid) nonReentrant returns (uint256) {
    _updateRewards(_pid, msg.sender);

    UserInfo storage _userInfo = userInfo[_pid][msg.sender];
    uint256 _rewards = _userInfo.rewards;
    _userInfo.rewards = 0;

    emit Claim(_pid, msg.sender, _recipient, _rewards);

    _rewards = _claim(_rewards, _minOut, _recipient, _claimAsToken);
    return _rewards;
  }

  /// @inheritdoc IConcentratorGeneralVault
  function claimMulti(
    uint256[] memory _pids,
    address _recipient,
    uint256 _minOut,
    address _claimAsToken
  ) public override nonReentrant returns (uint256) {
    uint256 _poolIndex = poolIndex;
    uint256 _rewards;
    for (uint256 i = 0; i < _pids.length; i++) {
      uint256 _pid = _pids[i];
      require(_pid < _poolIndex, "Concentrator: pool not exist");

      UserInfo storage _userInfo = userInfo[_pid][msg.sender];
      // update if user has share
      if (_userInfo.shares > 0) {
        _updateRewards(_pid, msg.sender);
      }
      // withdraw if user has reward
      if (_userInfo.rewards > 0) {
        _rewards = _rewards.add(_userInfo.rewards);
        emit Claim(_pid, msg.sender, _recipient, _userInfo.rewards);

        _userInfo.rewards = 0;
      }
    }

    return _claim(_rewards, _minOut, _recipient, _claimAsToken);
  }

  /// @inheritdoc IConcentratorGeneralVault
  function claimAll(
    uint256 _minOut,
    address _recipient,
    address _claimAsToken
  ) external override nonReentrant returns (uint256) {
    uint256 _length = poolIndex;
    uint256 _rewards;
    for (uint256 _pid = 0; _pid < _length; _pid++) {
      UserInfo storage _userInfo = userInfo[_pid][msg.sender];
      // update if user has share
      if (_userInfo.shares > 0) {
        _updateRewards(_pid, msg.sender);
      }
      // withdraw if user has reward
      if (_userInfo.rewards > 0) {
        _rewards = _rewards.add(_userInfo.rewards);
        emit Claim(_pid, msg.sender, _recipient, _userInfo.rewards);

        _userInfo.rewards = 0;
      }
    }

    return _claim(_rewards, _minOut, _recipient, _claimAsToken);
  }

  /// @inheritdoc IConcentratorGeneralVault
  function harvest(
    uint256 _pid,
    address _recipient,
    uint256 _minOut
  ) external virtual override onlyExistPool(_pid) nonReentrant returns (uint256) {
    ensureCallerIsHarvester();

    // 1. update global pending rewards
    _updateRewards(_pid, address(0));

    // 2. harvest rewards from strategy
    uint256 _rewards = _harvest(_pid);
    require(_rewards >= _minOut, "Concentrator: insufficient rewards");

    // 3. distribute rewards to platform and _recipient
    address _token = rewardToken();
    PoolFeeInfo memory _fees = poolInfo[_pid].fee;
    uint256 _platformFee;
    uint256 _harvestBounty;
    if (_fees.platformFeeRatio > 0) {
      _platformFee = (uint256(_fees.platformFeeRatio) * _rewards) / FEE_PRECISION;
      IERC20Upgradeable(_token).safeTransfer(platform, _platformFee);
    }
    if (_fees.harvestBountyRatio > 0) {
      _harvestBounty = (uint256(_fees.harvestBountyRatio) * _rewards) / FEE_PRECISION;
      IERC20Upgradeable(_token).safeTransfer(_recipient, _harvestBounty);
    }

    emit Harvest(_pid, msg.sender, _recipient, _rewards, _platformFee, _harvestBounty);

    // 4. distribute rest rewards to users
    _notifyHarvestedReward(_pid, _rewards - _platformFee - _harvestBounty);

    return _rewards;
  }

  /// @notice Checkpoint account state.
  /// @param _pid The pool id.
  /// @param _account The address of user to checkpoint.
  function checkpoint(uint256 _pid, address _account) external {
    _updateRewards(_pid, _account);
  }

  /********************************** Restricted Functions **********************************/

  /// @notice Update the pool fee ratios.
  /// @param _pid The pool id.
  /// @param _withdrawFeeRatio The withdraw fee ratio to update.
  /// @param _platformFeeRatio The platform fee ratio to update.
  /// @param _harvestBountyRatio The harvest bounty fee ratio to update.
  function updatePoolFeeRatio(
    uint256 _pid,
    uint32 _withdrawFeeRatio,
    uint32 _platformFeeRatio,
    uint32 _harvestBountyRatio
  ) external onlyExistPool(_pid) onlyOwner {
    require(_withdrawFeeRatio <= MAX_WITHDRAW_FEE, "Concentrator: withdraw fee too large");
    require(_platformFeeRatio <= MAX_PLATFORM_FEE, "Concentrator: platform fee too large");
    require(_harvestBountyRatio <= MAX_HARVEST_BOUNTY, "Concentrator: harvest bounty too large");

    poolInfo[_pid].fee = PoolFeeInfo({
      withdrawFeeRatio: _withdrawFeeRatio,
      platformFeeRatio: _platformFeeRatio,
      harvestBountyRatio: _harvestBountyRatio,
      reserved: 0
    });

    emit UpdatePoolFeeRatio(_pid, _withdrawFeeRatio, _platformFeeRatio, _harvestBountyRatio);
  }

  /// @notice Update withdraw fee for certain user.
  /// @param _pid The pool id.
  /// @param _user The address of user to update.
  /// @param _ratio The withdraw fee ratio to be updated, multipled by 1e9.
  function setWithdrawFeeForUser(
    uint256 _pid,
    address _user,
    uint32 _ratio
  ) external onlyExistPool(_pid) onlyOwner {
    require(_ratio <= MAX_WITHDRAW_FEE, "Concentrator: withdraw fee too large");

    _setFeeCustomization(_getWithdrawFeeType(_pid), _user, _ratio);
  }

  /// @notice Update the recipient for platform fee.
  /// @param _platform The address of new platform.
  function updatePlatform(address _platform) external onlyOwner {
    require(_platform != address(0), "Concentrator: zero platform address");
    platform = _platform;

    emit UpdatePlatform(_platform);
  }

  /// @notice Update the zap contract
  function updateZap(address _zap) external onlyOwner {
    require(_zap != address(0), "Concentrator: zero zap address");
    zap = _zap;

    emit UpdateZap(_zap);
  }

  /// @notice Update the harvester contract
  /// @param _harvester The address of the harvester contract.
  function updateHarvester(address _harvester) external onlyOwner {
    _updateHarvester(_harvester);
  }

  /// @notice Add new Convex pool.
  /// @param _underlying The address of staking token.
  /// @param _strategy The address of corresponding strategy.
  /// @param _withdrawFeeRatio The default withdraw fee ratio of the pool.
  /// @param _platformFeeRatio The platform fee ratio of the pool.
  /// @param _harvestBountyRatio The harvest bounty ratio of the pool.
  function addPool(
    address _underlying,
    address _strategy,
    uint32 _withdrawFeeRatio,
    uint32 _platformFeeRatio,
    uint32 _harvestBountyRatio
  ) external onlyOwner {
    require(_withdrawFeeRatio <= MAX_WITHDRAW_FEE, "Concentrator: withdraw fee too large");
    require(_platformFeeRatio <= MAX_PLATFORM_FEE, "Concentrator: platform fee too large");
    require(_harvestBountyRatio <= MAX_HARVEST_BOUNTY, "Concentrator: harvest bounty too large");

    uint256 _pid = poolIndex;
    poolIndex = _pid + 1;

    poolInfo[_pid].strategy = PoolStrategyInfo({
      token: _underlying,
      strategy: _strategy,
      pauseDeposit: false,
      pauseWithdraw: false
    });

    poolInfo[_pid].fee = PoolFeeInfo({
      withdrawFeeRatio: _withdrawFeeRatio,
      platformFeeRatio: _platformFeeRatio,
      harvestBountyRatio: _harvestBountyRatio,
      reserved: 0
    });

    emit AddPool(_pid, _underlying, _strategy);
  }

  /// @notice update reward period
  /// @param _pid The pool id.
  /// @param _period The length of the period
  function updateRewardPeriod(uint256 _pid, uint32 _period) external onlyExistPool(_pid) onlyOwner {
    require(_period <= WEEK, "Concentrator: reward period too long");

    poolInfo[_pid].reward.periodLength = _period;

    emit UpdateRewardPeriod(_pid, _period);
  }

  /// @notice update reward tokens
  /// @param _pid The pool id.
  /// @param _rewardTokens The address list of new reward tokens.
  function updatePoolRewardTokens(uint256 _pid, address[] memory _rewardTokens) external onlyExistPool(_pid) onlyOwner {
    IConcentratorStrategy(poolInfo[_pid].strategy.strategy).updateRewards(_rewardTokens);

    emit UpdatePoolRewardTokens(_pid, _rewardTokens);
  }

  /// @notice Pause withdraw for specific pool.
  /// @param _pid The pool id.
  /// @param _status The status to update.
  function pausePoolWithdraw(uint256 _pid, bool _status) external onlyExistPool(_pid) onlyOwner {
    poolInfo[_pid].strategy.pauseWithdraw = _status;

    emit PausePoolWithdraw(_pid, _status);
  }

  /// @notice Pause deposit for specific pool.
  /// @param _pid The pool id.
  /// @param _status The status to update.
  function pausePoolDeposit(uint256 _pid, bool _status) external onlyExistPool(_pid) onlyOwner {
    poolInfo[_pid].strategy.pauseDeposit = _status;

    emit PausePoolDeposit(_pid, _status);
  }

  /// @notice Migrate pool assets to new strategy.
  /// @param _pid The pool id.
  /// @param _newStrategy The address of new strategy.
  function migrateStrategy(uint256 _pid, address _newStrategy) external onlyExistPool(_pid) onlyOwner {
    uint256 _totalUnderlying = poolInfo[_pid].supply.totalUnderlying;
    address _oldStrategy = poolInfo[_pid].strategy.strategy;
    poolInfo[_pid].strategy.strategy = _newStrategy;

    IConcentratorStrategy(_oldStrategy).prepareMigrate(_newStrategy);
    IConcentratorStrategy(_oldStrategy).withdraw(_newStrategy, _totalUnderlying);
    IConcentratorStrategy(_oldStrategy).finishMigrate(_newStrategy);
    IConcentratorStrategy(_newStrategy).deposit(address(this), _totalUnderlying);

    emit Migrate(_pid, _oldStrategy, _newStrategy);
  }

  /********************************** Internal Functions **********************************/

  /// @dev Internal function to return the amount of pending rewards.
  /// @param _pid The pool id to query.
  /// @param _account The address of account to query.
  /// @param _accRewardPerShare Hint used to compute rewards.
  function _pendingReward(
    uint256 _pid,
    address _account,
    uint256 _accRewardPerShare
  ) internal view returns (uint256) {
    UserInfo storage _userInfo = userInfo[_pid][_account];
    return
      uint256(_userInfo.rewards).add(
        _accRewardPerShare.sub(_userInfo.rewardPerSharePaid).mul(_userInfo.shares) / REWARD_PRECISION
      );
  }

  /// @dev Internal function to reward checkpoint.
  /// @param _pid The pool id to update.
  /// @param _account The address of account to update.
  function _updateRewards(uint256 _pid, address _account) internal virtual {
    PoolInfo storage _pool = poolInfo[_pid];

    // 1. update global information
    PoolRewardInfo memory _poolRewardInfo = _pool.reward;
    PoolSupplyInfo memory _supply = _pool.supply;
    if (_poolRewardInfo.periodLength > 0) {
      uint256 _currentTime = _poolRewardInfo.finishAt;
      if (_currentTime > block.timestamp) {
        _currentTime = block.timestamp;
      }
      uint256 _duration = _currentTime >= _poolRewardInfo.lastUpdate ? _currentTime - _poolRewardInfo.lastUpdate : 0;
      if (_duration > 0) {
        _poolRewardInfo.lastUpdate = uint48(block.timestamp);
        if (_supply.totalShare > 0) {
          _poolRewardInfo.accRewardPerShare = _poolRewardInfo.accRewardPerShare.add(
            _duration.mul(_poolRewardInfo.rate).mul(REWARD_PRECISION) / _supply.totalShare
          );
        }

        _pool.reward = _poolRewardInfo;
      }
    }

    // 2. update user information
    if (_account != address(0)) {
      uint256 _rewards = _pendingReward(_pid, _account, _poolRewardInfo.accRewardPerShare);
      UserInfo storage _userInfo = userInfo[_pid][_account];

      _userInfo.rewards = SafeCastUpgradeable.toUint128(_rewards);
      _userInfo.rewardPerSharePaid = _poolRewardInfo.accRewardPerShare;
    }
  }

  /// @dev Internal function to deposit token to strategy.
  /// @param _pid The pool id to deposit.
  /// @param _recipient The address of the recipient.
  /// @param _assetsIn The amount of underlying assets to deposit.
  /// @return The amount of pool shares received.
  function _deposit(
    uint256 _pid,
    address _recipient,
    uint256 _assetsIn
  ) internal returns (uint256) {
    PoolInfo storage _pool = poolInfo[_pid];

    IConcentratorStrategy(_pool.strategy.strategy).deposit(_recipient, _assetsIn);

    PoolSupplyInfo memory _supply = _pool.supply;
    uint256 _sharesOut;
    if (_supply.totalShare == 0) {
      _sharesOut = _assetsIn;
    } else {
      _sharesOut = _assetsIn.mul(_supply.totalShare) / _supply.totalUnderlying;
    }
    _supply.totalShare = _supply.totalShare + uint128(_sharesOut);
    _supply.totalUnderlying = _supply.totalUnderlying + uint128(_assetsIn);
    _pool.supply = _supply;

    UserInfo storage _userInfo = userInfo[_pid][_recipient];
    _userInfo.shares = uint128(_sharesOut + _userInfo.shares);

    emit Deposit(_pid, msg.sender, _recipient, _assetsIn, _sharesOut);
    return _sharesOut;
  }

  /// @dev Internal function to withdraw underlying assets from convex booster.
  /// @param _pid The pool id to deposit.
  /// @param _sharesIn The amount of pool shares to withdraw.
  /// @param _owner The address of user to withdraw from.
  /// @param _recipient The address of the recipient.
  /// @return The amount of underlying assets received.
  function _withdraw(
    uint256 _pid,
    uint256 _sharesIn,
    address _owner,
    address _recipient
  ) internal returns (uint256) {
    PoolInfo storage _pool = poolInfo[_pid];

    // 2. withdraw lp token
    UserInfo storage _userInfo = userInfo[_pid][_owner];
    require(_sharesIn <= _userInfo.shares, "Concentrator: exceed user shares");

    PoolSupplyInfo memory _supply = _pool.supply;
    uint256 _assetsOut;
    if (_sharesIn == _supply.totalShare) {
      // If user is last to withdraw, don't take withdraw fee.
      // And there may still have some pending rewards, we just simple ignore it now.
      // If we want the reward later, we can upgrade the contract.
      _assetsOut = _supply.totalUnderlying;
    } else {
      uint256 _withdrawFeeRatio = getFeeRate(_getWithdrawFeeType(_pid), _owner);
      // take withdraw fee here
      _assetsOut = _sharesIn.mul(_supply.totalUnderlying) / _supply.totalShare;
      uint256 _fee = _assetsOut.mul(_withdrawFeeRatio) / FEE_PRECISION;
      _assetsOut = _assetsOut - _fee; // never overflow
    }

    _supply.totalShare = _supply.totalShare - uint128(_sharesIn);
    _supply.totalUnderlying = _supply.totalUnderlying - uint128(_assetsOut);
    _pool.supply = _supply;

    _userInfo.shares = _userInfo.shares - uint128(_sharesIn);

    IConcentratorStrategy(_pool.strategy.strategy).withdraw(_recipient, _assetsOut);

    emit Withdraw(_pid, msg.sender, _owner, _recipient, _sharesIn, _assetsOut);

    return _assetsOut;
  }

  /// @dev Internal function to update allowance.
  /// @param _pid The pool id to query.
  /// @param _owner The address of the owner.
  /// @param _spender The address of the spender.
  /// @param _amount The amount of allowance.
  function _approve(
    uint256 _pid,
    address _owner,
    address _spender,
    uint256 _amount
  ) internal {
    require(_owner != address(0), "Concentrator: approve from the zero address");
    require(_spender != address(0), "Concentrator: approve to the zero address");

    UserInfo storage _info = userInfo[_pid][_owner];
    _info.allowances[_spender] = _amount;
    emit Approval(_pid, _owner, _spender, _amount);
  }

  /// @dev Internal function to notify harvested rewards.
  /// @dev The caller should make sure `_updateRewards` is called before.
  /// @param _pid The pool id to notify.
  /// @param _amount The amount of harvested rewards.
  function _notifyHarvestedReward(uint256 _pid, uint256 _amount) internal virtual {
    require(_amount < uint128(-1), "Concentrator: harvested amount overflow");
    PoolRewardInfo memory _info = poolInfo[_pid].reward;

    if (_info.periodLength == 0) {
      _info.accRewardPerShare = _info.accRewardPerShare.add(
        _amount.mul(REWARD_PRECISION) / poolInfo[_pid].supply.totalShare
      );
    } else {
      if (block.timestamp >= _info.finishAt) {
        _info.rate = uint128(_amount / _info.periodLength);
      } else {
        uint256 _remaining = _info.finishAt - block.timestamp;
        uint256 _leftover = _remaining * _info.rate;
        _info.rate = uint128((_amount + _leftover) / _info.periodLength);
      }

      _info.lastUpdate = uint48(block.timestamp);
      _info.finishAt = uint48(block.timestamp + _info.periodLength);
    }

    poolInfo[_pid].reward = _info;
  }

  /// @dev Internal function to get the withdraw fee type for pool.
  /// @param _pid The pool id.
  function _getWithdrawFeeType(uint256 _pid) internal pure returns (bytes32) {
    return bytes32(uint256(WITHDRAW_FEE_TYPE) + _pid);
  }

  /// @inheritdoc FeeCustomization
  function _defaultFeeRate(bytes32 _feeType) internal view override returns (uint256 rate) {
    uint256 _pid = uint256(_feeType) - uint256(WITHDRAW_FEE_TYPE);
    rate = poolInfo[_pid].fee.withdrawFeeRatio;
  }

  /// @dev Internal function to claim reward token.
  /// @param _amount The amount of to claim
  /// @param _minOut The minimum amount of pending reward to receive.
  /// @param _recipient The address of account who will receive the rewards.
  /// @param _claimAsToken The address of token to claim as. Use address(0) if claim as ETH.
  /// @return The amount of reward sent to the recipient.
  function _claim(
    uint256 _amount,
    uint256 _minOut,
    address _recipient,
    address _claimAsToken
  ) internal virtual returns (uint256) {}

  /// @dev Internal function to harvest strategy rewards to reward token.
  /// @param _pid The pool id to harvest.
  /// @return The amount of reward token harvested.
  function _harvest(uint256 _pid) internal virtual returns (uint256) {}
}