// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

import "./interfaces/IAladdinConvexVault.sol";
import "./interfaces/IAladdinCRV.sol";
import "../interfaces/IConvexBooster.sol";
import "../interfaces/IConvexBasicRewards.sol";
import "../interfaces/IConvexCRVDepositor.sol";
import "../interfaces/ICurveFactoryPlainPool.sol";
import "../interfaces/IZap.sol";

// solhint-disable no-empty-blocks, reason-string
contract AladdinConvexVault is OwnableUpgradeable, ReentrancyGuardUpgradeable, IAladdinConvexVault {
  using SafeMathUpgradeable for uint256;
  using SafeERC20Upgradeable for IERC20Upgradeable;

  event UpdateMigrator(address _migrator);
  event Migrate(
    uint256 indexed _pid,
    address indexed _caller,
    uint256 _share,
    address _recipient,
    address _migrator,
    uint256 _newPid
  );

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
  }

  uint256 internal constant PRECISION = 1e18;
  uint256 internal constant FEE_DENOMINATOR = 1e9;
  uint256 private constant MAX_WITHDRAW_FEE = 1e8; // 10%
  uint256 private constant MAX_PLATFORM_FEE = 2e8; // 20%
  uint256 private constant MAX_HARVEST_BOUNTY = 1e8; // 10%

  // The address of cvxCRV token.
  address internal constant CVXCRV = 0x62B9c7356A2Dc64a1969e19C23e4f579F9810Aa7;
  // The address of CRV token.
  address internal constant CRV = 0xD533a949740bb3306d119CC777fa900bA034cd52;
  // The address of WETH token.
  address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
  // The address of Convex Booster Contract
  address private constant BOOSTER = 0xF403C135812408BFbE8713b5A23a04b3D48AAE31;
  // The address of Curve cvxCRV/CRV Pool
  address private constant CURVE_CVXCRV_CRV_POOL = 0x9D0464996170c6B9e75eED71c68B99dDEDf279e8;
  // The address of Convex CRV => cvxCRV Contract.
  address private constant CRV_DEPOSITOR = 0x8014595F2AB54cD7c604B00E9fb932176fDc86Ae;

  /// @notice The list of all supported pool.
  PoolInfo[] public poolInfo;

  /// @notice Mapping from pool id to account address to user share info.
  mapping(uint256 => mapping(address => UserInfo)) public userInfo;

  /// @notice The address of AladdinCRV token.
  address public aladdinCRV;

  /// @notice The address of ZAP contract, will be used to swap tokens.
  address public zap;

  /// @notice The address of recipient of platform fee
  address public platform;

  /// @notice The address of vault to migrate.
  address public migrator;

  modifier onlyExistPool(uint256 _pid) {
    require(_pid < poolInfo.length, "invalid pool");
    _;
  }

  function initialize(
    address _aladdinCRV,
    address _zap,
    address _platform
  ) external initializer {
    OwnableUpgradeable.__Ownable_init();
    ReentrancyGuardUpgradeable.__ReentrancyGuard_init();

    require(_aladdinCRV != address(0), "zero acrv address");
    require(_zap != address(0), "zero zap address");
    require(_platform != address(0), "zero platform address");

    aladdinCRV = _aladdinCRV;
    zap = _zap;
    platform = _platform;
  }

  /********************************** View Functions **********************************/

  /// @notice Returns the number of pools.
  function poolLength() public view returns (uint256 pools) {
    pools = poolInfo.length;
  }

  /// @notice See {IAladdinConvexVault-pendingReward}
  function pendingReward(uint256 _pid, address _account) public view override returns (uint256) {
    PoolInfo storage _pool = poolInfo[_pid];
    UserInfo storage _userInfo = userInfo[_pid][_account];
    return
      uint256(_userInfo.rewards).add(
        _pool.accRewardPerShare.sub(_userInfo.rewardPerSharePaid).mul(_userInfo.shares) / PRECISION
      );
  }

  /// @notice See {IAladdinConvexVault-pendingRewardAll}
  function pendingRewardAll(address _account) external view override returns (uint256) {
    uint256 _pending;
    for (uint256 i = 0; i < poolInfo.length; i++) {
      _pending += pendingReward(i, _account);
    }
    return _pending;
  }

  /// @notice See {IAladdinConvexVault-getUserShare}
  function getUserShare(uint256 _pid, address _account) external view override returns (uint256) {
    return userInfo[_pid][_account].shares;
  }

  /// @notice See {IAladdinConvexVault-getTotalUnderlying}
  function getTotalUnderlying(uint256 _pid) external view override returns (uint256) {
    return poolInfo[_pid].totalUnderlying;
  }

  /// @notice See {IAladdinConvexVault-getTotalShare}
  function getTotalShare(uint256 _pid) external view override returns (uint256) {
    return poolInfo[_pid].totalShare;
  }

  /********************************** Mutated Functions **********************************/

  /// @notice See {IAladdinConvexVault-deposit}
  /// @dev This function is deprecated.
  function deposit(uint256 _pid, uint256 _amount) external override returns (uint256 share) {
    return deposit(_pid, msg.sender, _amount);
  }

  /// @notice See {IAladdinConvexVault-deposit}
  function deposit(
    uint256 _pid,
    address _recipient,
    uint256 _amount
  ) public override onlyExistPool(_pid) returns (uint256 share) {
    require(_amount > 0, "zero amount deposit");

    // 1. update rewards
    PoolInfo storage _pool = poolInfo[_pid];
    require(!_pool.pauseDeposit, "pool paused");
    _updateRewards(_pid, _recipient);

    // 2. transfer user token
    address _lpToken = _pool.lpToken;
    {
      uint256 _before = IERC20Upgradeable(_lpToken).balanceOf(address(this));
      IERC20Upgradeable(_lpToken).safeTransferFrom(msg.sender, address(this), _amount);
      _amount = IERC20Upgradeable(_lpToken).balanceOf(address(this)) - _before;
    }

    // 3. deposit
    return _deposit(_pid, _recipient, _amount);
  }

  /// @notice See {IAladdinConvexVault-depositAll}
  function depositAll(uint256 _pid) external override returns (uint256 share) {
    return depositAll(_pid, msg.sender);
  }

  /// @notice See {IAladdinConvexVault-depositAll}
  function depositAll(uint256 _pid, address _recipient) public override returns (uint256 share) {
    PoolInfo storage _pool = poolInfo[_pid];
    uint256 _balance = IERC20Upgradeable(_pool.lpToken).balanceOf(msg.sender);
    return deposit(_pid, _recipient, _balance);
  }

  /// @notice See {IAladdinConvexVault-zapAndDeposit}
  function zapAndDeposit(
    uint256 _pid,
    address _token,
    uint256 _amount,
    uint256 _minAmount
  ) external payable override returns (uint256 share) {
    return zapAndDeposit(_pid, msg.sender, _token, _amount, _minAmount);
  }

  /// @notice See {IAladdinConvexVault-zapAndDeposit}
  function zapAndDeposit(
    uint256 _pid,
    address _recipient,
    address _token,
    uint256 _amount,
    uint256 _minAmount
  ) public payable override onlyExistPool(_pid) returns (uint256 share) {
    require(_amount > 0, "zero amount deposit");

    PoolInfo storage _pool = poolInfo[_pid];
    require(!_pool.pauseDeposit, "pool paused");

    address _lpToken = _pool.lpToken;
    if (_lpToken == _token) {
      return deposit(_pid, _recipient, _amount);
    }

    // 1. update rewards
    _updateRewards(_pid, _recipient);

    // transfer token to zap contract.
    address _zap = zap;
    uint256 _before;
    if (_token != address(0)) {
      require(msg.value == 0, "nonzero msg.value");
      _before = IERC20Upgradeable(_token).balanceOf(_zap);
      IERC20Upgradeable(_token).safeTransferFrom(msg.sender, _zap, _amount);
      _amount = IERC20Upgradeable(_token).balanceOf(_zap) - _before;
    } else {
      require(msg.value == _amount, "invalid amount");
    }

    // zap token to lp token using zap contract.
    _before = IERC20Upgradeable(_lpToken).balanceOf(address(this));
    IZap(_zap).zap{ value: msg.value }(_token, _amount, _lpToken, _minAmount);
    _amount = IERC20Upgradeable(_lpToken).balanceOf(address(this)) - _before;

    share = _deposit(_pid, _recipient, _amount);

    require(share >= _minAmount, "insufficient share");
    return share;
  }

  /// @notice See {IAladdinConvexVault-zapAllAndDeposit}
  function zapAllAndDeposit(
    uint256 _pid,
    address _token,
    uint256 _minAmount
  ) external payable override returns (uint256) {
    return zapAllAndDeposit(_pid, msg.sender, _token, _minAmount);
  }

  /// @notice See {IAladdinConvexVault-zapAllAndDeposit}
  function zapAllAndDeposit(
    uint256 _pid,
    address _recipient,
    address _token,
    uint256 _minAmount
  ) public payable override returns (uint256) {
    uint256 _balance = IERC20Upgradeable(_token).balanceOf(msg.sender);
    return zapAndDeposit(_pid, _recipient, _token, _balance, _minAmount);
  }

  /// @notice See {IAladdinConvexVault-withdrawAndClaim}
  function withdrawAndClaim(
    uint256 _pid,
    uint256 _shares,
    uint256 _minOut,
    ClaimOption _option
  ) public override onlyExistPool(_pid) nonReentrant returns (uint256 withdrawn, uint256 claimed) {
    require(_shares > 0, "zero share withdraw");

    // 1. update rewards
    PoolInfo storage _pool = poolInfo[_pid];
    require(!_pool.pauseWithdraw, "pool paused");
    _updateRewards(_pid, msg.sender);

    // 2. withdraw lp token
    uint256 _withdrawable = _withdraw(_pid, _shares, msg.sender);

    // 3. claim rewards
    if (_option == ClaimOption.None) {
      return (_withdrawable, 0);
    } else {
      UserInfo storage _userInfo = userInfo[_pid][msg.sender];
      uint256 _rewards = _userInfo.rewards;
      _userInfo.rewards = 0;

      emit Claim(msg.sender, _rewards, _option);
      _rewards = _claim(_rewards, _minOut, _option);

      return (_withdrawable, _rewards);
    }
  }

  /// @notice See {IAladdinConvexVault-withdrawAllAndClaim}
  function withdrawAllAndClaim(
    uint256 _pid,
    uint256 _minOut,
    ClaimOption _option
  ) external override returns (uint256 withdrawn, uint256 claimed) {
    UserInfo storage _userInfo = userInfo[_pid][msg.sender];
    return withdrawAndClaim(_pid, _userInfo.shares, _minOut, _option);
  }

  /// @notice Migrate all user share to another vault
  /// @param _pid The pool id to migrate.
  /// @param _recipient The address of recipient who will recieve the token.
  /// @param _newPid The target pool id in new vault.
  function migrate(
    uint256 _pid,
    address _recipient,
    uint256 _newPid
  ) external onlyExistPool(_pid) nonReentrant {
    address _migrator = migrator;
    require(_migrator != address(0), "migrator not set");

    // 1. update rewards
    PoolInfo storage _pool = poolInfo[_pid];
    _updateRewards(_pid, msg.sender);

    // 2. withdraw lp token
    UserInfo storage _userInfo = userInfo[_pid][msg.sender];
    uint256 _shares = _userInfo.shares;
    uint256 _totalShare = _pool.totalShare;
    uint256 _totalUnderlying = _pool.totalUnderlying;
    uint256 _withdrawable = _shares.mul(_totalUnderlying) / _totalShare; // no withdraw fee

    _pool.totalShare = uint128(_totalShare - _shares); // safe to cast
    _pool.totalUnderlying = uint128(_totalUnderlying - _withdrawable); // safe to cast
    _userInfo.shares = 0;

    IConvexBasicRewards(_pool.crvRewards).withdrawAndUnwrap(_withdrawable, false);

    emit Withdraw(_pid, msg.sender, _shares);

    // 3. migrate
    address _token = _pool.lpToken;
    IERC20Upgradeable(_token).approve(_migrator, 0);
    IERC20Upgradeable(_token).approve(_migrator, _withdrawable);
    IAladdinConvexVault(_migrator).deposit(_newPid, _recipient, _withdrawable);

    emit Migrate(_pid, msg.sender, _shares, _recipient, _migrator, _newPid);
  }

  /// @notice See {IAladdinConvexVault-withdrawAndZap}
  function withdrawAndZap(
    uint256 _pid,
    uint256 _shares,
    address _token,
    uint256 _minOut
  ) public override onlyExistPool(_pid) nonReentrant returns (uint256 withdrawn) {
    require(_shares > 0, "zero share withdraw");

    // 1. update rewards
    PoolInfo storage _pool = poolInfo[_pid];
    require(!_pool.pauseWithdraw, "pool paused");
    _updateRewards(_pid, msg.sender);

    // 2. withdraw and zap
    address _lpToken = _pool.lpToken;
    if (_token == _lpToken) {
      return _withdraw(_pid, _shares, msg.sender);
    } else {
      address _zap = zap;
      // withdraw to zap contract
      uint256 _before = IERC20Upgradeable(_lpToken).balanceOf(_zap);
      _withdraw(_pid, _shares, _zap);
      uint256 _amount = IERC20Upgradeable(_lpToken).balanceOf(_zap) - _before;

      // zap to desired token
      if (_token == address(0)) {
        _before = address(this).balance;
        IZap(_zap).zap(_lpToken, _amount, _token, _minOut);
        _amount = address(this).balance - _before;
        // solhint-disable-next-line avoid-low-level-calls
        (bool _success, ) = msg.sender.call{ value: _amount }("");
        require(_success, "transfer failed");
      } else {
        _before = IERC20Upgradeable(_token).balanceOf(address(this));
        IZap(_zap).zap(_lpToken, _amount, _token, _minOut);
        _amount = IERC20Upgradeable(_token).balanceOf(address(this)) - _before;
        IERC20Upgradeable(_token).safeTransfer(msg.sender, _amount);
      }
      return _amount;
    }
  }

  /// @notice See {IAladdinConvexVault-withdrawAllAndZap}
  function withdrawAllAndZap(
    uint256 _pid,
    address _token,
    uint256 _minOut
  ) external override returns (uint256 withdrawn) {
    UserInfo storage _userInfo = userInfo[_pid][msg.sender];
    return withdrawAndZap(_pid, _userInfo.shares, _token, _minOut);
  }

  /// @notice See {IAladdinConvexVault-claim}
  function claim(
    uint256 _pid,
    uint256 _minOut,
    ClaimOption _option
  ) public override onlyExistPool(_pid) nonReentrant returns (uint256 claimed) {
    PoolInfo storage _pool = poolInfo[_pid];
    require(!_pool.pauseWithdraw, "pool paused");
    _updateRewards(_pid, msg.sender);

    UserInfo storage _userInfo = userInfo[_pid][msg.sender];
    uint256 _rewards = _userInfo.rewards;
    _userInfo.rewards = 0;

    emit Claim(msg.sender, _rewards, _option);
    _rewards = _claim(_rewards, _minOut, _option);
    return _rewards;
  }

  /// @notice See {IAladdinConvexVault-claimAll}
  function claimAll(uint256 _minOut, ClaimOption _option) external override nonReentrant returns (uint256 claimed) {
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
        _userInfo.rewards = 0;
      }
    }

    emit Claim(msg.sender, _rewards, _option);
    _rewards = _claim(_rewards, _minOut, _option);
    return _rewards;
  }

  /// @notice See {IAladdinConvexVault-harvest}
  function harvest(
    uint256 _pid,
    address _recipient,
    uint256 _minimumOut
  ) external virtual override onlyExistPool(_pid) nonReentrant returns (uint256 harvested) {
    PoolInfo storage _pool = poolInfo[_pid];
    // 1. claim rewards
    IConvexBasicRewards(_pool.crvRewards).getReward();

    // 2. swap all rewards token to CRV
    address[] memory _rewardsToken = _pool.convexRewardTokens;
    uint256 _amount = address(this).balance;
    address _token;
    address _zap = zap;
    for (uint256 i = 0; i < _rewardsToken.length; i++) {
      _token = _rewardsToken[i];
      if (_token != CRV) {
        uint256 _balance = IERC20Upgradeable(_token).balanceOf(address(this));
        if (_balance > 0) {
          // saving gas
          IERC20Upgradeable(_token).safeTransfer(_zap, _balance);
          _amount = _amount.add(IZap(_zap).zap(_token, _balance, address(0), 0));
        }
      }
    }
    if (_amount > 0) {
      IZap(_zap).zap{ value: _amount }(address(0), _amount, CRV, 0);
    }
    _amount = IERC20Upgradeable(CRV).balanceOf(address(this));
    _amount = _swapCRVToCvxCRV(_amount, _minimumOut);

    _token = aladdinCRV; // gas saving
    _approve(CVXCRV, _token, _amount);
    uint256 _rewards = IAladdinCRV(_token).deposit(address(this), _amount);

    // 3. distribute rewards to platform and _recipient
    uint256 _platformFee = _pool.platformFeePercentage;
    uint256 _harvestBounty = _pool.harvestBountyPercentage;
    if (_platformFee > 0) {
      _platformFee = (_platformFee * _rewards) / FEE_DENOMINATOR;
      _rewards = _rewards - _platformFee;
      IERC20Upgradeable(_token).safeTransfer(platform, _platformFee);
    }
    if (_harvestBounty > 0) {
      _harvestBounty = (_harvestBounty * _rewards) / FEE_DENOMINATOR;
      _rewards = _rewards - _harvestBounty;
      IERC20Upgradeable(_token).safeTransfer(_recipient, _harvestBounty);
    }

    // 4. update rewards info
    _pool.accRewardPerShare = _pool.accRewardPerShare.add(_rewards.mul(PRECISION) / _pool.totalShare);

    emit Harvest(msg.sender, _rewards, _platformFee, _harvestBounty);

    return _amount;
  }

  /********************************** Restricted Functions **********************************/

  /// @dev Update the withdraw fee percentage.
  /// @param _pid - The pool id.
  /// @param _feePercentage - The fee percentage to update.
  function updateWithdrawFeePercentage(uint256 _pid, uint256 _feePercentage) external onlyExistPool(_pid) onlyOwner {
    require(_feePercentage <= MAX_WITHDRAW_FEE, "fee too large");

    poolInfo[_pid].withdrawFeePercentage = _feePercentage;

    emit UpdateWithdrawalFeePercentage(_pid, _feePercentage);
  }

  /// @dev Update the platform fee percentage.
  /// @param _pid - The pool id.
  /// @param _feePercentage - The fee percentage to update.
  function updatePlatformFeePercentage(uint256 _pid, uint256 _feePercentage) external onlyExistPool(_pid) onlyOwner {
    require(_feePercentage <= MAX_PLATFORM_FEE, "fee too large");

    poolInfo[_pid].platformFeePercentage = _feePercentage;

    emit UpdatePlatformFeePercentage(_pid, _feePercentage);
  }

  /// @dev Update the harvest bounty percentage.
  /// @param _pid - The pool id.
  /// @param _percentage - The fee percentage to update.
  function updateHarvestBountyPercentage(uint256 _pid, uint256 _percentage) external onlyExistPool(_pid) onlyOwner {
    require(_percentage <= MAX_HARVEST_BOUNTY, "fee too large");

    poolInfo[_pid].harvestBountyPercentage = _percentage;

    emit UpdateHarvestBountyPercentage(_pid, _percentage);
  }

  /// @dev Update the recipient
  function updatePlatform(address _platform) external onlyOwner {
    require(_platform != address(0), "zero platform address");
    platform = _platform;

    emit UpdatePlatform(_platform);
  }

  /// @dev Update the zap contract
  function updateZap(address _zap) external onlyOwner {
    require(_zap != address(0), "zero zap address");
    zap = _zap;

    emit UpdateZap(_zap);
  }

  /// @dev Update the migrator contract
  function updateMigrator(address _migrator) external onlyOwner {
    require(_migrator != address(0), "zero migrator address");
    migrator = _migrator;

    emit UpdateMigrator(_migrator);
  }

  /// @dev Add new Convex pool.
  /// @param _convexPid - The Convex pool id.
  /// @param _rewardTokens - The list of addresses of reward tokens.
  /// @param _withdrawFeePercentage - The withdraw fee percentage of the pool.
  /// @param _platformFeePercentage - The platform fee percentage of the pool.
  /// @param _harvestBountyPercentage - The harvest bounty percentage of the pool.
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

    emit AddPool(poolInfo.length - 1, _convexPid, _rewardTokens);
  }

  /// @dev update reward tokens
  /// @param _pid - The pool id.
  /// @param _rewardTokens - The address list of new reward tokens.
  function updatePoolRewardTokens(uint256 _pid, address[] memory _rewardTokens) external onlyExistPool(_pid) onlyOwner {
    delete poolInfo[_pid].convexRewardTokens;
    poolInfo[_pid].convexRewardTokens = _rewardTokens;

    emit UpdatePoolRewardTokens(_pid, _rewardTokens);
  }

  /// @dev Pause withdraw for specific pool.
  /// @param _pid - The pool id.
  /// @param _status - The status to update.
  function pausePoolWithdraw(uint256 _pid, bool _status) external onlyExistPool(_pid) onlyOwner {
    poolInfo[_pid].pauseWithdraw = _status;

    emit PausePoolWithdraw(_pid, _status);
  }

  /// @dev Pause deposit for specific pool.
  /// @param _pid - The pool id.
  /// @param _status - The status to update.
  function pausePoolDeposit(uint256 _pid, bool _status) external onlyExistPool(_pid) onlyOwner {
    poolInfo[_pid].pauseDeposit = _status;

    emit PausePoolDeposit(_pid, _status);
  }

  /********************************** Internal Functions **********************************/

  function _updateRewards(uint256 _pid, address _account) internal virtual {
    uint256 _rewards = pendingReward(_pid, _account);
    PoolInfo storage _pool = poolInfo[_pid];
    UserInfo storage _userInfo = userInfo[_pid][_account];

    _userInfo.rewards = _toU128(_rewards);
    _userInfo.rewardPerSharePaid = _pool.accRewardPerShare;
  }

  function _deposit(
    uint256 _pid,
    address _recipient,
    uint256 _amount
  ) internal nonReentrant returns (uint256) {
    PoolInfo storage _pool = poolInfo[_pid];

    _approve(_pool.lpToken, BOOSTER, _amount);
    IConvexBooster(BOOSTER).deposit(_pool.convexPoolId, _amount, true);

    uint256 _totalShare = _pool.totalShare;
    uint256 _totalUnderlying = _pool.totalUnderlying;
    uint256 _shares;
    if (_totalShare == 0) {
      _shares = _amount;
    } else {
      _shares = _amount.mul(_totalShare) / _totalUnderlying;
    }
    _pool.totalShare = _toU128(_totalShare.add(_shares));
    _pool.totalUnderlying = _toU128(_totalUnderlying.add(_amount));

    UserInfo storage _userInfo = userInfo[_pid][_recipient];
    _userInfo.shares = _toU128(_shares + _userInfo.shares);

    emit Deposit(_pid, _recipient, _amount);
    return _shares;
  }

  function _withdraw(
    uint256 _pid,
    uint256 _shares,
    address _recipient
  ) internal returns (uint256) {
    PoolInfo storage _pool = poolInfo[_pid];

    // 2. withdraw lp token
    UserInfo storage _userInfo = userInfo[_pid][msg.sender];
    require(_shares <= _userInfo.shares, "shares not enough");

    uint256 _totalShare = _pool.totalShare;
    uint256 _totalUnderlying = _pool.totalUnderlying;
    uint256 _withdrawable;
    if (_shares == _totalShare) {
      // If user is last to withdraw, don't take withdraw fee.
      // And there may still have some pending rewards, we just simple ignore it now.
      // If we want the reward later, we can upgrade the contract.
      _withdrawable = _totalUnderlying;
    } else {
      // take withdraw fee here
      _withdrawable = _shares.mul(_totalUnderlying) / _totalShare;
      uint256 _fee = _withdrawable.mul(_pool.withdrawFeePercentage) / FEE_DENOMINATOR;
      _withdrawable = _withdrawable - _fee; // never overflow
    }

    _pool.totalShare = _toU128(_totalShare - _shares);
    _pool.totalUnderlying = _toU128(_totalUnderlying - _withdrawable);
    _userInfo.shares = _toU128(uint256(_userInfo.shares) - _shares);

    IConvexBasicRewards(_pool.crvRewards).withdrawAndUnwrap(_withdrawable, false);
    IERC20Upgradeable(_pool.lpToken).safeTransfer(_recipient, _withdrawable);
    emit Withdraw(_pid, msg.sender, _shares);

    return _withdrawable;
  }

  function _claim(
    uint256 _amount,
    uint256 _minOut,
    ClaimOption _option
  ) internal returns (uint256) {
    if (_amount == 0) return _amount;

    IAladdinCRV.WithdrawOption _withdrawOption;
    if (_option == ClaimOption.Claim) {
      require(_amount >= _minOut, "insufficient output");
      IERC20Upgradeable(aladdinCRV).safeTransfer(msg.sender, _amount);
      return _amount;
    } else if (_option == ClaimOption.ClaimAsCvxCRV) {
      _withdrawOption = IAladdinCRV.WithdrawOption.Withdraw;
    } else if (_option == ClaimOption.ClaimAsCRV) {
      _withdrawOption = IAladdinCRV.WithdrawOption.WithdrawAsCRV;
    } else if (_option == ClaimOption.ClaimAsCVX) {
      _withdrawOption = IAladdinCRV.WithdrawOption.WithdrawAsCVX;
    } else if (_option == ClaimOption.ClaimAsETH) {
      _withdrawOption = IAladdinCRV.WithdrawOption.WithdrawAsETH;
    } else {
      revert("invalid claim option");
    }
    return IAladdinCRV(aladdinCRV).withdraw(msg.sender, _amount, _minOut, _withdrawOption);
  }

  function _toU128(uint256 _value) internal pure returns (uint128) {
    require(_value < 340282366920938463463374607431768211456, "overflow");
    return uint128(_value);
  }

  function _swapCRVToCvxCRV(uint256 _amountIn, uint256 _minOut) internal returns (uint256) {
    // CRV swap to CVXCRV or stake to CVXCRV
    // CRV swap to CVXCRV or stake to CVXCRV
    uint256 _amountOut = ICurveFactoryPlainPool(CURVE_CVXCRV_CRV_POOL).get_dy(0, 1, _amountIn);
    bool useCurve = _amountOut > _amountIn;
    require(_amountOut >= _minOut || _amountIn >= _minOut, "AladdinCRVZap: insufficient output");

    if (useCurve) {
      _approve(CRV, CURVE_CVXCRV_CRV_POOL, _amountIn);
      _amountOut = ICurveFactoryPlainPool(CURVE_CVXCRV_CRV_POOL).exchange(0, 1, _amountIn, 0, address(this));
    } else {
      _approve(CRV, CRV_DEPOSITOR, _amountIn);
      uint256 _lockIncentive = IConvexCRVDepositor(CRV_DEPOSITOR).lockIncentive();
      // if use `lock = false`, will possible take fee
      // if use `lock = true`, some incentive will be given
      _amountOut = IERC20Upgradeable(CVXCRV).balanceOf(address(this));
      if (_lockIncentive == 0) {
        // no lock incentive, use `lock = false`
        IConvexCRVDepositor(CRV_DEPOSITOR).deposit(_amountIn, false, address(0));
      } else {
        // no lock incentive, use `lock = true`
        IConvexCRVDepositor(CRV_DEPOSITOR).deposit(_amountIn, true, address(0));
      }
      _amountOut = IERC20Upgradeable(CVXCRV).balanceOf(address(this)) - _amountOut; // never overflow here
    }
    return _amountOut;
  }

  function _approve(
    address _token,
    address _spender,
    uint256 _amount
  ) internal {
    IERC20Upgradeable(_token).safeApprove(_spender, 0);
    IERC20Upgradeable(_token).safeApprove(_spender, _amount);
  }

  receive() external payable {}
}