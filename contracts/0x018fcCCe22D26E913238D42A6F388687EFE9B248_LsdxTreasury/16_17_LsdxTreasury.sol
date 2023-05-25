// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/structs/DoubleEndedQueue.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "./veLSD.sol";

contract LsdxTreasury is Ownable, ReentrancyGuard {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;
  using Counters for Counters.Counter;
  using DoubleEndedQueue for DoubleEndedQueue.Bytes32Deque;
  using EnumerableSet for EnumerableSet.AddressSet;

  /* ========== STATE VARIABLES ========== */

  IERC20 public lsdToken;
  veLSD public velsdToken;
  EnumerableSet.AddressSet private _rewardTokensSet;
  EnumerableSet.AddressSet private _rewardersSet;

  mapping(address => uint256) public periodFinish;
  mapping(address => uint256) public rewardRates;
  mapping(address => uint256) public rewardsPerTokenStored;
  mapping(address => uint256) public lastUpdateTime;

  mapping(address => mapping(address => uint256)) public userRewardsPerTokenPaid;
  mapping(address => mapping(address => uint256)) public rewards;

  uint256 private _totalSupply;
  mapping(address => uint256) private _balances;
  uint256 private _adminFee;
  Counters.Counter private _nextLockId;
  mapping(address => DoubleEndedQueue.Bytes32Deque) private _userVelsdLocked;
  mapping(uint256 => VelsdLocked) private _allVelsdLocked;

  struct VelsdLocked {
    uint256 lockId;
    uint256 amount;
    uint256 depositTime;
  }

  /* ========== CONSTRUCTOR ========== */

  constructor(
    address _lsdToken,
    address[] memory _rewardTokens,
    address _velsdToken
  ) Ownable() {
    require(_lsdToken != address(0), "Zero address detected");
    require(_rewardTokens.length > 0, "Empty reward token list");
    require(_velsdToken != address(0), "Zero address detected");

    lsdToken = IERC20(_lsdToken);
    for (uint256 i = 0; i < _rewardTokens.length; i++) {
      addRewardToken(_rewardTokens[i]);
    }
    addRewarder(_msgSender());
    velsdToken = veLSD(_velsdToken);
  }

  /* ========== VIEWS ========== */

  function totalSupply() external view returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address account) external view returns (uint256) {
    return _balances[account];
  }

  function lastTimeRewardsApplicable(address rewardToken) public view onlyValidRewardToken(rewardToken) returns (uint256) {
    return Math.min(block.timestamp, periodFinish[rewardToken]);
  }

  function rewardsPerToken(address rewardToken) public view onlyValidRewardToken(rewardToken) returns (uint256) {
    if (_totalSupply == 0) {
      return rewardsPerTokenStored[rewardToken];
    }
    return
      rewardsPerTokenStored[rewardToken].add(
        lastTimeRewardsApplicable(rewardToken)
          .sub(lastUpdateTime[rewardToken])
          .mul(rewardRates[rewardToken])
          .mul(1e18)
        .div(_totalSupply)
      );
  }

  function earned(address account, address rewardToken) public view onlyValidRewardToken(rewardToken) returns (uint256) {
    return
      _balances[account]
        .mul(rewardsPerToken(rewardToken).sub(userRewardsPerTokenPaid[account][rewardToken]))
        .div(1e18)
        .add(rewards[account][rewardToken]);
  }

  function isSupportedRewardToken(address rewardToken) public view returns (bool) {
    return _rewardTokensSet.contains(rewardToken);
  }

  /// @dev No guarantees are made on the ordering
  function rewardTokens() public view returns (address[] memory) {
    return _rewardTokensSet.values();
  }

  /// @dev No guarantees are made on the ordering
  function rewarders() public view returns (address[] memory) {
    return _rewardersSet.values();
  }

  function velsdLockedCount(address user) public view returns (uint256) {
    return _userVelsdLocked[user].length();
  }

  function velsdLockedInfoByIndex(address user, uint256 index) public view returns (VelsdLocked memory) {
    require(index < velsdLockedCount(user), "Index out of bounds");

    DoubleEndedQueue.Bytes32Deque storage userLocked = _userVelsdLocked[user];
    uint256 lockId = uint256(userLocked.at(index));
    return _allVelsdLocked[lockId];
  }

  /* ========== MUTATIVE FUNCTIONS ========== */

  function depositAndLockToken(uint256 amount) external nonReentrant updateAllRewards(_msgSender()) {
    require(amount > 0, "Cannot deposit 0");

    _totalSupply = _totalSupply.add(amount);
    _balances[_msgSender()] = _balances[_msgSender()].add(amount);

    lsdToken.safeTransferFrom(_msgSender(), address(this), amount);
    velsdToken.mint(_msgSender(), amount);

    _nextLockId.increment();
    uint256 lockId = _nextLockId.current();
    VelsdLocked memory lock = VelsdLocked({
      lockId: lockId,
      amount: amount,
      depositTime: block.timestamp
    });
    _allVelsdLocked[lockId] = lock;
    DoubleEndedQueue.Bytes32Deque storage userLocked = _userVelsdLocked[_msgSender()];
    userLocked.pushBack(bytes32(lockId));

    emit Deposited(_msgSender(), amount);
  }

  function withdrawFirstSumOfLockedToken() public nonReentrant updateAllRewards(_msgSender()) {
    DoubleEndedQueue.Bytes32Deque storage userLocked = _userVelsdLocked[_msgSender()];
    require(!userLocked.empty(), "No deposit to withdraw");

    uint256 lockId = uint256(userLocked.front());
    VelsdLocked memory lock = _allVelsdLocked[lockId];
    uint256 amount = lock.amount;
    userLocked.popFront();
    delete _allVelsdLocked[lockId];

    if (amount > 0) {
      _totalSupply = _totalSupply.sub(amount);
      _balances[_msgSender()] = _balances[_msgSender()].sub(amount);

      uint256 fee = calcAdminFee(lock);
      uint256 netAmount = amount.sub(fee);     
       
      lsdToken.safeTransfer(_msgSender(), netAmount);
      velsdToken.burnFrom(_msgSender(), amount);
      emit Withdrawn(_msgSender(), amount, fee);

      if (fee > 0) {
        _adminFee = _adminFee.add(fee);
        emit AdminFeeAccrued(_msgSender(), amount, fee);
      }
    }
  }

  function calcAdminFee(VelsdLocked memory lock) public view returns (uint256) {
    require(lock.depositTime < block.timestamp, "Invalid deposit time");
    require(lock.amount > 0, "Invalid deposit amount");

    uint256 period = block.timestamp.sub(lock.depositTime);
    if (period < 7 days) {
      return lock.amount.mul(90).div(100);
    }
    else if (period < 30 days) {
      return lock.amount.mul(50).div(100);
    }
    else if (period < 90 days) {
      return lock.amount.mul(35).div(100);
    }
    else if (period < 180 days) {
      return lock.amount.mul(20).div(100);
    }
    else if (period < 365 days) {
      return lock.amount.mul(10).div(100);
    }
    else {
      return 0;
    }
  }

  function getRewards() public nonReentrant updateAllRewards(_msgSender()) {
    for (uint256 i = 0; i < _rewardTokensSet.length(); i++) {
      address currentToken = _rewardTokensSet.at(i);
      uint256 reward = rewards[_msgSender()][currentToken];
      if (reward > 0) {
        rewards[_msgSender()][currentToken] = 0;
        IERC20(currentToken).safeTransfer(_msgSender(), reward);
        emit RewardsPaid(_msgSender(), currentToken, reward);
      }
    }
  }

  function exitFirstSumOfLockedToken() external {
    withdrawFirstSumOfLockedToken();
    getRewards();
  }

  /* ========== RESTRICTED FUNCTIONS ========== */

  function addRewarder(address rewarder) public nonReentrant onlyOwner {
    require(rewarder != address(0), "Zero address detected");
    require(!_rewardersSet.contains(rewarder), "Already added");

    _rewardersSet.add(rewarder);
    emit RewarderAdded(rewarder);
  }

  function removeRewarder(address rewarder) public nonReentrant onlyOwner {
    require(_rewardersSet.contains(rewarder), "Not a rewarder");
    require(_rewardersSet.remove(rewarder), "Failed to remove rewarder");
    emit RewarderRemoved(rewarder);
  }

  function addRewardToken(address rewardToken) public nonReentrant onlyOwner {
    require(rewardToken != address(0), "Zero address detected");
    require(!_rewardTokensSet.contains(rewardToken), "Already added");
    _rewardTokensSet.add(rewardToken);
    emit RewardTokenAdded(rewardToken);
  }

  function addRewards(address rewardToken, uint256 rewardAmount, uint256 durationInDays) external nonReentrant onlyValidRewardToken(rewardToken) onlyRewarder {
    require(rewardAmount > 0, "Reward amount should be greater than 0");
    require(durationInDays > 0, 'Reward duration too short');

    uint256 rewardDuration = durationInDays.mul(1 days);
    IERC20(rewardToken).safeTransferFrom(_msgSender(), address(this), rewardAmount);
    _notifyRewardsAmount(rewardToken, rewardAmount, rewardDuration);
  }

  function _notifyRewardsAmount(address rewardToken, uint256 reward, uint256 rewardDuration) internal virtual onlyRewarder updateRewards(address(0), rewardToken) {
    if (block.timestamp >= periodFinish[rewardToken]) {
      rewardRates[rewardToken] = reward.div(rewardDuration);
    }
    else {
      uint256 remaining = periodFinish[rewardToken].sub(block.timestamp);
      uint256 leftover = remaining.mul(rewardRates[rewardToken]);
      rewardRates[rewardToken] = reward.add(leftover).div(rewardDuration);
    }

    uint balance = IERC20(rewardToken).balanceOf(address(this));
    require(rewardRates[rewardToken] <= balance.div(rewardDuration), "Provided reward too high");

    lastUpdateTime[rewardToken] = block.timestamp;
    periodFinish[rewardToken] = block.timestamp.add(rewardDuration);
    emit RewardsAdded(rewardToken, _msgSender(), reward, rewardDuration);
  }

  function adminFee() external view returns (uint256) {
    return _adminFee;
  }

  function withdrawAdminFee(address to) external nonReentrant onlyRewarder {
    require(_adminFee > 0, 'No admin fee to withdraw');

    lsdToken.safeTransfer(to, _adminFee);
    emit AdminFeeWithdrawn(_msgSender(), to, _adminFee);

    _adminFee = 0;
  }

  /* ========== MODIFIERS ========== */

  modifier onlyRewarder() {
    require(_rewardersSet.contains(_msgSender()), "Not a rewarder");
    _;
  }

  modifier onlyValidRewardToken(address rewardToken) {
    require(isSupportedRewardToken(rewardToken), "Reward token not supported");
    _;
  }

  modifier updateRewards(address account, address rewardToken) {
    _updateRewards(account, rewardToken);
    _;
  }

  modifier updateAllRewards(address account) {
    for (uint256 i = 0; i < _rewardTokensSet.length(); i++) {
      address rewardToken = _rewardTokensSet.at(i);
      _updateRewards(account, rewardToken);
    }
    _;
  }

  function _updateRewards(address account, address rewardToken) internal {
    require(isSupportedRewardToken(rewardToken), "Reward token not supported");
    rewardsPerTokenStored[rewardToken] = rewardsPerToken(rewardToken);
    lastUpdateTime[rewardToken] = lastTimeRewardsApplicable(rewardToken);
    if (account != address(0)) {
      rewards[account][rewardToken] = earned(account, rewardToken);
      userRewardsPerTokenPaid[account][rewardToken] = rewardsPerTokenStored[rewardToken];
    }
  }

  /* ========== EVENTS ========== */

  event Deposited(address indexed user, uint256 amount);
  event Withdrawn(address indexed user, uint256 totalAmount, uint256 fee);
  event RewardsPaid(address indexed user, address indexed rewardToken, uint256 reward);
  event RewardTokenAdded(address indexed rewardToken);
  event RewardsAdded(address indexed rewardToken, address indexed rewarder, uint256 reward, uint256 rewardDuration);
  event RewarderAdded(address indexed rewarder);
  event RewarderRemoved(address indexed rewarder);
  event AdminFeeAccrued(address indexed user, uint256 totalAmount, uint256 fee);
  event AdminFeeWithdrawn(address indexed rewarder, address indexed to, uint256 amount);
}