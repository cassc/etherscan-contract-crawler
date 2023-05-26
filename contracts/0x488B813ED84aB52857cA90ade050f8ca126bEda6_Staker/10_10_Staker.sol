//SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.17;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Staker is Pausable, Ownable, ReentrancyGuard {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  IERC20 public rewardsToken;
  IERC20 public stakingToken;

  uint256 public periodFinish = 0;
  uint256 public rewardRate = 0;
  uint256 public rewardsDuration;
  uint256 public lastUpdateTime;
  uint256 public rewardPerTokenStored;
  uint256 public stakingTokensDecimalRate;
  address public stakeAdmin;
  uint256 public lockDuration;
  bool public locked;

  uint256 public constant MAX_UNSTAKE_FEE = 10000;
  uint256 public earlyUnstakeFee = 10000; // 100%
  uint256 public fixedRate = 0;

  mapping(address => uint256) public userRewardPerTokenPaid;
  mapping(address => uint256) public rewards;
  mapping(address => uint256) public lockFinishPerUser;

  bool private initialised;
  uint256 private _totalSupply;
  mapping(address => uint256) private _balances;

  modifier notContract() {
    require(!_isContract(msg.sender), "contract not allowed");
    require(msg.sender == tx.origin, "proxy contract not allowed");
    _;
  }

  function _isContract(address addr) internal view returns (bool) {
    uint256 size;
    assembly {
      size := extcodesize(addr)
    }
    return size > 0;
  }

  /* ========== CONSTRUCTOR ========== */

  constructor(
    address _rewardsToken,
    address _stakingToken,
    uint _rewardsDuration,
    uint _stakingTokensDecimal,
    bool _locked,
    address _admin,
    uint _fixedRate
  ) {
    stakingTokensDecimalRate = pow(10, _stakingTokensDecimal);
    rewardsToken = IERC20(_rewardsToken);
    stakingToken = IERC20(_stakingToken);
    rewardsDuration = _rewardsDuration;
    locked = _locked;
    if (locked) {
      lockDuration = _rewardsDuration;
    }
    stakeAdmin = _admin;
    fixedRate = _fixedRate;
  }

  /* ========== VIEWS ========== */

  function totalSupply() external view returns (uint256) {
    return _totalSupply;
  }

  function rewardsBalance() external view returns (uint256) {
    uint256 balance = rewardsToken.balanceOf(address(this));
    return balance - _totalSupply;
  }

  function totalInterest() external view returns (uint256) {
    if (fixedRate > 0) {
      return _totalSupply.mul(rewardPerToken()).div(stakingTokensDecimalRate);
      // this will return a estimated maximum interest
      // return _totalSupply.mul(fixedRate).div(10000).mul(rewardsDuration).div(31536000);
    } else {
      // not needed for dynamic apy
      return 0;
    }
  }

  function pow(uint n, uint e) private pure returns (uint) {
    if (e == 0) {
      return 1;
    } else if (e == 1) {
      return n;
    } else {
      uint p = pow(n, e.div(2));
      p = p.mul(p);
      if (e.mod(2) == 1) {
        p = p.mul(n);
      }
      return p;
    }
  }

  function balanceOf(address account) external view returns (uint256) {
    return _balances[account];
  }

  function lastTimeRewardApplicable() public view returns (uint256) {
    return min(block.timestamp, periodFinish);
  }

  function rewardPerToken() public view returns (uint256) {
    if (_totalSupply == 0) {
      return rewardPerTokenStored;
    }
    if (fixedRate > 0) {
      return
        rewardPerTokenStored.add(
          lastTimeRewardApplicable()
            .sub(lastUpdateTime)
            .mul(fixedRate)
            .div(10000)
            .mul(stakingTokensDecimalRate)
            .div(31536000) // percent:  1% == 100 // one year
        );
    }

    return
      rewardPerTokenStored.add(
        lastTimeRewardApplicable()
          .sub(lastUpdateTime)
          .mul(rewardRate)
          .mul(stakingTokensDecimalRate)
          .div(_totalSupply)
      );
  }

  function earned(address account) public view returns (uint256) {
    return
      _balances[account]
        .mul(rewardPerToken().sub(userRewardPerTokenPaid[account]))
        .div(stakingTokensDecimalRate)
        .add(rewards[account]);
  }

  function getRewardForDuration() external view returns (uint256) {
    return rewardRate.mul(rewardsDuration);
  }

  function min(uint256 a, uint256 b) private pure returns (uint256) {
    return a < b ? a : b;
  }

  function PoolInfo()
    public
    view
    returns (
      uint256 _periodFinish,
      uint256 _rewardRate,
      uint256 _rewardsDuration,
      uint256 _lastUpdateTime,
      uint256 _rewardPerToken,
      uint256 _getRewardForDuration,
      uint256 _lockDuration,
      uint256 _earlyUnstakeFee,
      uint256 _totSupply,
      uint256 _fixedRate,
      uint256 _timeLeft
    )
  {
    _periodFinish = periodFinish;
    _rewardRate = rewardRate;
    _rewardsDuration = rewardsDuration;
    _lastUpdateTime = lastUpdateTime;
    _rewardPerToken = rewardPerToken();
    _getRewardForDuration = rewardRate.mul(rewardsDuration);
    _lockDuration = lockDuration;
    _earlyUnstakeFee = earlyUnstakeFee;
    _totSupply = _totalSupply;
    _fixedRate = fixedRate;

    if (periodFinish > block.timestamp)
      _timeLeft = periodFinish.sub(block.timestamp);
    else _timeLeft = 0;
  }

  function UserInfo(
    address account
  )
    public
    view
    returns (uint256 _balanceOf, uint256 _earned, uint256 _rewards, uint256 _lockFinish, uint256 _timeLeft)
  {
    _balanceOf = _balances[account];
    _earned = earned(account);
    _rewards = rewards[account];
    _lockFinish = lockFinishPerUser[account];
    if (_lockFinish > block.timestamp)
      _timeLeft = _lockFinish.sub(block.timestamp);
  }

  /* ========== MUTATIVE FUNCTIONS ========== */

  function stake(
    uint256 amount
  ) external notContract nonReentrant whenNotPaused updateReward(msg.sender) {
    require(amount > 0, "Cannot stake 0");
    _totalSupply = _totalSupply.add(amount);
    _balances[msg.sender] = _balances[msg.sender].add(amount);
    stakingToken.safeTransferFrom(msg.sender, address(this), amount);
    lockFinishPerUser[msg.sender] = block.timestamp.add(lockDuration);
    emit Staked(msg.sender, amount);
  }

  function compound() public notContract updateReward(msg.sender) {
    uint256 reward = rewards[msg.sender];
    if (reward > 0) {
      rewards[msg.sender] = 0;
      _totalSupply = _totalSupply.add(reward);
      _balances[msg.sender] = _balances[msg.sender].add(reward);
      emit Compounded(msg.sender, reward);
    }
  }

  function withdraw(
    uint256 amount
  ) public notContract nonReentrant updateReward(msg.sender) {
    require(amount > 0, "Cannot withdraw 0");
    if (locked) {
      require(block.timestamp >= lockFinishPerUser[msg.sender], "Lock Time is not over");
    }
    _totalSupply = _totalSupply.sub(amount);
    _balances[msg.sender] = _balances[msg.sender].sub(amount);
    stakingToken.safeTransfer(msg.sender, amount);
    emit Withdrawn(msg.sender, amount);
  }

  function getReward()
    public
    nonReentrant
    notContract
    updateReward(msg.sender)
  {
    uint256 reward = rewards[msg.sender];
    if (reward > 0) {
      rewards[msg.sender] = 0;
      rewardsToken.safeTransfer(msg.sender, reward);
      emit RewardPaid(msg.sender, reward);
    }
  }

  function emergencyWithdraw(
    uint256 amount //allows you to exit the contract before unlock time, at a penalty to your balance
  ) public notContract updateReward(msg.sender) {
    require(amount > 0, "Cannot withdraw 0");
    getReward();
    _totalSupply = _totalSupply.sub(amount);
    _balances[msg.sender] = _balances[msg.sender].sub(amount);
    if (earlyUnstakeFee > 0) {
      uint256 adminFee = amount.mul(earlyUnstakeFee).div(10000);
      amount -= adminFee;
      stakingToken.safeTransfer(stakeAdmin, adminFee);
    }
    stakingToken.safeTransfer(msg.sender, amount);
    emit Withdrawn(msg.sender, amount);
  }

  function exit() external {
    withdraw(_balances[msg.sender]);
    getReward();
  }

  /* ========== RESTRICTED FUNCTIONS ========== */

  function setLockedDuration(uint256 _duration) external onlyOwner {
    if (fixedRate > 0) {
      lockDuration = _duration;
    }
  }

  function setApr(
    uint256 _newRate
  ) external onlyOwner updateReward(address(0)) {
    require(
      _newRate > 0 && fixedRate > 0,
      "New rate must be > 0 and pool must have fixed APR"
    );
    fixedRate = _newRate;
  }

  // * Use this only once for fixed rate
  function notifyRewardAmount(
    uint256 reward
  ) external onlyOwner updateReward(address(0)) {
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
    uint256 balance = rewardsToken.balanceOf(address(this));
    require(
      rewardRate <= balance.div(rewardsDuration),
      "Provided reward too high"
    );

    lastUpdateTime = block.timestamp;
    periodFinish = block.timestamp.add(rewardsDuration);
    emit RewardAdded(reward);
  }

  function setEarlyUnstakeFee(uint256 _earlyUnstakeFee) external onlyOwner {
    require(
      _earlyUnstakeFee <= MAX_UNSTAKE_FEE,
      "earlyUnstakeFee cannot be more than MAX_UNSTAKE_FEE"
    );
    earlyUnstakeFee = _earlyUnstakeFee;
  }

  // function setTokenInternalFee(uint256 _tokenInternalFess) external onlyOwner {
  //     tokenInternalFess = _tokenInternalFess;
  // }

  function manualUnlock() external onlyOwner {
    locked = false;
  }

  function recoverERC20(
    address tokenAddress,
    uint256 tokenAmount
  ) external onlyOwner {
    // require(block.timestamp >= periodFinish + 2 hours, "Period is not over");
    IERC20(tokenAddress).safeTransfer(msg.sender, tokenAmount);
    emit Recovered(tokenAddress, tokenAmount);
  }

  function setRewardsDuration(uint256 _rewardsDuration) external onlyOwner {
    require(
      block.timestamp > periodFinish || fixedRate > 0,
      "Previous rewards period must be complete before changing the duration for the new period"
    );
    rewardsDuration = _rewardsDuration;
    emit RewardsDurationUpdated(rewardsDuration);
  }

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
  event RewardsDurationUpdated(uint256 newDuration);
  event Recovered(address token, uint256 amount);
  event Compounded(address indexed user, uint256 amount);
}