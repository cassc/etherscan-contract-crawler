// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/structs/DoubleEndedQueue.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';
import "./interfaces/IBoostableFarm.sol";
import "./interfaces/IRewardBooster.sol";
import "../interfaces/ICurvePool.sol";

contract RewardBooster is IRewardBooster, Ownable, ReentrancyGuard {
  using Counters for Counters.Counter;
  using SafeMath for uint256;
  using SafeERC20 for IERC20;
  using DoubleEndedQueue for DoubleEndedQueue.Bytes32Deque;

  IUniswapV2Pair public lsdEthPair;
  ICurvePool public ethxPool;
  IBoostableFarm public farm;
  address public zapStakeDelegator;

  uint256 public stakePeriod = 7 days;

  Counters.Counter private _nextStakeId;
  mapping(address => DoubleEndedQueue.Bytes32Deque) private _userStakes;
  mapping(uint256 => StakeInfo) private _allUserStakes;
  uint256 public constant MAX_STAKES_COUNT_PER_USER = 10;

  uint256 public constant DECIMALS = 1e18;
  uint256 public constant MAX_BOOST_RATE = 10 * DECIMALS;
  uint256 public constant PRECISION = 1e10;

  struct StakeInfo {
    uint256 id;
    uint256 amount;
    uint256 startTime;
    uint256 endTime;
  }

  constructor(address _lsdEthPair, address _ethxPool, address _farm) Ownable() {
    require(_lsdEthPair != address(0), "Zero address detected");
    require(_ethxPool != address(0), "Zero address detected");
    require(_farm != address(0), "Zero address detected");

    lsdEthPair = IUniswapV2Pair(_lsdEthPair);
    ethxPool = ICurvePool(_ethxPool);
    farm = IBoostableFarm(_farm);
  }

  /*******************************************************/
  /***********************  VIEWS ************************/
  /*******************************************************/

  function assertStakeCount(address user) external view {
    require(user != address(0), "Zero address detected");
    require(_userStakes[user].length() < MAX_STAKES_COUNT_PER_USER, "Too many stakes");
  }

  function userStakesCount(address user) public virtual view returns (uint256) {
    return _userStakes[user].length();
  }

  function stakeOfUserByIndex(address user, uint256 index) public virtual view returns (StakeInfo memory) {
    DoubleEndedQueue.Bytes32Deque storage userStakeIds = _userStakes[user];
    require(index < userStakeIds.length(), 'Invalid index');

    uint256 stakeId = uint256(userStakeIds.at(index));
    return _allUserStakes[stakeId];
  }
 
  /**
   * @dev Get the amount of LP tokens that can be unstaked for a user
   * @return Amount of LP tokens that could be unstaked
   * @return Total amount of staked LP tokens
   */
  function getStakeAmount(address user) public view returns (uint256, uint256) {
    uint256 unstakeableAmount = 0;
    uint256 totalStakedAmount = 0;

    for (uint256 index = 0; index < userStakesCount(user); index++) {
      StakeInfo memory stakeInfo = stakeOfUserByIndex(user, index);
      require(stakeInfo.amount > 0, "Invalid stake info");
      if (block.timestamp >= stakeInfo.endTime) {
        unstakeableAmount = unstakeableAmount.add(stakeInfo.amount);
      }
      totalStakedAmount = totalStakedAmount.add(stakeInfo.amount);
    }
    return (unstakeableAmount, totalStakedAmount);
  }

  function getUserBoostRate(address user, uint256 ethxAmount) external view returns (uint256) {
    (, uint256 lpAmount) = getStakeAmount(user);
    return getBoostRate(lpAmount, ethxAmount);
  }

  function getBoostRate(uint256 lpAmount, uint256 ethxAmount) public view returns (uint256) {
    (uint256 ethReserve, , ) = lsdEthPair.getReserves();
    uint256 lpAmountETHValue = lpAmount.mul(PRECISION).mul(ethReserve).div(lsdEthPair.totalSupply()).mul(2);

    uint256 ethxAmountETHValue = ICurvePool(ethxPool).get_virtual_price().mul(ethxAmount).div(DECIMALS);
    if (ethxAmountETHValue == 0) {
      return 1 * DECIMALS;
    }

    uint256 boostRate = lpAmountETHValue.mul(10).mul(DECIMALS).div(ethxAmountETHValue).div(PRECISION);
    return Math.min(boostRate.add(1 * DECIMALS), MAX_BOOST_RATE);
  }

  /*******************************************************/
  /****************** MUTATIVE FUNCTIONS *****************/
  /*******************************************************/

  function stake(uint256 amount) external nonReentrant {
    uint256 stakeId = _stakeFor(_msgSender(), amount);
    emit Stake(_msgSender(), stakeId, amount);
  }

  function delegateZapStake(address user, uint256 amount) external nonReentrant onlyZapStakeDelegator(_msgSender()) {
    uint256 stakeId = _stakeFor(user, amount);
    emit DelegateZapStake(user, stakeId, amount);
  }

  function _stakeFor(address user, uint256 amount) private returns (uint256) {
    require(user != address(0), "Zero address detected");
    require(amount > 0, "Amount must be greater than 0");
    require(_userStakes[user].length() < MAX_STAKES_COUNT_PER_USER, "Too many stakes");

    _nextStakeId.increment();
    uint256 stakeId = _nextStakeId.current();

    IERC20(address(lsdEthPair)).safeTransferFrom(_msgSender(), address(this), amount);
    StakeInfo memory stakeInfo = StakeInfo(stakeId, amount, block.timestamp, block.timestamp.add(stakePeriod));
    _userStakes[user].pushBack(bytes32(stakeId));
    _allUserStakes[stakeId] = stakeInfo;

    farm.updateBoostRate(user);

    return stakeId;
  }

  function unstake(uint256 amount) external nonReentrant {
    require(amount > 0, "Amount must be greater than 0");

    (uint256 unstakeableAmount,) = getStakeAmount(_msgSender());
    require(amount <= unstakeableAmount, "Not enough tokens to unstake");

    uint256 remainingAmount = amount;
    for (uint256 index = 0; index < userStakesCount(_msgSender()); ) {
      StakeInfo storage stakeInfo = _allUserStakes[uint256(_userStakes[_msgSender()].at(index))];

      uint256 stakeId = stakeInfo.id;
      require(stakeInfo.amount > 0, "Invalid stake info");

      bool unstakeable = block.timestamp >= stakeInfo.endTime;
      if (!unstakeable) {
        break;
      }

      uint256 unstakeAmount = 0;
      if (remainingAmount >= stakeInfo.amount) {
        unstakeAmount = stakeInfo.amount;
        _userStakes[_msgSender()].popFront();
        delete _allUserStakes[stakeId];
      }
      else {
        unstakeAmount = remainingAmount;
        stakeInfo.amount = stakeInfo.amount.sub(unstakeAmount);
      }

      IERC20(address(lsdEthPair)).safeTransfer(_msgSender(), unstakeAmount);
      emit Unstake(_msgSender(), stakeId, unstakeAmount);
      remainingAmount = remainingAmount.sub(unstakeAmount);
      if (remainingAmount == 0) {
        break;
      }
    }

    farm.updateBoostRate(_msgSender());
  }


  /********************************************/
  /*********** RESTRICTED FUNCTIONS ***********/
  /********************************************/

  function setZapStakeDelegator(address _zapStakeDelegator) external onlyOwner {
    require(_zapStakeDelegator != address(0), "Zero address detected");
    zapStakeDelegator = _zapStakeDelegator;
  }

  /***********************************************/
  /****************** MODIFIERS ******************/
  /***********************************************/

  modifier onlyZapStakeDelegator(address _address) {
    require(zapStakeDelegator == _address, "Not zap stake delegator");
    _;
  }

  /********************************************/
  /****************** EVENTS ******************/
  /********************************************/

  event Stake(address indexed userAddress, uint256 stakeId, uint256 amount);
  event DelegateZapStake(address indexed userAddress, uint256 stakeId, uint256 amount);
  event Unstake(address indexed userAddress, uint256 stakeId, uint256 amount);
}