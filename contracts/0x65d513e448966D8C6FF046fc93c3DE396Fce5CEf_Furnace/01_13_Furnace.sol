// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "./interfaces/ICLeverToken.sol";
import "./interfaces/IFurnace.sol";
import "../interfaces/IConvexCVXRewardPool.sol";
import "../interfaces/IZap.sol";

// solhint-disable reason-string, not-rely-on-time, max-states-count

contract Furnace is OwnableUpgradeable, IFurnace {
  using SafeMathUpgradeable for uint256;
  using SafeERC20Upgradeable for IERC20Upgradeable;

  event UpdateWhitelist(address indexed _whitelist, bool _status);
  event UpdateStakePercentage(uint256 _percentage);
  event UpdateStakeThreshold(uint256 _threshold);
  event UpdatePlatformFeePercentage(uint256 _feePercentage);
  event UpdateHarvestBountyPercentage(uint256 _percentage);
  event UpdatePlatform(address indexed _platform);
  event UpdateZap(address indexed _zap);
  event UpdateGovernor(address indexed _governor);
  event UpdatePeriodLength(uint256 _length);

  uint256 private constant E128 = 2**128;
  uint256 private constant FEE_PRECISION = 1e9;
  uint256 private constant MAX_PLATFORM_FEE = 2e8; // 20%
  uint256 private constant MAX_HARVEST_BOUNTY = 1e8; // 10%

  address private constant CVX = 0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B;
  // The address of cvxCRV token.
  address private constant CVXCRV = 0x62B9c7356A2Dc64a1969e19C23e4f579F9810Aa7;
  address private constant CVX_REWARD_POOL = 0xCF50b810E57Ac33B91dCF525C6ddd9881B139332;

  /// @notice If the unrealised is not paid off,
  /// the realised token in n sequential distribute is
  ///    user_unrealised * (reward_1 / total_unrealised_1)
  ///  + user_unrealised * (reward_1 / total_unrealised_1) * (reward_2 / total_unrealised_2)
  ///  + ...
  /// the unrealised token in n sequential distribute is
  ///    user_unrealised * (total_unrealised_1 - reward_1) / total_unrealised_1 * (total_unrealised_2 - reward_2) / total_unrealised_2 * ...
  ///
  /// So we can maintain a variable `accUnrealisedFraction` which is a product of `(total_unrealised - reward) / total_unrealised`.
  /// And keep track of this variable on each deposit/withdraw/claim, the unrealised clevCVX of the user should be
  ///                                accUnrealisedFractionPaid
  ///                   unrealised * -------------------------
  ///                                  accUnrealisedFraction
  /// Also, the debt will paid off in some case, we record a global variable `lastPaidOffDistributeIndex` and an user
  /// specific variable `lastDistributeIndex` to check if the debt is paid off during `(lastDistributeIndex, distributeIndex]`.
  ///
  /// And to save the gas usage, an `uint128` is used to store `accUnrealisedFraction` and `accUnrealisedFractionPaid`.
  /// More specifically, it is in range [0, 2^128), means the real number `fraction / 2^128`. If the value is 0, it
  /// means the value of the faction is 1.
  struct UserInfo {
    // The total amount of clevCVX unrealised.
    uint128 unrealised;
    // The total amount of clevCVX realised.
    uint128 realised;
    // The checkpoint for global `accUnrealisedFraction`, multipled by 1e9.
    uint192 accUnrealisedFractionPaid;
    // The distribute index record when use interacted the contract.
    uint64 lastDistributeIndex;
  }

  /// @dev The address of governor
  address public governor;
  /// @dev The address of clevCVX
  address public clevCVX;
  /// @dev The total amount of clevCVX unrealised.
  uint128 public totalUnrealised;
  /// @dev The total amount of clevCVX realised.
  uint128 public totalRealised;
  /// @dev The accumulated unrealised fraction, multipled by 2^128.
  uint128 public accUnrealisedFraction;
  /// @dev The distriubed index, will be increased each time the function `distribute` is called.
  uint64 public distributeIndex;
  /// @dev The distriubed index when all clevCVX is paied off.
  uint64 public lastPaidOffDistributeIndex;
  /// @dev Mapping from user address to user info.
  mapping(address => UserInfo) public userInfo;
  /// @dev Mapping from user address to whether it is whitelisted.
  mapping(address => bool) public isWhitelisted;
  /// @dev The percentage of free CVX should be staked in CVXRewardPool, multipled by 1e9.
  uint256 public stakePercentage;
  /// @dev The minimum amount of CVX in each stake.
  uint256 public stakeThreshold;

  /// @dev The address of zap contract.
  address public zap;
  /// @dev The percentage of rewards to take for platform on harvest, multipled by 1e9.
  uint256 public platformFeePercentage;
  /// @dev The percentage of rewards to take for caller on harvest, multipled by 1e9.
  uint256 public harvestBountyPercentage;
  /// @dev The address of recipient of platform fee
  address public platform;

  /// @dev Compiler will pack this into single `uint256`.
  struct LinearReward {
    // The number of debt token to pay each second.
    uint128 ratePerSecond;
    // The length of reward period in seconds.
    // If the value is zero, the reward will be distributed immediately.
    uint32 periodLength;
    // The timesamp in seconds when reward is updated.
    uint48 lastUpdate;
    // The finish timestamp in seconds of current reward period.
    uint48 finishAt;
  }

  /// @notice The reward distribute information.
  LinearReward public rewardInfo;

  modifier onlyWhitelisted() {
    require(isWhitelisted[msg.sender], "Furnace: only whitelisted");
    _;
  }

  modifier onlyGovernorOrOwner() {
    require(msg.sender == governor || msg.sender == owner(), "Furnace: only governor or owner");
    _;
  }

  function initialize(
    address _governor,
    address _clevCVX,
    address _zap,
    address _platform,
    uint256 _platformFeePercentage,
    uint256 _harvestBountyPercentage
  ) external initializer {
    OwnableUpgradeable.__Ownable_init();

    require(_governor != address(0), "Furnace: zero governor address");
    require(_clevCVX != address(0), "Furnace: zero clevCVX address");
    require(_zap != address(0), "Furnace: zero zap address");
    require(_platform != address(0), "Furnace: zero platform address");
    require(_platformFeePercentage <= MAX_PLATFORM_FEE, "Furnace: fee too large");
    require(_harvestBountyPercentage <= MAX_HARVEST_BOUNTY, "Furnace: fee too large");

    governor = _governor;
    clevCVX = _clevCVX;
    zap = _zap;
    platform = _platform;
    platformFeePercentage = _platformFeePercentage;
    harvestBountyPercentage = _harvestBountyPercentage;
  }

  /********************************** View Functions **********************************/

  /// @dev Return the amount of clevCVX unrealised and realised of user.
  /// @param _account The address of user.
  /// @return unrealised The amount of clevCVX unrealised.
  /// @return realised The amount of clevCVX realised and can be claimed.
  function getUserInfo(address _account) external view override returns (uint256 unrealised, uint256 realised) {
    UserInfo memory _info = userInfo[_account];
    if (_info.lastDistributeIndex < lastPaidOffDistributeIndex) {
      // In this case, all unrealised is paid off since last operate.
      return (0, _info.unrealised + _info.realised);
    } else {
      // extra plus 1, make sure we round up in division
      uint128 _newUnrealised = _toU128(
        _muldiv128(_info.unrealised, accUnrealisedFraction, uint128(_info.accUnrealisedFractionPaid))
      ) + 1;
      if (_newUnrealised >= _info.unrealised) {
        _newUnrealised = _info.unrealised;
      }
      uint128 _newRealised = _info.unrealised - _newUnrealised + _info.realised; // never overflow here
      return (_newUnrealised, _newRealised);
    }
  }

  /// @dev Return the total amount of free CVX in this contract, including staked in CVXRewardPool.
  /// @return The amount of CVX in this contract now.
  function totalCVXInPool() public view returns (uint256) {
    LinearReward memory _info = rewardInfo;
    uint256 _leftover = 0;
    if (_info.periodLength != 0) {
      if (block.timestamp < _info.finishAt) {
        _leftover = (_info.finishAt - block.timestamp) * _info.ratePerSecond;
      }
    }
    return
      IERC20Upgradeable(CVX)
        .balanceOf(address(this))
        .add(IConvexCVXRewardPool(CVX_REWARD_POOL).balanceOf(address(this)))
        .sub(_leftover);
  }

  /********************************** Mutated Functions **********************************/

  /// @dev Deposit clevCVX in this contract to change for CVX.
  /// @param _amount The amount of clevCVX to deposit.
  function deposit(uint256 _amount) external override {
    require(_amount > 0, "Furnace: deposit zero clevCVX");

    // transfer token into contract
    IERC20Upgradeable(clevCVX).safeTransferFrom(msg.sender, address(this), _amount);

    _deposit(msg.sender, _amount);
  }

  /// @dev Deposit clevCVX in this contract to change for CVX for other user.
  /// @param _account The address of user you deposit for.
  /// @param _amount The amount of clevCVX to deposit.
  function depositFor(address _account, uint256 _amount) external override {
    require(_amount > 0, "Furnace: deposit zero clevCVX");

    // transfer token into contract
    IERC20Upgradeable(clevCVX).safeTransferFrom(msg.sender, address(this), _amount);

    _deposit(_account, _amount);
  }

  /// @dev Withdraw unrealised clevCVX of the caller from this contract.
  /// @param _recipient The address of user who will recieve the clevCVX.
  /// @param _amount The amount of clevCVX to withdraw.
  function withdraw(address _recipient, uint256 _amount) external override {
    require(_amount > 0, "Furnace: withdraw zero CVX");

    _updateUserInfo(msg.sender);
    _withdraw(_recipient, _amount);
  }

  /// @dev Withdraw all unrealised clevCVX of the caller from this contract.
  /// @param _recipient The address of user who will recieve the clevCVX.
  function withdrawAll(address _recipient) external override {
    _updateUserInfo(msg.sender);

    _withdraw(_recipient, userInfo[msg.sender].unrealised);
  }

  /// @dev Claim all realised CVX of the caller from this contract.
  /// @param _recipient The address of user who will recieve the CVX.
  function claim(address _recipient) external override {
    _updateUserInfo(msg.sender);

    _claim(_recipient);
  }

  /// @dev Exit the contract, withdraw all unrealised clevCVX and realised CVX of the caller.
  /// @param _recipient The address of user who will recieve the clevCVX and CVX.
  function exit(address _recipient) external override {
    _updateUserInfo(msg.sender);

    _withdraw(_recipient, userInfo[msg.sender].unrealised);
    _claim(_recipient);
  }

  /// @dev Distribute CVX from `origin` to pay clevCVX debt.
  /// @param _origin The address of the user who will provide CVX.
  /// @param _amount The amount of CVX will be provided.
  function distribute(address _origin, uint256 _amount) external override onlyWhitelisted {
    require(_amount > 0, "Furnace: distribute zero CVX");

    IERC20Upgradeable(CVX).safeTransferFrom(_origin, address(this), _amount);

    _distribute(_origin, _amount);
  }

  /// @dev Harvest the pending reward and convert to cvxCRV.
  /// @param _recipient - The address of account to receive harvest bounty.
  /// @param _minimumOut - The minimum amount of cvxCRV should get.
  /// @return the amount of CVX harvested.
  function harvest(address _recipient, uint256 _minimumOut) external returns (uint256) {
    // 1. harvest from CVXRewardPool
    IConvexCVXRewardPool(CVX_REWARD_POOL).getReward(false);

    // 2. swap all reward to CVX (cvxCRV only currently)
    uint256 _amount = IERC20Upgradeable(CVXCRV).balanceOf(address(this));
    if (_amount > 0) {
      IERC20Upgradeable(CVXCRV).safeTransfer(zap, _amount);
      _amount = IZap(zap).zap(CVXCRV, _amount, CVX, _minimumOut);
    }

    emit Harvest(msg.sender, _amount);

    if (_amount > 0) {
      uint256 _distributeAmount = _amount;
      // 3. take platform fee and harvest bounty
      uint256 _platformFee = platformFeePercentage;
      if (_platformFee > 0) {
        _platformFee = (_platformFee * _distributeAmount) / FEE_PRECISION;
        IERC20Upgradeable(CVX).safeTransfer(platform, _platformFee);
        _distributeAmount = _distributeAmount - _platformFee; // never overflow here
      }
      uint256 _harvestBounty = harvestBountyPercentage;
      if (_harvestBounty > 0) {
        _harvestBounty = (_harvestBounty * _distributeAmount) / FEE_PRECISION;
        _distributeAmount = _distributeAmount - _harvestBounty; // never overflow here
        IERC20Upgradeable(CVX).safeTransfer(_recipient, _harvestBounty);
      }
      // 4. distribute harvest CVX to pay clevCVX
      // @note: we may distribute all rest CVX to AladdinConvexLocker
      _distribute(address(this), _distributeAmount);
    }
    return _amount;
  }

  /// @notice External helper function to update global debt.
  function updatePendingDistribution() external {
    _updatePendingDistribution();
  }

  /********************************** Restricted Functions **********************************/

  /// @dev Update the status of a list of whitelisted accounts.
  /// @param _whitelists The address list of whitelisted accounts.
  /// @param _status The status to update.
  function updateWhitelists(address[] memory _whitelists, bool _status) external onlyOwner {
    for (uint256 i = 0; i < _whitelists.length; i++) {
      // solhint-disable-next-line reason-string
      require(_whitelists[i] != address(0), "Furnace: zero whitelist address");
      isWhitelisted[_whitelists[i]] = _status;

      emit UpdateWhitelist(_whitelists[i], _status);
    }
  }

  /// @dev Update the address of governor.
  /// @param _governor The address to be updated
  function updateGovernor(address _governor) external onlyGovernorOrOwner {
    require(_governor != address(0), "Furnace: zero governor address");
    governor = _governor;

    emit UpdateGovernor(_governor);
  }

  /// @dev Update stake percentage for CVX in this contract.
  /// @param _percentage The stake percentage to be updated, multipled by 1e9.
  function updateStakePercentage(uint256 _percentage) external onlyGovernorOrOwner {
    require(_percentage <= FEE_PRECISION, "Furnace: percentage too large");
    stakePercentage = _percentage;

    emit UpdateStakePercentage(_percentage);
  }

  /// @dev Update stake threshold for CVX.
  /// @param _threshold The stake threshold to be updated.
  function updateStakeThreshold(uint256 _threshold) external onlyGovernorOrOwner {
    stakeThreshold = _threshold;

    emit UpdateStakeThreshold(_threshold);
  }

  /// @dev Update the platform fee percentage.
  /// @param _feePercentage The fee percentage to be updated, multipled by 1e9.
  function updatePlatformFeePercentage(uint256 _feePercentage) external onlyOwner {
    require(_feePercentage <= MAX_PLATFORM_FEE, "Furnace: fee too large");
    platformFeePercentage = _feePercentage;

    emit UpdatePlatformFeePercentage(_feePercentage);
  }

  /// @dev Update the harvest bounty percentage.
  /// @param _percentage - The fee percentage to be updated, multipled by 1e9.
  function updateHarvestBountyPercentage(uint256 _percentage) external onlyOwner {
    require(_percentage <= MAX_HARVEST_BOUNTY, "Furnace: fee too large");
    harvestBountyPercentage = _percentage;

    emit UpdateHarvestBountyPercentage(_percentage);
  }

  /// @dev Update the platform fee recipient
  /// @dev _platform The platform address to be updated.
  function updatePlatform(address _platform) external onlyOwner {
    require(_platform != address(0), "Furnace: zero platform address");
    platform = _platform;

    emit UpdatePlatform(_platform);
  }

  /// @dev Update the zap contract
  /// @param _zap The zap contract to be updated.
  function updateZap(address _zap) external onlyGovernorOrOwner {
    require(_zap != address(0), "Furnace: zero zap address");
    zap = _zap;

    emit UpdateZap(_zap);
  }

  /// @notice Update the reward period length.
  /// @dev The modification will be effictive after next reward distribution.
  /// @param _length The period length to be updated.
  function updatePeriodLength(uint32 _length) external onlyGovernorOrOwner {
    rewardInfo.periodLength = _length;

    emit UpdatePeriodLength(_length);
  }

  /********************************** Internal Functions **********************************/

  /// @dev Internal function to reduce global debt based on pending rewards.
  /// This function should be called before any mutable state change.
  function _updatePendingDistribution() internal {
    LinearReward memory _info = rewardInfo;
    if (_info.periodLength > 0) {
      uint256 _currentTime = _info.finishAt;
      if (_currentTime > block.timestamp) {
        _currentTime = block.timestamp;
      }
      uint256 _duration = _currentTime >= _info.lastUpdate ? _currentTime - _info.lastUpdate : 0;
      if (_duration > 0) {
        _info.lastUpdate = uint48(block.timestamp);
        rewardInfo = _info;

        _reduceGlobalDebt(_duration.mul(_info.ratePerSecond));
      }
    }
  }

  /// @dev Internal function called when user interacts with the contract.
  /// @param _account The address of user to update.
  function _updateUserInfo(address _account) internal {
    _updatePendingDistribution();

    UserInfo memory _info = userInfo[_account];
    uint128 _accUnrealisedFraction = accUnrealisedFraction;
    uint64 _distributeIndex = distributeIndex;
    if (_info.lastDistributeIndex < lastPaidOffDistributeIndex) {
      // In this case, all unrealised is paid off since last operate.
      userInfo[_account] = UserInfo({
        unrealised: 0,
        realised: _info.unrealised + _info.realised, // never overflow here
        accUnrealisedFractionPaid: 0,
        lastDistributeIndex: _distributeIndex
      });
    } else {
      // extra plus 1, make sure we round up in division
      uint128 _newUnrealised = _toU128(
        _muldiv128(_info.unrealised, _accUnrealisedFraction, uint128(_info.accUnrealisedFractionPaid))
      ) + 1;
      if (_newUnrealised >= _info.unrealised) {
        _newUnrealised = _info.unrealised;
      }
      uint128 _newRealised = _info.unrealised - _newUnrealised + _info.realised; // never overflow here
      userInfo[_account] = UserInfo({
        unrealised: _newUnrealised,
        realised: _newRealised,
        accUnrealisedFractionPaid: _accUnrealisedFraction,
        lastDistributeIndex: _distributeIndex
      });
    }
  }

  /// @dev Internal function called by `deposit` and `depositFor`.
  ///      assume that clevCVX is already transfered into this contract.
  /// @param _account The address of the user.
  /// @param _amount The amount of clevCVX to deposit.
  function _deposit(address _account, uint256 _amount) internal {
    // 1. update user info
    _updateUserInfo(_account);

    // 2. compute realised and unrelised
    uint256 _totalUnrealised = totalUnrealised;
    uint256 _totalRealised = totalRealised;
    uint256 _freeCVX = totalCVXInPool().sub(_totalRealised);

    uint256 _newUnrealised;
    uint256 _newRealised;
    if (_freeCVX >= _amount) {
      // pay all the debt with CVX in contract directly.
      _newUnrealised = 0;
      _newRealised = _amount;
    } else {
      // pay part of the debt with CVX in contract directly
      // and part of the debt with future CVX distributed to the contract.
      _newUnrealised = _amount - _freeCVX;
      _newRealised = _freeCVX;
    }

    // 3. update user and global state
    userInfo[_account].realised = _toU128(_newRealised.add(userInfo[_account].realised));
    userInfo[_account].unrealised = _toU128(_newUnrealised.add(userInfo[_account].unrealised));

    totalRealised = _toU128(_totalRealised.add(_newRealised));
    totalUnrealised = _toU128(_totalUnrealised.add(_newUnrealised));

    emit Deposit(_account, _amount);
  }

  /// @dev Internal function called by `withdraw` and `withdrawAll`.
  /// @param _recipient The address of user who will recieve the clevCVX.
  /// @param _amount The amount of clevCVX to withdraw.
  function _withdraw(address _recipient, uint256 _amount) internal {
    require(_amount <= userInfo[msg.sender].unrealised, "Furnace: clevCVX not enough");

    userInfo[msg.sender].unrealised = uint128(uint256(userInfo[msg.sender].unrealised) - _amount); // never overflow here
    totalUnrealised = uint128(uint256(totalUnrealised) - _amount); // never overflow here

    IERC20Upgradeable(clevCVX).safeTransfer(_recipient, _amount);

    emit Withdraw(msg.sender, _recipient, _amount);
  }

  /// @dev Internal function called by `claim`.
  /// @param _recipient The address of user who will recieve the CVX.
  function _claim(address _recipient) internal {
    uint256 _amount = userInfo[msg.sender].realised;
    // should not overflow, but just in case, we use safe math.
    totalRealised = uint128(uint256(totalRealised).sub(_amount));
    userInfo[msg.sender].realised = 0;

    uint256 _balanceInContract = IERC20Upgradeable(CVX).balanceOf(address(this));
    if (_balanceInContract < _amount) {
      // balance is not enough, with from reward pool
      IConvexCVXRewardPool(CVX_REWARD_POOL).withdraw(_amount - _balanceInContract, false);
    }
    IERC20Upgradeable(CVX).safeTransfer(_recipient, _amount);
    // burn realised clevCVX
    ICLeverToken(clevCVX).burn(_amount);

    emit Claim(msg.sender, _recipient, _amount);
  }

  /// @dev Internal function called by `distribute` and `harvest`.
  /// @param _origin The address of the user who will provide CVX.
  /// @param _amount The amount of CVX will be provided.
  function _distribute(address _origin, uint256 _amount) internal {
    // reduct pending debt
    _updatePendingDistribution();

    // distribute clevCVX rewards
    LinearReward memory _info = rewardInfo;
    if (_info.periodLength == 0) {
      _reduceGlobalDebt(_amount);
    } else {
      if (block.timestamp >= _info.finishAt) {
        _info.ratePerSecond = _toU128(_amount / _info.periodLength);
      } else {
        uint256 _remaining = _info.finishAt - block.timestamp;
        uint256 _leftover = _remaining * _info.ratePerSecond;
        _info.ratePerSecond = _toU128((_amount + _leftover) / _info.periodLength);
      }

      _info.lastUpdate = uint48(block.timestamp);
      _info.finishAt = uint48(block.timestamp + _info.periodLength);

      rewardInfo = _info;
    }

    // 2. stake extra CVX to cvxRewardPool
    uint256 _toStake = totalCVXInPool().mul(stakePercentage).div(FEE_PRECISION);
    uint256 _balanceStaked = IConvexCVXRewardPool(CVX_REWARD_POOL).balanceOf(address(this));
    if (_balanceStaked < _toStake) {
      _toStake = _toStake - _balanceStaked;
      if (_toStake >= stakeThreshold) {
        IERC20Upgradeable(CVX).safeApprove(CVX_REWARD_POOL, 0);
        IERC20Upgradeable(CVX).safeApprove(CVX_REWARD_POOL, _toStake);
        IConvexCVXRewardPool(CVX_REWARD_POOL).stake(_toStake);
      }
    }

    emit Distribute(_origin, _amount);
  }

  /// @dev Internal function to reduce global debt based on CVX rewards.
  /// @param _amount The new paid clevCVX debt.
  function _reduceGlobalDebt(uint256 _amount) internal {
    distributeIndex += 1;

    uint256 _totalUnrealised = totalUnrealised;
    uint256 _totalRealised = totalRealised;
    uint128 _accUnrealisedFraction = accUnrealisedFraction;
    // 1. distribute clevCVX rewards
    if (_amount >= _totalUnrealised) {
      // In this case, all unrealised clevCVX are paid off.
      totalUnrealised = 0;
      totalRealised = _toU128(_totalUnrealised + _totalRealised);

      accUnrealisedFraction = 0;
      lastPaidOffDistributeIndex = distributeIndex;
    } else {
      totalUnrealised = uint128(_totalUnrealised - _amount);
      totalRealised = _toU128(_totalRealised + _amount);

      uint128 _fraction = _toU128(((_totalUnrealised - _amount) * E128) / _totalUnrealised); // mul never overflow
      accUnrealisedFraction = _mul128(_accUnrealisedFraction, _fraction);
    }
  }

  /// @dev Convert uint256 value to uint128 value.
  function _toU128(uint256 _value) internal pure returns (uint128) {
    require(_value < 340282366920938463463374607431768211456, "Furnace: overflow");
    return uint128(_value);
  }

  /// @dev Compute the value of (_a / 2^128) * (_b / 2^128) with precision 2^128.
  function _mul128(uint128 _a, uint128 _b) internal pure returns (uint128) {
    if (_a == 0) return _b;
    if (_b == 0) return _a;
    return uint128((uint256(_a) * uint256(_b)) / E128);
  }

  /// @dev Compute the value of _a * (_b / 2^128) / (_c / 2^128).
  function _muldiv128(
    uint256 _a,
    uint128 _b,
    uint128 _c
  ) internal pure returns (uint256) {
    if (_b == 0) {
      if (_c == 0) return _a;
      else return _a / _c;
    } else {
      if (_c == 0) return _a.mul(_b) / E128;
      else return _a.mul(_b) / _c;
    }
  }
}