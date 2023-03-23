// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "../interfaces/IStakingPool.sol";

abstract contract StakingPoolV2 is IStakingPool, Ownable, ReentrancyGuard {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  /* ========== STATE VARIABLES ========== */

  IERC20 public rewardsToken;
  IERC20 public stakingToken;
  uint256 public periodFinish = 0;
  uint256 public rewardRate = 0;
  uint256 public rewardsDuration;
  uint256 public lastUpdateTime;
  uint256 public rewardPerTokenStored;

  mapping(address => uint256) public userRewardPerTokenPaid;
  mapping(address => uint256) public rewards;

  uint256 internal _totalSupply;
  mapping(address => uint256) private _balances;

  /* ========== CONSTRUCTOR ========== */

  constructor(
    address _rewardsToken,
    address _stakingToken,
    uint256 _durationInDays
  ) Ownable() {
    rewardsToken = IERC20(_rewardsToken);
    stakingToken = IERC20(_stakingToken);
    rewardsDuration = _durationInDays.mul(3600 * 24);
  }

  receive() external payable virtual {}

  /* ========== VIEWS ========== */

  function totalSupply() external view returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address account) external view returns (uint256) {
    return _balances[account];
  }

  function lastTimeRewardApplicable() public view returns (uint256) {
    return Math.min(block.timestamp, periodFinish);
  }

  function rewardPerToken() public view returns (uint256) {
    if (_totalSupply == 0) {
      return rewardPerTokenStored;
    }
    return
      rewardPerTokenStored.add(
        lastTimeRewardApplicable().sub(lastUpdateTime).mul(rewardRate).mul(1e18).div(_totalSupply)
      );
  }

  function earned(address account) public view returns (uint256) {
    return _balances[account].mul(rewardPerToken().sub(userRewardPerTokenPaid[account])).div(1e18).add(rewards[account]);
  }

  function getRewardForDuration() external view returns (uint256) {
    return rewardRate.mul(rewardsDuration);
  }

  /* ========== MUTATIVE FUNCTIONS ========== */

  function stake(uint256 amount) external virtual payable nonReentrant updateReward(msg.sender) {
    require(amount > 0, "Cannot stake 0");
    _totalSupply = _totalSupply.add(amount);
    _balances[msg.sender] = _balances[msg.sender].add(amount);
    // console.log('stake, msg.sender balance: %s', stakingToken.balanceOf(msg.sender));
    _transferStakingToken(amount);
    emit Staked(msg.sender, amount);
  }

  function _transferStakingToken(uint256 amount) internal virtual {
    stakingToken.safeTransferFrom(msg.sender, address(this), amount);
  }

  function withdraw(uint256 amount) public virtual nonReentrant updateReward(msg.sender) {
    require(amount > 0, "Cannot withdraw 0");
    _totalSupply = _totalSupply.sub(amount);
    _balances[msg.sender] = _balances[msg.sender].sub(amount);
    _withdrawStakingToken(amount);
    emit Withdrawn(msg.sender, amount);
  }

  function _withdrawStakingToken(uint256 amount) internal virtual {
    stakingToken.safeTransfer(msg.sender, amount);
  }

  function getReward() public nonReentrant updateReward(msg.sender) {
    uint256 reward = rewards[msg.sender];
    if (reward > 0) {
      rewards[msg.sender] = 0;
      rewardsToken.safeTransfer(msg.sender, reward);
      emit RewardPaid(msg.sender, reward);
    }
  }

  function exit() external {
    withdraw(_balances[msg.sender]);
    getReward();
  }

  /* ========== RESTRICTED FUNCTIONS ========== */

  function addRewards(uint256 rewardsAmount) external onlyOwner {
    if (rewardsAmount > 0) {
      rewardsToken.safeTransferFrom(msg.sender, address(this), rewardsAmount);
      notifyRewardAmount(rewardsAmount);
    }
  }

  function notifyRewardAmount(uint256 reward) internal virtual onlyOwner updateReward(address(0)) {
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
    uint balance = rewardsToken.balanceOf(address(this));
    require(rewardRate <= balance.div(rewardsDuration), "Provided reward too high");

    lastUpdateTime = block.timestamp;
    periodFinish = block.timestamp.add(rewardsDuration);
    emit RewardAdded(reward);
  }

  function adminRewards() external virtual returns (uint256);

  function withdrawAdminRewards(address to) external virtual;

  /* ========== MODIFIERS ========== */

  modifier updateReward(address account) {
    rewardPerTokenStored = rewardPerToken();
    lastUpdateTime = lastTimeRewardApplicable();
    if (account != address(0)) {
      rewards[account] = earned(account);
      userRewardPerTokenPaid[account] = rewardPerTokenStored;
    }
    _;
  }

  /* ========== EVENTS ========== */

  event RewardAdded(uint256 reward);
  event Staked(address indexed user, uint256 amount);
  event Withdrawn(address indexed user, uint256 amount);
  event RewardPaid(address indexed user, uint256 reward);
  event AdminRewardWithdrawn(address indexed to, uint256 amount);
}