// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/security/Pausable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

// import "@nomiclabs/buidler/console.sol";
contract CirusStaking is Ownable, Pausable, ReentrancyGuard {
  using SafeERC20 for IERC20;

  // Info of each user.
  struct UserInfo {
    uint256 amount;
    uint256 rewardDebt;
  }

  uint256 internal lastRewardTime; // Last reward time that Cirus distribution occurs.
  uint256 internal accCirusPerShare; // Accumulated Cirus per share, times mulDecimal. See below.

  // The REWARD TOKEN
  IERC20 constant public cirusToken = IERC20(0xA01199c61841Fce3b3daFB83FeFC1899715c8756);

  // Cirus tokens created per second.
  uint256 public rewardPerSecond;

  // Cirus tokens created per month.
  uint256 public rewardPerMonth; //= 50000 * 10 ** 18;

  // Info of each user that stakes Cirus tokens.
  mapping(address => UserInfo) public stakeHistory;

  uint256 public startTime;

  uint256 public totalStakedAmount = 0;

  uint256 public immutable mulDecimal = 1e12;
  uint256 public constant secondsPerMonth = 30 * 24 * 60 * 60;

  uint256 constant public fee = 15;

  // The rewards will be transferred from this address
  address public rewarderAddr;

  // fees will transfer to this address when user deposit token.
  address public feeCollectAddr;

  event Staked(address staker, uint256 amount);
  event Withdrawed(address withdrawer, uint256 amount);
  event RedeemReward(address withdrawer, uint256 amount);
  event EmergencyWithdrawed(address withdrawer, uint256 amount);

  /// @notice This is a contract for the Cirus Token
  /// A fee of 15% will be collected as the result of the deposit
  /// The rest of the deposit will go into to staking contract where
   /// @param _startTime startingtime of the delivery of tokens
  /// @param _rewardPerMonth rewards that will be distrubuted per month
  /// @param _rewarderAddr address that will reward all tokens to the users
  /// @param _feeCollectAddr address of the Fee Collector
  constructor(
    uint256 _startTime,
    uint256 _rewardPerMonth,
    address _rewarderAddr,
    address _feeCollectAddr
  ) {
    require(_feeCollectAddr != address(0x0));
    require(_rewarderAddr != address(0x0));
    startTime = _startTime;
    if (startTime < block.timestamp) {
      startTime = block.timestamp;
    }
    lastRewardTime = startTime;
    rewarderAddr = _rewarderAddr;
    feeCollectAddr = _feeCollectAddr;
    rewardPerMonth = _rewardPerMonth;
    rewardPerSecond = (rewardPerMonth / secondsPerMonth); // 1 month = 30day, 1 day = 24 hour, 1 hour = 60 min, 1 min = 60 sec
    accCirusPerShare = 0;
  }

  /// @notice Return reward multiplier over the given _from to _to block.
  function getMultiplier(uint256 _from, uint256 _to)
    public
    pure
    returns (uint256)
  {
    uint256 sub = _to - _from;
    return sub;
  }

  /// @notice View function to see pending Reward on frontend.
  /// @param _user the user you want to check rewards from
  function pendingReward(address _user) external view returns (uint256 reward) {
    require(_user != address(0x0));
    UserInfo storage user = stakeHistory[_user];
    uint256 accCirusPerShareN = accCirusPerShare;
    if (block.timestamp > lastRewardTime && totalStakedAmount != 0) {
      uint256 multiplier = getMultiplier(lastRewardTime, block.timestamp);
      uint256 cirusReward = (multiplier * rewardPerSecond);
      accCirusPerShareN =
        accCirusPerShareN +
        ((cirusReward * (mulDecimal)) / (totalStakedAmount));
    }

    reward =
      ((user.amount * (accCirusPerShareN)) / (mulDecimal)) -
      (user.rewardDebt);
  }

  /// @notice View function to see pending Reward on frontend.
  /// @param _user the user you want to check staking token amount from
  function stakedAmount(address _user) public view returns (uint256 amount) {
    amount = stakeHistory[_user].amount;
  }

  /// @notice Pool will get updated
  function updatePool() internal {
    if (block.timestamp <= lastRewardTime) {
      return;
    }
    if (totalStakedAmount == 0) {
      lastRewardTime = block.timestamp;
      return;
    }
    uint256 multiplier = getMultiplier(lastRewardTime, block.timestamp);
    uint256 cirusReward = multiplier * (rewardPerSecond);
    accCirusPerShare =
      accCirusPerShare +
      ((cirusReward * (mulDecimal)) / (totalStakedAmount));
    lastRewardTime = block.timestamp;
  }

  /// @notice Stake tokens to CirusStaking Contract.
  /// A Fee will be collected as the result of the deposit
  /// Rest deposit to staking contract.
  /// @param _amount amount of tokens you want to deposit into the contract
  function deposit(uint256 _amount) public whenNotPaused nonReentrant {
    require(_amount > 0, 'Invalid deposit amount');
    uint256 tokenAmountToStake = _amount - ((_amount * fee) / 100);
    UserInfo storage user = stakeHistory[msg.sender];
    
    uint userAmount = user.amount;
    uint reward = user.rewardDebt;
        
    updatePool();
    
    user.amount = userAmount + (tokenAmountToStake);
    totalStakedAmount = totalStakedAmount + (tokenAmountToStake);
    user.rewardDebt = (user.amount * (accCirusPerShare)) / (mulDecimal);

    cirusToken.safeTransferFrom(
      msg.sender,
      feeCollectAddr,
      _amount - tokenAmountToStake
    );
    cirusToken.safeTransferFrom(msg.sender, address(this), tokenAmountToStake);
    if (userAmount > 0) {
      uint256 pending = ((userAmount * (accCirusPerShare)) / (mulDecimal)) -
        (reward);
      if (pending > 0) {
        cirusToken.safeTransferFrom(rewarderAddr, address(msg.sender), pending);
      }
    }
    emit Staked(msg.sender, tokenAmountToStake);
  }

  /// @notice Withdraw tokens from STAKING.
  /// @param _amount amount of tokens you want to deposit into the contract
  function withdraw(uint256 _amount) public nonReentrant whenNotPaused {
    UserInfo storage user = stakeHistory[msg.sender];
    require(user.amount >= _amount, 'withdraw: not good');
    updatePool();
    uint256 pending = ((user.amount * (accCirusPerShare)) / (mulDecimal)) -
      (user.rewardDebt);
    if (pending > 0) {
      cirusToken.safeTransferFrom(rewarderAddr, address(msg.sender), pending);
    }
    if (_amount > 0) {
      cirusToken.safeTransfer(address(msg.sender), _amount);
      user.amount = user.amount - (_amount);
      totalStakedAmount = totalStakedAmount - (_amount);
    }
    user.rewardDebt = (user.amount * (accCirusPerShare)) / (mulDecimal);

    emit Withdrawed(msg.sender, _amount);
  }

  /// @notice Withdraw without caring about rewards. EMERGENCY ONLY.
  function emergencyWithdraw() public nonReentrant {
    UserInfo storage user = stakeHistory[msg.sender];
    uint256 emergencyAmount = user.amount;
    user.amount = 0;
    user.rewardDebt = 0;
    totalStakedAmount -= (emergencyAmount);
    cirusToken.safeTransfer(address(msg.sender), emergencyAmount);
    emit EmergencyWithdrawed(msg.sender, emergencyAmount);
  }

  /// @notice Owner can set Monthly Reward amount here.
  function updateRewardAmount(uint256 _rewardPerMonth) public onlyOwner {
    rewardPerMonth = _rewardPerMonth;
    rewardPerSecond = rewardPerMonth / (secondsPerMonth);
  }

  /// @notice Withdraw only reward
  function getReward() public whenNotPaused {
    UserInfo storage user = stakeHistory[msg.sender];
    updatePool();
    uint256 pending = ((user.amount * (accCirusPerShare)) / (mulDecimal)) -
      (user.rewardDebt);
    if (pending > 0) {
      cirusToken.safeTransferFrom(rewarderAddr, address(msg.sender), pending);
    }
    user.rewardDebt = (user.amount * (accCirusPerShare)) / (mulDecimal);
    emit RedeemReward(msg.sender, pending);
  }

  /// @notice returns the estimated APY for the vault
  /// @return apy estimatedAPY
  /// @dev should divide 100 this value
  function estimatedAPY() public view returns (uint256 apy) {
    uint256 const = 120000;
    if (totalStakedAmount == 0) {
      apy = 0;
    } else {
      apy = (rewardPerMonth * const) / (totalStakedAmount);
    }
  }
}