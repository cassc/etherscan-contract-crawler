// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/IBoostableFarm.sol";
import "./interfaces/IRewardBooster.sol";

contract BoostableFarm is IBoostableFarm, Ownable, ReentrancyGuard {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  /********************************************/
  /************* STATE VARIABLES **************/
  /********************************************/

  IERC20 public eslsd;
  IERC20 public ethx;
  uint256 public periodFinish = 0;
  uint256 public rewardRate = 0;
  uint256 public rewardsDuration;
  uint256 public lastUpdateTime;
  uint256 public rewardPerTokenStored;
  uint256 public constant PRECISION = 1e18;

  mapping(address => uint256) public userRewardPerTokenPaid;
  mapping(address => uint256) public rewards;

  uint256 internal _totalSupply;
  mapping(address => uint256) private _balances;

  uint256 internal _totalBoostedSupply;
  mapping(address => uint256) private _boostedBalances;

  address public rewardBooster;

  constructor(
    address _eslsd,
    address _ethx
  ) Ownable() {
    eslsd = IERC20(_eslsd);
    ethx = IERC20(_ethx);
  }

  /********************************************/
  /****************** VIEWS *******************/
  /********************************************/

  function totalSupply() external view returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address account) external view returns (uint256) {
    return _balances[account];
  }

  function totalBoostedSupply() external view returns (uint256) {
    return _totalBoostedSupply;
  }

  function boostedBalanceOf(address account) external view returns (uint256) {
    return _boostedBalances[account];
  }

  function lastTimeRewardApplicable() public view returns (uint256) {
    return Math.min(block.timestamp, periodFinish);
  }

  function rewardPerToken() public view returns (uint256) {
    if (_totalBoostedSupply == 0) {
      return rewardPerTokenStored;
    }
    return
      rewardPerTokenStored.add(
        lastTimeRewardApplicable().sub(lastUpdateTime).mul(rewardRate).mul(PRECISION).div(_totalBoostedSupply)
      );
  }

  function earned(address account) public view returns (uint256) {
    return _boostedBalances[account].mul(rewardPerToken().sub(userRewardPerTokenPaid[account])).div(PRECISION).add(rewards[account]);
  }

  function getRewardForDuration() external view returns (uint256) {
    return rewardRate.mul(rewardsDuration);
  }

  /********************************************/
  /************ MUTATIVE FUNCTIONS ************/
  /********************************************/

  function stake(uint256 amount) external virtual payable nonReentrant updateReward(_msgSender()) {
    require(amount > 0, "Cannot stake 0");
    require(rewardBooster != address(0), "Reward booster not set");

    _totalSupply = _totalSupply.add(amount);
    _balances[_msgSender()] = _balances[_msgSender()].add(amount);

    _updateBoostedBalances(_msgSender());

    ethx.safeTransferFrom(_msgSender(), address(this), amount);
    emit Staked(_msgSender(), amount);
  }

  function withdraw(uint256 amount) public virtual nonReentrant updateReward(_msgSender()) {
    require(amount > 0, "Cannot withdraw 0");
    require(rewardBooster != address(0), "Reward booster not set");

    _totalSupply = _totalSupply.sub(amount);
    _balances[_msgSender()] = _balances[_msgSender()].sub(amount);

    _updateBoostedBalances(_msgSender());

    ethx.safeTransfer(_msgSender(), amount);
    emit Withdrawn(_msgSender(), amount);
  }

  function getReward() public nonReentrant updateReward(_msgSender()) {
    uint256 reward = rewards[_msgSender()];
    if (reward > 0) {
      rewards[_msgSender()] = 0;
      eslsd.safeTransfer(_msgSender(), reward);
      emit RewardPaid(_msgSender(), reward);
    }
    _updateBoostedBalances(_msgSender());
  }

  function updateBoostRate(address account) external nonReentrant updateReward(account) {
    require(account != address(0), "Zero address detected");
    _updateBoostedBalances(account);
  }

  function _updateBoostedBalances(address account) internal {
    uint256 prevBoostedBalance = _boostedBalances[account];
    uint256 boostRate = IRewardBooster(rewardBooster).getUserBoostRate(account, _balances[account]);
    uint256 newBoostedBalance = _balances[account].mul(boostRate).div(PRECISION);
    _boostedBalances[account] = newBoostedBalance;
    _totalBoostedSupply = _totalBoostedSupply.sub(prevBoostedBalance).add(newBoostedBalance);
  }

  /********************************************/
  /*********** RESTRICTED FUNCTIONS ***********/
  /********************************************/

  function addRewards(uint256 rewardsAmount, uint256 rewardsDurationInDays) external onlyOwner {
    require(rewardsAmount > 0, "Reward amount should be greater than 0");
    require(rewardsDurationInDays > 0, 'Reward duration too short');

    eslsd.safeTransferFrom(_msgSender(), address(this), rewardsAmount);
    rewardsDuration = rewardsDurationInDays.mul(1 days);
    _notifyRewardAmount(rewardsAmount);
  }

  function _notifyRewardAmount(uint256 reward) internal updateReward(address(0)) {
    if (block.timestamp >= periodFinish) {
      rewardRate = reward.div(rewardsDuration);
    } else {
      uint256 remaining = periodFinish.sub(block.timestamp);
      uint256 leftover = remaining.mul(rewardRate);
      rewardRate = reward.add(leftover).div(rewardsDuration);
    }

    // Ensure the provided reward amount is not more than the balance in the contract.
    // This keeps the reward rate in the right range, preventing overflows due to
    // very high values of rewardRate in the earned and rewardsPerToken functions;
    // Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.
    uint balance = eslsd.balanceOf(address(this));
    require(rewardRate <= balance.div(rewardsDuration), "Provided reward too high");

    lastUpdateTime = block.timestamp;
    periodFinish = block.timestamp.add(rewardsDuration);
    emit RewardAdded(reward, rewardsDuration);
  }

  function setRewardBooster(address _rewardBooster) external onlyOwner {
    require(_rewardBooster != address(0), "Zero address detected");
    rewardBooster = _rewardBooster;
  }

  /********************************************/
  /***************** MODIFIERS ****************/
  /********************************************/

  modifier updateReward(address account) {
    rewardPerTokenStored = rewardPerToken();
    lastUpdateTime = lastTimeRewardApplicable();
    if (account != address(0)) {
      rewards[account] = earned(account);
      userRewardPerTokenPaid[account] = rewardPerTokenStored;
    }
    _;
  }

  /********************************************/
  /****************** EVENTS ******************/
  /********************************************/

  event RewardAdded(uint256 reward, uint256 rewardDuration);
  event Staked(address indexed user, uint256 amount);
  event Withdrawn(address indexed user, uint256 amount);
  event RewardPaid(address indexed user, uint256 reward);
}