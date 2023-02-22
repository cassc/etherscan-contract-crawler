// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

contract MemepadStakingV2 is OwnableUpgradeable, ReentrancyGuardUpgradeable {
  using SafeMath for uint256;
  using SafeERC20 for IERC20Metadata;

  struct UserInfo {
    address addr; // Address of user
    uint256 amount; // How many staked tokens the user has provided
    uint256 rewardDebt; // Reward debt
    bool registered; // it will add user in address list on first deposit
  }

  // The precision factor
  uint256 private constant _PRECISION_FACTOR = 1e36;

  // Whether it is initialized
  bool public isInitialized;

  // The reward token
  IERC20Metadata public rewardToken;

  // The staked token
  IERC20Metadata public stakedToken;

  // Info of each user that stakes tokens (stakedToken)
  mapping(address => UserInfo) public userInfo;

  // User list
  address[] public userList;

  // Whether a limit is set for users
  bool public hasUserLimit;

  // Accrued token per share
  uint256 public accTokenPerShare;

  // The block number when Pool mining ends.
  uint256 public bonusEndBlock;

  // The block number when Pool mining starts.
  uint256 public startBlock;

  // The block number of the last pool update
  uint256 public lastRewardBlock;

  // The pool limit (0 if none)
  uint256 public poolLimitPerUser;

  // Reward tokens created per block.
  uint256 public rewardPerBlock;

  // Total staking tokens
  uint256 public totalStakingTokens;

  // Total reward tokens
  uint256 public totalRewardTokens;

  // Freeze start block
  uint256 public freezeStartBlock;

  // Freeze end block
  uint256 public freezeEndBlock;

  // Minimum deposit amount
  uint256 public minDepositAmount;

  // Block for withdraw. Allow user can withdraw if block.number >= withdrawBlock
  uint256 public withdrawBlock;

  // Withdraw mode
  // 0: Apply withdrawBlock to both (stake + reward)
  // 1: Apply withdrawBlock to stake
  // 2: Apply withdrawBlock to reward
  uint256 public withdrawMode;

  // Lock to user mode
  bool public enableLockToUser;
  uint256 public lockDuration;
  mapping(address => uint256) public userDepositTimes;

  // User's pending reward
  mapping(address => uint256) public userRewards;

  // Operator
  mapping(address => bool) public isOperator;

  event AdminTokenRecovery(address tokenRecovered, uint256 amount);
  event Deposit(address indexed user, uint256 amount);
  event EmergencyWithdraw(address indexed user, uint256 amount);
  event NewStartAndEndBlocks(uint256 startBlock, uint256 endBlock);
  event NewRewardPerBlock(uint256 rewardPerBlock);
  event NewFreezeBlocks(uint256 freezeStartBlock, uint256 freezeEndBlock);
  event NewPoolLimit(uint256 poolLimitPerUser);
  event RewardsStop(uint256 blockNumber);
  event Withdraw(address indexed user, uint256 amount);
  event AddRewardTokens(address indexed user, uint256 amount);

  /**
   * @dev Upgradable initializer
   */
  function __MemepadStakingV2_init() public initializer {
    __Ownable_init();
    __ReentrancyGuard_init();
  }

  /*
   * @notice Initialize the contract
   * @param _stakedToken: staked token address
   * @param _rewardToken: reward token address
   * @param _rewardPerBlock: reward per block (in rewardToken)
   * @param _startBlock: start block
   * @param _bonusEndBlock: end block
   * @param _poolLimitPerUser: pool limit per user in stakedToken (if any, else 0)
   * @param _admin: admin address with ownership
   */
  function initialize(
    IERC20Metadata _stakedToken,
    IERC20Metadata _rewardToken,
    uint256 _rewardPerBlock,
    uint256 _startBlock,
    uint256 _bonusEndBlock,
    uint256 _poolLimitPerUser,
    uint256 _minDepositAmount,
    uint256 _withdrawBlock,
    uint256 _withdrawMode,
    address _admin
  ) external onlyOwner {
    require(!isInitialized, "Already initialized");

    // Make this contract initialized
    isInitialized = true;

    stakedToken = _stakedToken;
    rewardToken = _rewardToken;
    rewardPerBlock = _rewardPerBlock;
    startBlock = _startBlock;
    bonusEndBlock = _bonusEndBlock;
    minDepositAmount = _minDepositAmount;
    withdrawBlock = _withdrawBlock;
    withdrawMode = _withdrawMode;

    if (_poolLimitPerUser > 0) {
      hasUserLimit = true;
      poolLimitPerUser = _poolLimitPerUser;
    }

    // Set the lastRewardBlock as the startBlock
    lastRewardBlock = startBlock;

    if (_admin != _msgSender()) {
      // Transfer ownership to the admin address who becomes owner of the contract
      transferOwnership(_admin);
    }
    enableLockToUser = true;
  }

  /**
   * @dev Throws if called by any account other than the owner or operator.
   */
  modifier onlyOperator() {
    require(_msgSender() == owner() || isOperator[_msgSender()], "Operator role");
    _;
  }

  /**
   * @dev Function to set a account as operator
   */
  function fSetOperator(address _pAccount, bool _pStatus) external onlyOwner {
    require(isOperator[_pAccount] != _pStatus, "Added");
    isOperator[_pAccount] = _pStatus;
  }

  /*
   * @notice Deposit staked tokens and collect reward tokens (if any)
   * @param _amount: amount to withdraw (in rewardToken)
   */
  function deposit(uint256 _amount) external nonReentrant {
    require(isFrozen() == false, "deposit is frozen");
    UserInfo storage user = userInfo[msg.sender];
    require(user.amount + _amount >= minDepositAmount, "User amount below minimum");

    if (hasUserLimit) {
      require(_amount.add(user.amount) <= poolLimitPerUser, "User amount above limit");
    }
    userDepositTimes[msg.sender] = block.timestamp;

    _updatePool();

    if (user.amount > 0) {
      userRewards[msg.sender] = userRewards[msg.sender].add(
        user.amount.mul(accTokenPerShare).div(_PRECISION_FACTOR).sub(user.rewardDebt)
      );
    } else {
      if (user.registered == false) {
        userList.push(msg.sender);
        user.registered = true;
        user.addr = address(msg.sender);
      }
    }

    if (_amount > 0) {
      // Check real amount to avoid taxed token
      uint256 previousBalance_ = stakedToken.balanceOf(address(this));
      stakedToken.safeTransferFrom(address(msg.sender), address(this), _amount);
      uint256 newBalance_ = stakedToken.balanceOf(address(this));
      uint256 addedAmount_ = newBalance_ - previousBalance_;

      user.amount = user.amount.add(addedAmount_);
      totalStakingTokens = totalStakingTokens.add(addedAmount_);
    }

    user.rewardDebt = user.amount.mul(accTokenPerShare).div(_PRECISION_FACTOR);

    emit Deposit(msg.sender, _amount);
  }

  /*
   * @notice Withdraw staked tokens and collect reward tokens
   * @param _amount: amount to withdraw (in rewardToken)
   */
  function withdraw(uint256 _amount) external nonReentrant {
    require(isFrozen() == false, "withdraw is frozen");
    bool isClaim = _amount == 0;
    if (withdrawMode == 0 || (withdrawMode == 1 && !isClaim) || (withdrawMode == 2 && isClaim)) {
      require(block.number >= withdrawBlock, "withdraw not available");
      if (enableLockToUser) {
        require(block.timestamp >= userDepositTimes[msg.sender] + lockDuration, "in lock time");
      }
    }

    UserInfo storage user = userInfo[msg.sender];
    require(user.amount >= _amount, "Amount to withdraw too high");

    _updatePool();

    userRewards[msg.sender] = userRewards[msg.sender].add(
      user.amount.mul(accTokenPerShare).div(_PRECISION_FACTOR).sub(user.rewardDebt)
    );
    uint256 pending = userRewards[msg.sender];
    if (pending > 0) {
      userRewards[msg.sender] = 0;
      _safeRewardTransfer(address(msg.sender), pending);
    }

    if (_amount > 0) {
      user.amount = user.amount.sub(_amount);
      stakedToken.safeTransfer(address(msg.sender), _amount);
      totalStakingTokens = totalStakingTokens.sub(_amount);
    }

    user.rewardDebt = user.amount.mul(accTokenPerShare).div(_PRECISION_FACTOR);

    emit Withdraw(msg.sender, _amount);
  }

  /*
   * @notice Withdraw staked tokens without caring about rewards rewards
   * @dev Needs to be for emergency.
   */
  function emergencyWithdraw() external nonReentrant {
    require(isFrozen() == false, "emergency withdraw is frozen");

    if (withdrawMode == 0 || withdrawMode == 1) {
      require(block.number >= withdrawBlock, "withdraw not available");
      if (enableLockToUser) {
        require(block.timestamp >= userDepositTimes[msg.sender] + lockDuration, "in lock time");
      }
    }

    UserInfo storage user = userInfo[msg.sender];
    uint256 amountToTransfer = user.amount;
    user.amount = 0;
    user.rewardDebt = 0;

    if (amountToTransfer > 0) {
      stakedToken.safeTransfer(address(msg.sender), amountToTransfer);
      totalStakingTokens = totalStakingTokens.sub(amountToTransfer);
    }

    emit EmergencyWithdraw(msg.sender, user.amount);
  }

  /*
   * @notice return length of user addresses
   */
  function getUserListLength() external view returns (uint) {
    return userList.length;
  }

  /*
   * @notice View function to get users.
   * @param _offset: offset for paging
   * @param _limit: limit for paging
   * @return get users, next offset and total users
   */
  function getUsersPaging(uint _offset, uint _limit)
    public
    view
    returns (
      UserInfo[] memory users,
      uint nextOffset,
      uint total
    )
  {
    uint totalUsers = userList.length;
    if (_limit == 0) {
      _limit = 1;
    }

    if (_limit > totalUsers - _offset) {
      _limit = totalUsers - _offset;
    }

    UserInfo[] memory values = new UserInfo[](_limit);
    for (uint i = 0; i < _limit; i++) {
      values[i] = userInfo[userList[_offset + i]];
    }

    return (values, _offset + _limit, totalUsers);
  }

  /*
   * @notice isFrozed returns if contract is frozen, user cannot call deposit, withdraw, emergencyWithdraw function
   */
  function isFrozen() public view returns (bool) {
    return block.number >= freezeStartBlock && block.number <= freezeEndBlock;
  }

  /*
   * @notice Stop rewards
   * @dev Only callable by owner. Needs to be for emergency.
   */
  function emergencyRewardWithdraw(uint256 _amount) external onlyOwner {
    totalRewardTokens = totalRewardTokens.sub(_amount);
    rewardToken.safeTransfer(address(msg.sender), _amount);
  }

  /**
   * @dev Emergency case withdraw tokens
   * @param _pTokenAddress token address
   * @param _pTo destination address
   * @param _pAmount token amount
   */
  function emergencyWithdrawAll(
    address _pTokenAddress,
    address _pTo,
    uint256 _pAmount
  ) external onlyOwner {
    IERC20Metadata(_pTokenAddress).safeTransfer(_pTo, _pAmount);
  }

  /*
   * @dev Update lock to user mode
   */
  function setEnableLockToUser(bool _enable) external onlyOwner {
    enableLockToUser = _enable;
  }

  /*
   * @dev Update lock duration
   */
  function setLockDuration(uint256 _duration) external onlyOwner {
    lockDuration = _duration;
  }

  /*
   * @dev Reset user lock time
   */
  function resetUserDepositTime(address _user, uint256 _freezeTime) external onlyOwner {
    userDepositTimes[_user] = _freezeTime;
  }

  /**
   * @notice It allows the admin to reward tokens
   * @param _amount: amount of tokens
   * @dev This function is only callable by admin.
   */
  function addRewardTokens(uint256 _amount) external onlyOwner {
    // Check real amount to avoid taxed token
    uint256 previousBalance_ = rewardToken.balanceOf(address(this));
    rewardToken.safeTransferFrom(address(msg.sender), address(this), _amount);
    uint256 newBalance_ = rewardToken.balanceOf(address(this));
    uint256 addedAmount_ = newBalance_ - previousBalance_;

    totalRewardTokens = totalRewardTokens.add(addedAmount_);
    emit AddRewardTokens(msg.sender, addedAmount_);
  }

  /**
   * @notice It allows the admin to recover wrong tokens sent to the contract
   * @param _tokenAddress: the address of the token to withdraw
   * @param _tokenAmount: the number of tokens to withdraw
   * @dev This function is only callable by admin.
   */
  function recoverWrongTokens(address _tokenAddress, uint256 _tokenAmount) external onlyOwner {
    require(_tokenAddress != address(stakedToken), "Cannot be staked token");
    require(_tokenAddress != address(rewardToken), "Cannot be reward token");

    IERC20Metadata(_tokenAddress).safeTransfer(address(msg.sender), _tokenAmount);

    emit AdminTokenRecovery(_tokenAddress, _tokenAmount);
  }

  /*
   * @notice Stop rewards
   * @dev Only callable by owner
   */
  function stopReward() external onlyOwner {
    bonusEndBlock = block.number;
  }

  /*
   * @notice Stop Freeze
   * @dev Only callable by owner
   */
  function stopFreeze() external onlyOwner {
    freezeStartBlock = 0;
    freezeEndBlock = 0;
  }

  /*
   * @notice Update pool limit per user
   * @dev Only callable by owner.
   * @param _hasUserLimit: whether the limit remains forced
   * @param _poolLimitPerUser: new pool limit per user
   */
  function updatePoolLimitPerUser(bool _hasUserLimit, uint256 _poolLimitPerUser) external onlyOwner {
    require(hasUserLimit, "Must be set");
    if (_hasUserLimit) {
      require(_poolLimitPerUser > poolLimitPerUser, "New limit must be higher");
      poolLimitPerUser = _poolLimitPerUser;
    } else {
      hasUserLimit = _hasUserLimit;
      poolLimitPerUser = 0;
    }
    emit NewPoolLimit(poolLimitPerUser);
  }

  /*
   * @notice Update reward per block
   * @dev Only callable by owner.
   * @param _rewardPerBlock: the reward per block
   */
  function updateRewardPerBlock(uint256 _rewardPerBlock) external onlyOwner {
    _updatePool();
    rewardPerBlock = _rewardPerBlock;
    emit NewRewardPerBlock(_rewardPerBlock);
  }

  /**
   * @notice It allows the admin to update start and end blocks
   * @dev This function is only callable by owner.
   * @param _startBlock: the new start block
   * @param _bonusEndBlock: the new end block
   */
  function updateStartAndEndBlocks(uint256 _startBlock, uint256 _bonusEndBlock) external onlyOwner {
    require(block.number > bonusEndBlock, "Pool has started");
    require(_startBlock < _bonusEndBlock, "Invalid start and end block");
    bonusEndBlock = _bonusEndBlock;

    if (_startBlock > block.number) {
      startBlock = _startBlock;
      // Set the lastRewardBlock as the startBlock
      lastRewardBlock = startBlock;
    }
    emit NewStartAndEndBlocks(_startBlock, _bonusEndBlock);
  }

  /**
   * @notice It allows the admin to update freeze start and end blocks
   * @dev This function is only callable by owner.
   * @param _freezeStartBlock: the new freeze start block
   * @param _freezeEndBlock: the new freeze end block
   */
  function updateFreezaBlocks(uint256 _freezeStartBlock, uint256 _freezeEndBlock) external onlyOperator {
    require(_freezeStartBlock < _freezeEndBlock, "Invalid start and end block");
    require(block.number < _freezeStartBlock, "Invalid start and current");

    freezeStartBlock = _freezeStartBlock;
    freezeEndBlock = _freezeEndBlock;
    emit NewFreezeBlocks(freezeStartBlock, freezeEndBlock);
  }

  /**
   * @notice Update minimum deposit amount
   * @dev This function is only callable by owner.
   * @param _minDepositAmount: the new minimum deposit amount
   */
  function updateMinDepositAmount(uint256 _minDepositAmount) external onlyOwner {
    minDepositAmount = _minDepositAmount;
  }

  /**
   * @dev Update withdraw config
   * @param _block: block for withdraw
   * @param _mode: withdraw mode
   * 0: Apply withdrawBlock to both (stake + reward)
   * 1: Apply withdrawBlock to stake
   * 2: Apply withdrawBlock to reward
   */
  function updateWithdrawConfig(uint256 _block, uint256 _mode) external onlyOwner {
    withdrawBlock = _block;
    withdrawMode = _mode;
  }

  /*
   * @notice View function to see pending reward on frontend.
   * @param _user: user address
   * @return Pending reward for a given user
   */
  function pendingReward(address _user) external view returns (uint256) {
    UserInfo storage user = userInfo[_user];
    uint256 stakedTokenSupply = totalStakingTokens;
    if (block.number > lastRewardBlock && stakedTokenSupply != 0) {
      uint256 multiplier = _getMultiplier(lastRewardBlock, block.number);
      uint256 tokenReward = multiplier.mul(rewardPerBlock);
      uint256 adjustedTokenPerShare = accTokenPerShare.add(tokenReward.mul(_PRECISION_FACTOR).div(stakedTokenSupply));
      return userRewards[_user].add(user.amount.mul(adjustedTokenPerShare).div(_PRECISION_FACTOR).sub(user.rewardDebt));
    } else {
      return userRewards[_user].add(user.amount.mul(accTokenPerShare).div(_PRECISION_FACTOR).sub(user.rewardDebt));
    }
  }

  /*
   * @notice View function to see the current staked value
   * @param _user: user address
   * @return Staked value
   */
  function userStakedValue(address account) external view returns (uint256) {
    return userInfo[account].amount;
  }

  /*
   * @notice Update reward variables of the given pool to be up-to-date.
   */
  function _updatePool() internal {
    if (block.number <= lastRewardBlock) {
      return;
    }

    uint256 stakedTokenSupply = totalStakingTokens;

    if (stakedTokenSupply == 0) {
      lastRewardBlock = block.number;
      return;
    }

    uint256 multiplier = _getMultiplier(lastRewardBlock, block.number);
    uint256 tokenReward = multiplier.mul(rewardPerBlock);
    accTokenPerShare = accTokenPerShare.add(tokenReward.mul(_PRECISION_FACTOR).div(stakedTokenSupply));
    lastRewardBlock = block.number;
  }

  /*
   * @notice Return reward multiplier over the given _from to _to block.
   * @param _from: block to start
   * @param _to: block to finish
   */
  function _getMultiplier(uint256 _from, uint256 _to) internal view returns (uint256) {
    if (_to <= bonusEndBlock) {
      return _to.sub(_from);
    } else if (_from >= bonusEndBlock) {
      return 0;
    } else {
      return bonusEndBlock.sub(_from);
    }
  }

  /*
   * @notice transfer reward tokens.
   * @param _to: address where tokens will transfer
   * @param _amount: amount of tokens
   */
  function _safeRewardTransfer(address _to, uint256 _amount) internal {
    uint256 rewardTokenBal = totalRewardTokens;
    if (_amount > rewardTokenBal) {
      totalRewardTokens = totalRewardTokens.sub(rewardTokenBal);
      rewardToken.safeTransfer(_to, rewardTokenBal);
    } else {
      totalRewardTokens = totalRewardTokens.sub(_amount);
      rewardToken.safeTransfer(_to, _amount);
    }
  }
}