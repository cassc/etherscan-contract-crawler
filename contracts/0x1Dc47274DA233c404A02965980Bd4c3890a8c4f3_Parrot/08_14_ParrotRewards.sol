// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/interfaces/IERC20.sol';
import './interfaces/IParrotRewards.sol';

contract ParrotRewards is IParrotRewards, Ownable {
  uint256 private constant ONE_DAY = 60 * 60 * 24;
  int256 private constant OFFSET19700101 = 2440588;

  struct Reward {
    uint256 totalExcluded;
    uint256 totalRealised;
    uint256 lastClaim;
  }

  struct Share {
    uint256 amount;
    uint256 lockedTime;
  }

  uint256 public timeLock = 30 days;
  address public shareholderToken;
  uint256 public totalLockedUsers;
  uint256 public totalSharesDeposited;

  uint8 public minDayOfMonthCanLock = 1;
  uint8 public maxDayOfMonthCanLock = 5;

  // amount of shares a user has
  mapping(address => Share) public shares;
  // reward information per user
  mapping(address => Reward) public rewards;

  uint256 public totalRewards;
  uint256 public totalDistributed;
  uint256 public rewardsPerShare;

  uint256 private constant ACC_FACTOR = 10**36;

  event ClaimReward(address wallet);
  event DistributeReward(address indexed wallet, address payable receiver);
  event DepositRewards(address indexed wallet, uint256 amountETH);

  constructor(address _shareholderToken) {
    shareholderToken = _shareholderToken;
  }

  function lock(uint256 _amount) external {
    uint256 _currentDayOfMonth = _dayOfMonth(block.timestamp);
    require(
      _currentDayOfMonth >= minDayOfMonthCanLock &&
        _currentDayOfMonth <= maxDayOfMonthCanLock,
      'outside of allowed lock window'
    );
    address shareholder = msg.sender;
    IERC20 tokenContract = IERC20(shareholderToken);
    _amount = _amount == 0 ? tokenContract.balanceOf(shareholder) : _amount;
    tokenContract.transferFrom(shareholder, address(this), _amount);
    _addShares(shareholder, _amount);
  }

  function unlock(uint256 _amount) external {
    address shareholder = msg.sender;
    require(
      block.timestamp >= shares[shareholder].lockedTime + timeLock,
      'must wait the time lock before unstaking'
    );
    _amount = _amount == 0 ? shares[shareholder].amount : _amount;
    require(_amount > 0, 'need tokens to unlock');
    require(
      _amount <= shares[shareholder].amount,
      'cannot unlock more than you have locked'
    );
    IERC20(shareholderToken).transfer(shareholder, _amount);
    _removeShares(shareholder, _amount);
  }

  function _addShares(address shareholder, uint256 amount) internal {
    _distributeReward(shareholder);

    uint256 sharesBefore = shares[shareholder].amount;
    totalSharesDeposited += amount;
    shares[shareholder].amount += amount;
    shares[shareholder].lockedTime = block.timestamp;
    if (sharesBefore == 0 && shares[shareholder].amount > 0) {
      totalLockedUsers++;
    }
    rewards[shareholder].totalExcluded = getCumulativeRewards(
      shares[shareholder].amount
    );
  }

  function _removeShares(address shareholder, uint256 amount) internal {
    amount = amount == 0 ? shares[shareholder].amount : amount;
    require(
      shares[shareholder].amount > 0 && amount <= shares[shareholder].amount,
      'you can only unlock if you have some lockd'
    );
    _distributeReward(shareholder);

    totalSharesDeposited -= amount;
    shares[shareholder].amount -= amount;
    if (shares[shareholder].amount == 0) {
      totalLockedUsers--;
    }
    rewards[shareholder].totalExcluded = getCumulativeRewards(
      shares[shareholder].amount
    );
  }

  function depositRewards() public payable override {
    _depositRewards(msg.value);
  }

  function _depositRewards(uint256 _amount) internal {
    require(_amount > 0, 'must provide ETH to deposit');
    require(totalSharesDeposited > 0, 'must be shares deposited');

    totalRewards += _amount;
    rewardsPerShare += (ACC_FACTOR * _amount) / totalSharesDeposited;
    emit DepositRewards(msg.sender, _amount);
  }

  function _distributeReward(address shareholder) internal {
    if (shares[shareholder].amount == 0) {
      return;
    }

    uint256 amount = getUnpaid(shareholder);

    rewards[shareholder].totalRealised += amount;
    rewards[shareholder].totalExcluded = getCumulativeRewards(
      shares[shareholder].amount
    );
    rewards[shareholder].lastClaim = block.timestamp;

    if (amount > 0) {
      address payable receiver = payable(shareholder);
      totalDistributed += amount;
      uint256 balanceBefore = address(this).balance;
      receiver.call{ value: amount }('');
      require(address(this).balance >= balanceBefore - amount);
      emit DistributeReward(shareholder, receiver);
    }
  }

  function _dayOfMonth(uint256 _timestamp) internal pure returns (uint256) {
    (, , uint256 day) = _daysToDate(_timestamp / ONE_DAY);
    return day;
  }

  // date conversion algorithm from http://aa.usno.navy.mil/faq/docs/JD_Formula.php
  function _daysToDate(uint256 _days)
    internal
    pure
    returns (
      uint256,
      uint256,
      uint256
    )
  {
    int256 __days = int256(_days);

    int256 L = __days + 68569 + OFFSET19700101;
    int256 N = (4 * L) / 146097;
    L = L - (146097 * N + 3) / 4;
    int256 _year = (4000 * (L + 1)) / 1461001;
    L = L - (1461 * _year) / 4 + 31;
    int256 _month = (80 * L) / 2447;
    int256 _day = L - (2447 * _month) / 80;
    L = _month / 11;
    _month = _month + 2 - 12 * L;
    _year = 100 * (N - 49) + _year + L;

    return (uint256(_year), uint256(_month), uint256(_day));
  }

  function claimReward() external override {
    _distributeReward(msg.sender);
    emit ClaimReward(msg.sender);
  }

  // returns the unpaid rewards
  function getUnpaid(address shareholder) public view returns (uint256) {
    if (shares[shareholder].amount == 0) {
      return 0;
    }

    uint256 earnedRewards = getCumulativeRewards(shares[shareholder].amount);
    uint256 rewardsExcluded = rewards[shareholder].totalExcluded;
    if (earnedRewards <= rewardsExcluded) {
      return 0;
    }

    return earnedRewards - rewardsExcluded;
  }

  function getCumulativeRewards(uint256 share) internal view returns (uint256) {
    return (share * rewardsPerShare) / ACC_FACTOR;
  }

  function getLockedShares(address user)
    external
    view
    override
    returns (uint256)
  {
    return shares[user].amount;
  }

  function setMinDayOfMonthCanLock(uint8 _day) external onlyOwner {
    require(_day <= maxDayOfMonthCanLock, 'can set min day above max day');
    minDayOfMonthCanLock = _day;
  }

  function setMaxDayOfMonthCanLock(uint8 _day) external onlyOwner {
    require(_day >= minDayOfMonthCanLock, 'can set max day below min day');
    maxDayOfMonthCanLock = _day;
  }

  function setTimeLock(uint256 numSec) external onlyOwner {
    require(numSec <= 365 days, 'must be less than a year');
    timeLock = numSec;
  }

  receive() external payable {
    _depositRewards(msg.value);
  }
}