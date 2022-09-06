// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/SafeCastUpgradeable.sol";

import "./interfaces/IConcentratorConvexVault.sol";
import "../interfaces/IConvexBooster.sol";
import "../interfaces/IConvexBasicRewards.sol";

// solhint-disable no-empty-blocks, reason-string, not-rely-on-time
abstract contract ConcentratorConvexVault is OwnableUpgradeable, ReentrancyGuardUpgradeable, IConcentratorConvexVault {
  using SafeMathUpgradeable for uint256;
  using SafeERC20Upgradeable for IERC20Upgradeable;

  /// @notice Emitted when withdraw fee percentage is updated.
  /// @param _pid The pool id to update.
  /// @param _feePercentage The new fee percentage.
  event UpdateWithdrawalFeePercentage(uint256 indexed _pid, uint256 _feePercentage);

  /// @notice Emitted when platform fee percentage is updated.
  /// @param _pid The pool id to update.
  /// @param _feePercentage The new fee percentage.
  event UpdatePlatformFeePercentage(uint256 indexed _pid, uint256 _feePercentage);

  /// @notice Emitted when harvest bounty percentage is updated.
  /// @param _pid The pool id to update.
  /// @param _feePercentage The new fee percentage.
  event UpdateHarvestBountyPercentage(uint256 indexed _pid, uint256 _feePercentage);

  /// @notice Emitted when the platform address is updated.
  /// @param _platform The new platform address.
  event UpdatePlatform(address indexed _platform);

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
  /// @param _convexPid The corresponding convex pool id.
  /// @param _rewardTokens The list of reward tokens.
  event AddPool(uint256 indexed _pid, uint256 _convexPid, address[] _rewardTokens);

  /// @notice Emitted when deposit is paused for the pool.
  /// @param _pid The pool id to update.
  /// @param _status The new status.
  event PausePoolDeposit(uint256 indexed _pid, bool _status);

  /// @notice Emitted when withdraw is paused for the pool.
  /// @param _pid The pool id to update.
  /// @param _status The new status.
  event PausePoolWithdraw(uint256 indexed _pid, bool _status);

  /// @dev Compiler will pack this into single `uint256`.
  struct RewardInfo {
    // The current reward rate per second.
    uint128 rate;
    // The length of reward period in seconds.
    // If the value is zero, the reward will be distributed immediately.
    uint32 periodLength;
    // The timesamp in seconds when reward is updated.
    uint48 lastUpdate;
    // The finish timestamp in seconds of current reward period.
    uint48 finishAt;
  }

  struct PoolInfo {
    // The amount of total deposited token.
    uint128 totalUnderlying;
    // The amount of total deposited shares.
    uint128 totalShare;
    // The accumulated acrv reward per share, with 1e18 precision.
    uint256 accRewardPerShare;
    // The pool id in Convex Booster.
    uint256 convexPoolId;
    // The address of deposited token.
    address lpToken;
    // The address of Convex reward contract.
    address crvRewards;
    // The withdraw fee percentage, with 1e9 precision.
    uint256 withdrawFeePercentage;
    // The platform fee percentage, with 1e9 precision.
    uint256 platformFeePercentage;
    // The harvest bounty percentage, with 1e9 precision.
    uint256 harvestBountyPercentage;
    // Whether deposit for the pool is paused.
    bool pauseDeposit;
    // Whether withdraw for the pool is paused.
    bool pauseWithdraw;
    // The list of addresses of convex reward tokens.
    address[] convexRewardTokens;
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

  /// @dev The precision used to calculate accumulated rewards.
  uint256 internal constant PRECISION = 1e18;

  /// @dev The fee denominator used for percentage calculation.
  uint256 internal constant FEE_DENOMINATOR = 1e9;

  /// @dev The maximum percentage of withdraw fee.
  uint256 internal constant MAX_WITHDRAW_FEE = 1e8; // 10%

  /// @dev The maximum percentage of platform fee.
  uint256 internal constant MAX_PLATFORM_FEE = 2e8; // 20%

  /// @dev The maximum percentage of harvest bounty.
  uint256 internal constant MAX_HARVEST_BOUNTY = 1e8; // 10%

  /// @dev The number of seconds in one week.
  uint256 internal constant WEEK = 86400 * 7;

  /// @dev The address of Convex Booster Contract
  address private constant BOOSTER = 0xF403C135812408BFbE8713b5A23a04b3D48AAE31;

  /// @notice The list of all supported pool.
  PoolInfo[] public poolInfo;

  /// @notice The list of reward info for all supported pool.
  RewardInfo[] public rewardInfo;

  /// @notice Mapping from pool id to account address to user share info.
  mapping(uint256 => mapping(address => UserInfo)) public userInfo;

  /// @notice The address of recipient of platform fee
  address public platform;

  modifier onlyExistPool(uint256 _pid) {
    require(_pid < poolInfo.length, "pool not exist");
    _;
  }

  receive() external payable {}

  function _initialize(address _platform) internal {
    OwnableUpgradeable.__Ownable_init();
    ReentrancyGuardUpgradeable.__ReentrancyGuard_init();

    require(_platform != address(0), "zero platform address");

    platform = _platform;
  }

  /********************************** View Functions **********************************/

  /// @inheritdoc IConcentratorConvexVault
  function rewardToken() public view virtual override returns (address) {}

  /// @notice Returns the number of pools.
  function poolLength() external view returns (uint256 pools) {
    pools = poolInfo.length;
  }

  /// @inheritdoc IConcentratorConvexVault
  function pendingReward(uint256 _pid, address _account) public view override returns (uint256) {
    PoolInfo storage _pool = poolInfo[_pid];
    RewardInfo memory _rewardInfo = rewardInfo[_pid];

    uint256 _accRewardPerShare = _pool.accRewardPerShare;
    if (_rewardInfo.periodLength > 0) {
      uint256 _currentTime = _rewardInfo.finishAt;
      // solhint-disable-next-line not-rely-on-time
      if (_currentTime > block.timestamp) _currentTime = block.timestamp;
      uint256 _duration = _currentTime >= _rewardInfo.lastUpdate ? _currentTime - _rewardInfo.lastUpdate : 0;
      if (_duration > 0 && _pool.totalShare > 0) {
        _accRewardPerShare = _accRewardPerShare.add(_duration.mul(_rewardInfo.rate).mul(PRECISION) / _pool.totalShare);
      }
    }

    return _pendingReward(_pid, _account, _accRewardPerShare);
  }

  /// @inheritdoc IConcentratorConvexVault
  function pendingRewardAll(address _account) external view override returns (uint256) {
    uint256 _pending;
    for (uint256 i = 0; i < poolInfo.length; i++) {
      _pending += pendingReward(i, _account);
    }
    return _pending;
  }

  /// @inheritdoc IConcentratorConvexVault
  function getUserShare(uint256 _pid, address _account) external view override returns (uint256) {
    return userInfo[_pid][_account].shares;
  }

  /// @inheritdoc IConcentratorConvexVault
  function underlying(uint256 _pid) external view override returns (address) {
    return poolInfo[_pid].lpToken;
  }

  /// @inheritdoc IConcentratorConvexVault
  function getTotalUnderlying(uint256 _pid) external view override returns (uint256) {
    return poolInfo[_pid].totalUnderlying;
  }

  /// @inheritdoc IConcentratorConvexVault
  function getTotalShare(uint256 _pid) external view override returns (uint256) {
    return poolInfo[_pid].totalShare;
  }

  /// @inheritdoc IConcentratorConvexVault
  function allowance(
    uint256 _pid,
    address _owner,
    address _spender
  ) external view override returns (uint256) {
    UserInfo storage _info = userInfo[_pid][_owner];
    return _info.allowances[_spender];
  }

  /********************************** Mutated Functions **********************************/

  /// @inheritdoc IConcentratorConvexVault
  function approve(
    uint256 _pid,
    address _spender,
    uint256 _amount
  ) external override {
    _approve(_pid, msg.sender, _spender, _amount);
  }

  /// @inheritdoc IConcentratorConvexVault
  function deposit(
    uint256 _pid,
    address _recipient,
    uint256 _assetsIn
  ) public override onlyExistPool(_pid) nonReentrant returns (uint256) {
    if (_assetsIn == uint256(-1)) {
      _assetsIn = IERC20Upgradeable(poolInfo[_pid].lpToken).balanceOf(msg.sender);
    }
    require(_assetsIn > 0, "deposit zero amount");

    // 1. update rewards
    PoolInfo storage _pool = poolInfo[_pid];
    require(!_pool.pauseDeposit, "pool paused");
    _updateRewards(_pid, _recipient);

    // 2. transfer user token
    address _lpToken = _pool.lpToken;
    {
      uint256 _before = IERC20Upgradeable(_lpToken).balanceOf(address(this));
      IERC20Upgradeable(_lpToken).safeTransferFrom(msg.sender, address(this), _assetsIn);
      _assetsIn = IERC20Upgradeable(_lpToken).balanceOf(address(this)) - _before;
    }

    // 3. deposit
    return _deposit(_pid, _recipient, _assetsIn);
  }

  /// @inheritdoc IConcentratorConvexVault
  function withdraw(
    uint256 _pid,
    uint256 _sharesIn,
    address _recipient,
    address _owner
  ) public override onlyExistPool(_pid) nonReentrant returns (uint256) {
    if (_sharesIn == uint256(-1)) {
      _sharesIn = userInfo[_pid][_owner].shares;
    }
    require(_sharesIn > 0, "withdraw zero share");

    if (msg.sender != _owner) {
      UserInfo storage _info = userInfo[_pid][_owner];
      uint256 _allowance = _info.allowances[msg.sender];
      require(_allowance >= _sharesIn, "withdraw exceeds allowance");
      if (_allowance != uint256(-1)) {
        // decrease allowance if it is not max
        _approve(_pid, _owner, msg.sender, _allowance - _sharesIn);
      }
    }

    // 1. update rewards
    PoolInfo storage _pool = poolInfo[_pid];
    require(!_pool.pauseWithdraw, "pool paused");
    _updateRewards(_pid, _owner);

    // 2. withdraw lp token
    return _withdraw(_pid, _sharesIn, _owner, _recipient);
  }

  /// @inheritdoc IConcentratorConvexVault
  function claim(
    uint256 _pid,
    address _recipient,
    uint256 _minOut,
    address _claimAsToken
  ) public override onlyExistPool(_pid) nonReentrant returns (uint256) {
    PoolInfo storage _pool = poolInfo[_pid];
    require(!_pool.pauseWithdraw, "pool paused");
    _updateRewards(_pid, msg.sender);

    UserInfo storage _userInfo = userInfo[_pid][msg.sender];
    uint256 _rewards = _userInfo.rewards;
    _userInfo.rewards = 0;

    emit Claim(_pid, msg.sender, _recipient, _rewards);

    _rewards = _claim(_rewards, _minOut, _recipient, _claimAsToken);
    return _rewards;
  }

  /// @inheritdoc IConcentratorConvexVault
  function claimAll(
    uint256 _minOut,
    address _recipient,
    address _claimAsToken
  ) external override nonReentrant returns (uint256) {
    uint256 _rewards;
    for (uint256 _pid = 0; _pid < poolInfo.length; _pid++) {
      if (poolInfo[_pid].pauseWithdraw) continue; // skip paused pool

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

    _rewards = _claim(_rewards, _minOut, _recipient, _claimAsToken);
    return _rewards;
  }

  /// @inheritdoc IConcentratorConvexVault
  function harvest(
    uint256 _pid,
    address _recipient,
    uint256 _minOut
  ) external virtual override onlyExistPool(_pid) nonReentrant returns (uint256) {
    PoolInfo storage _pool = poolInfo[_pid];
    _updateRewards(_pid, address(0));

    // 1. claim rewards
    IConvexBasicRewards(_pool.crvRewards).getReward();

    // 2. swap all convex rewards to reward token
    address[] memory _tokens = _pool.convexRewardTokens;
    uint256[] memory _balances = new uint256[](_tokens.length);
    for (uint256 i = 0; i < _tokens.length; i++) {
      _balances[i] = IERC20Upgradeable(_tokens[i]).balanceOf(address(this));
    }

    uint256 _rewards = _zapAsRewardToken(_tokens, _balances);
    require(_rewards >= _minOut, "insufficient rewards");
    address _token = rewardToken();

    // 3. distribute rewards to platform and _recipient
    uint256 _platformFee = _pool.platformFeePercentage;
    uint256 _harvestBounty = _pool.harvestBountyPercentage;
    if (_platformFee > 0) {
      _platformFee = (_platformFee * _rewards) / FEE_DENOMINATOR;
      IERC20Upgradeable(_token).safeTransfer(platform, _platformFee);
    }
    if (_harvestBounty > 0) {
      _harvestBounty = (_harvestBounty * _rewards) / FEE_DENOMINATOR;
      IERC20Upgradeable(_token).safeTransfer(_recipient, _harvestBounty);
    }

    emit Harvest(_pid, msg.sender, _recipient, _rewards, _platformFee, _harvestBounty);

    // 4. update rewards info
    _notifyHarvestedReward(_pid, _rewards - _platformFee - _harvestBounty);

    return _rewards;
  }

  /********************************** Restricted Functions **********************************/

  /// @notice Update the withdraw fee percentage.
  /// @param _pid The pool id.
  /// @param _feePercentage The fee percentage to update.
  function updateWithdrawFeePercentage(uint256 _pid, uint256 _feePercentage) external onlyExistPool(_pid) onlyOwner {
    require(_feePercentage <= MAX_WITHDRAW_FEE, "fee too large");

    poolInfo[_pid].withdrawFeePercentage = _feePercentage;

    emit UpdateWithdrawalFeePercentage(_pid, _feePercentage);
  }

  /// @notice Update the platform fee percentage.
  /// @param _pid The pool id.
  /// @param _feePercentage The fee percentage to update.
  function updatePlatformFeePercentage(uint256 _pid, uint256 _feePercentage) external onlyExistPool(_pid) onlyOwner {
    require(_feePercentage <= MAX_PLATFORM_FEE, "fee too large");

    poolInfo[_pid].platformFeePercentage = _feePercentage;

    emit UpdatePlatformFeePercentage(_pid, _feePercentage);
  }

  /// @notice Update the harvest bounty percentage.
  /// @param _pid The pool id.
  /// @param _percentage The fee percentage to update.
  function updateHarvestBountyPercentage(uint256 _pid, uint256 _percentage) external onlyExistPool(_pid) onlyOwner {
    require(_percentage <= MAX_HARVEST_BOUNTY, "fee too large");

    poolInfo[_pid].harvestBountyPercentage = _percentage;

    emit UpdateHarvestBountyPercentage(_pid, _percentage);
  }

  /// @notice Update the recipient
  /// @param _platform The address of new platform.
  function updatePlatform(address _platform) external onlyOwner {
    require(_platform != address(0), "zero platform address");
    platform = _platform;

    emit UpdatePlatform(_platform);
  }

  /// @notice Add new Convex pool.
  /// @param _convexPid The Convex pool id.
  /// @param _rewardTokens The list of addresses of reward tokens.
  /// @param _withdrawFeePercentage The withdraw fee percentage of the pool.
  /// @param _platformFeePercentage The platform fee percentage of the pool.
  /// @param _harvestBountyPercentage The harvest bounty percentage of the pool.
  function addPool(
    uint256 _convexPid,
    address[] memory _rewardTokens,
    uint256 _withdrawFeePercentage,
    uint256 _platformFeePercentage,
    uint256 _harvestBountyPercentage
  ) external onlyOwner {
    for (uint256 i = 0; i < poolInfo.length; i++) {
      require(poolInfo[i].convexPoolId != _convexPid, "duplicate pool");
    }

    require(_withdrawFeePercentage <= MAX_WITHDRAW_FEE, "fee too large");
    require(_platformFeePercentage <= MAX_PLATFORM_FEE, "fee too large");
    require(_harvestBountyPercentage <= MAX_HARVEST_BOUNTY, "fee too large");

    IConvexBooster.PoolInfo memory _info = IConvexBooster(BOOSTER).poolInfo(_convexPid);
    poolInfo.push(
      PoolInfo({
        totalUnderlying: 0,
        totalShare: 0,
        accRewardPerShare: 0,
        convexPoolId: _convexPid,
        lpToken: _info.lptoken,
        crvRewards: _info.crvRewards,
        withdrawFeePercentage: _withdrawFeePercentage,
        platformFeePercentage: _platformFeePercentage,
        harvestBountyPercentage: _harvestBountyPercentage,
        pauseDeposit: false,
        pauseWithdraw: false,
        convexRewardTokens: _rewardTokens
      })
    );

    rewardInfo.push(RewardInfo({ rate: 0, periodLength: 0, lastUpdate: 0, finishAt: 0 }));

    emit AddPool(poolInfo.length - 1, _convexPid, _rewardTokens);
  }

  /// @notice update reward period
  /// @param _pid The pool id.
  /// @param _period The length of the period
  function updateRewardPeriod(uint256 _pid, uint32 _period) external onlyExistPool(_pid) onlyOwner {
    require(_period <= WEEK, "reward period too long");

    rewardInfo[_pid].periodLength = _period;

    emit UpdateRewardPeriod(_pid, _period);
  }

  /// @notice update reward tokens
  /// @param _pid The pool id.
  /// @param _rewardTokens The address list of new reward tokens.
  function updatePoolRewardTokens(uint256 _pid, address[] memory _rewardTokens) external onlyExistPool(_pid) onlyOwner {
    delete poolInfo[_pid].convexRewardTokens;
    poolInfo[_pid].convexRewardTokens = _rewardTokens;

    emit UpdatePoolRewardTokens(_pid, _rewardTokens);
  }

  /// @notice Pause withdraw for specific pool.
  /// @param _pid The pool id.
  /// @param _status The status to update.
  function pausePoolWithdraw(uint256 _pid, bool _status) external onlyExistPool(_pid) onlyOwner {
    poolInfo[_pid].pauseWithdraw = _status;

    emit PausePoolWithdraw(_pid, _status);
  }

  /// @notice Pause deposit for specific pool.
  /// @param _pid The pool id.
  /// @param _status The status to update.
  function pausePoolDeposit(uint256 _pid, bool _status) external onlyExistPool(_pid) onlyOwner {
    poolInfo[_pid].pauseDeposit = _status;

    emit PausePoolDeposit(_pid, _status);
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
        _accRewardPerShare.sub(_userInfo.rewardPerSharePaid).mul(_userInfo.shares) / PRECISION
      );
  }

  /// @dev Internal function to reward checkpoint.
  /// @param _pid The pool id to update.
  /// @param _account The address of account to update.
  function _updateRewards(uint256 _pid, address _account) internal virtual {
    PoolInfo storage _pool = poolInfo[_pid];

    // 1. update global info
    RewardInfo memory _rewardInfo = rewardInfo[_pid];
    uint256 _accRewardPerShare = _pool.accRewardPerShare;
    if (_rewardInfo.periodLength > 0) {
      uint256 _currentTime = _rewardInfo.finishAt;
      // solhint-disable-next-line not-rely-on-time
      if (_currentTime > block.timestamp) {
        _currentTime = block.timestamp;
      }
      uint256 _duration = _currentTime >= _rewardInfo.lastUpdate ? _currentTime - _rewardInfo.lastUpdate : 0;
      if (_duration > 0) {
        _rewardInfo.lastUpdate = uint48(block.timestamp);
        if (_pool.totalShare > 0) {
          _accRewardPerShare = _accRewardPerShare.add(
            _duration.mul(_rewardInfo.rate).mul(PRECISION) / _pool.totalShare
          );
        }

        rewardInfo[_pid] = _rewardInfo;
        _pool.accRewardPerShare = _accRewardPerShare;
      }
    }

    if (_account != address(0)) {
      uint256 _rewards = _pendingReward(_pid, _account, _accRewardPerShare);
      UserInfo storage _userInfo = userInfo[_pid][_account];

      _userInfo.rewards = SafeCastUpgradeable.toUint128(_rewards);
      _userInfo.rewardPerSharePaid = _accRewardPerShare;
    }
  }

  /// @dev Internal function to deposit token to convex booster.
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

    {
      address _token = _pool.lpToken;
      IERC20Upgradeable(_token).safeApprove(BOOSTER, 0);
      IERC20Upgradeable(_token).safeApprove(BOOSTER, _assetsIn);
      IConvexBooster(BOOSTER).deposit(_pool.convexPoolId, _assetsIn, true);
    }

    uint256 _totalShare = _pool.totalShare;
    uint256 _totalUnderlying = _pool.totalUnderlying;
    uint256 _sharesOut;
    if (_totalShare == 0) {
      _sharesOut = _assetsIn;
    } else {
      _sharesOut = _assetsIn.mul(_totalShare) / _totalUnderlying;
    }
    _pool.totalShare = SafeCastUpgradeable.toUint128(_totalShare.add(_sharesOut));
    _pool.totalUnderlying = SafeCastUpgradeable.toUint128(_totalUnderlying.add(_assetsIn));

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
    require(_sharesIn <= _userInfo.shares, "shares not enough");

    uint256 _totalShare = _pool.totalShare;
    uint256 _totalUnderlying = _pool.totalUnderlying;
    uint256 _assetsOut;
    if (_sharesIn == _totalShare) {
      // If user is last to withdraw, don't take withdraw fee.
      // And there may still have some pending rewards, we just simple ignore it now.
      // If we want the reward later, we can upgrade the contract.
      _assetsOut = _totalUnderlying;
    } else {
      // take withdraw fee here
      _assetsOut = _sharesIn.mul(_totalUnderlying) / _totalShare;
      uint256 _fee = _assetsOut.mul(_pool.withdrawFeePercentage) / FEE_DENOMINATOR;
      _assetsOut = _assetsOut - _fee; // never overflow
    }

    _pool.totalShare = SafeCastUpgradeable.toUint128(_totalShare - _sharesIn);
    _pool.totalUnderlying = SafeCastUpgradeable.toUint128(_totalUnderlying - _assetsOut);
    _userInfo.shares = uint128(uint256(_userInfo.shares) - _sharesIn);

    IConvexBasicRewards(_pool.crvRewards).withdrawAndUnwrap(_assetsOut, false);
    IERC20Upgradeable(_pool.lpToken).safeTransfer(_recipient, _assetsOut);

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
    require(_owner != address(0), "approve from the zero address");
    require(_spender != address(0), "approve to the zero address");

    UserInfo storage _info = userInfo[_pid][_owner];
    _info.allowances[_spender] = _amount;
    emit Approval(_pid, _owner, _spender, _amount);
  }

  /// @dev Internal function to notify harvested rewards.
  /// @dev The caller should make sure `_updateRewards` is called before.
  /// @param _pid The pool id to notify.
  /// @param _amount The amount of harvested rewards.
  function _notifyHarvestedReward(uint256 _pid, uint256 _amount) internal virtual {
    RewardInfo memory _info = rewardInfo[_pid];

    if (_info.periodLength == 0) {
      PoolInfo storage _pool = poolInfo[_pid];
      _pool.accRewardPerShare = _pool.accRewardPerShare.add(_amount.mul(PRECISION) / _pool.totalShare);
    } else {
      require(_amount < uint128(-1), "harvested amount overflow");

      if (block.timestamp >= _info.finishAt) {
        _info.rate = uint128(_amount / _info.periodLength);
      } else {
        uint256 _remaining = _info.finishAt - block.timestamp;
        uint256 _leftover = _remaining * _info.rate;
        _info.rate = uint128((_amount + _leftover) / _info.periodLength);
      }

      _info.lastUpdate = uint48(block.timestamp);
      _info.finishAt = uint48(block.timestamp + _info.periodLength);

      rewardInfo[_pid] = _info;
    }
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

  /// @dev Internal function to zap tokens to reward token.
  /// @param _tokens The address list of tokens to zap.
  /// @param _amounts The list of corresponding token amounts.
  function _zapAsRewardToken(address[] memory _tokens, uint256[] memory _amounts) internal virtual returns (uint256) {}
}