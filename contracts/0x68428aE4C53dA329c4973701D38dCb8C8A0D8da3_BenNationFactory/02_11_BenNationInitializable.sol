// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Ownable} from "./oz/access/Ownable.sol";
import {ReentrancyGuard} from "./oz/security/ReentrancyGuard.sol";
import {IERC20Metadata} from "./oz/token/ERC20/extensions/IERC20Metadata.sol";
import {SafeERC20} from "./oz/token/ERC20/utils/SafeERC20.sol";

import {BenNationVault} from "./BenNationVault.sol";

contract BenNationInitializable is Ownable, ReentrancyGuard {
  using SafeERC20 for IERC20Metadata;

  // The address of the smart chef factory
  address public immutable BEN_NATION_FACTORY;

  // Whether a limit is set for users
  bool public userLimit;

  // Whether it is initialized
  bool public isInitialized;

  // Accrued token per share
  uint256 public accTokenPerShare;

  // The block number when reward mining ends.
  uint256 public endBlock;

  // The block number when reward mining starts.
  uint256 public startBlock;

  // The block number of the last pool update
  uint256 public lastRewardBlock;

  // The pool limit (0 if none)
  uint256 public poolLimitPerUser;

  // Block numbers available for user limit (after start block)
  uint256 public numberBlocksForUserLimit;

  // Reward tokens created per block.
  uint256 public rewardPerBlock;

  // The precision factor
  uint256 public PRECISION_FACTOR;

  // The reward token
  IERC20Metadata public rewardToken;

  // The staked token
  IERC20Metadata public stakedToken;

  // The vault if rewardToken == stakedToken
  BenNationVault public vault;

  // Info of each user that stakes tokens (stakedToken)
  mapping(address => UserInfo) public userInfo;

  struct UserInfo {
    uint256 amount; // How many staked tokens the user has provided
    uint256 rewardDebt; // Reward debt
  }

  event Deposit(address indexed user, uint256 amount);
  event EmergencyWithdraw(address indexed user, uint256 amount);
  event NewStartAndEndBlocks(uint256 startBlock, uint256 endBlock);
  event NewRewardPerBlock(uint256 rewardPerBlock);
  event NewPoolLimit(uint256 poolLimitPerUser);
  event RewardsStop(uint256 blockNumber);
  event TokenRecovery(address indexed token, uint256 amount);
  event Withdraw(address indexed user, uint256 amount);

  error AmountToWithdrawTooHigh();
  error MustBeSet();
  error PoolHasStarted();
  error NotFactory();
  error MustBeInferiorTo30Decimals();
  error DepositLimitReached();
  error CannotRecoverStakedToken();
  error CannotRecoverRewardToken();
  error CannotRecoverZeroBalance();
  error NewLimitMustBeHigher();
  error AlreadyInitialized();
  error NewStartHigherThanEndBlock();
  error NewStartBlockLowerThanCurrentBlock();

  modifier onlyFactory() {
    if (msg.sender != BEN_NATION_FACTORY) {
      revert NotFactory();
    }
    _;
  }

  /**
   * @notice Constructor
   */
  constructor() {
    BEN_NATION_FACTORY = msg.sender;
  }

  /*
   * @notice Initialize the contract
   * @param _stakedToken: staked token address
   * @param _rewardToken: reward token address
   * @param _rewardPerBlock: reward per block (in rewardToken)
   * @param _startBlock: start block
   * @param _endBlock: end block
   * @param _poolLimitPerUser: pool limit per user in stakedToken (if any, else 0)
   * @param _numberBlocksForUserLimit: block numbers available for user limit (after start block)
   * @param _vault: vault address if rewardToken == stakedToken
   * @param _admin: admin address with ownership
   */
  function initialize(
    IERC20Metadata _stakedToken,
    IERC20Metadata _rewardToken,
    uint256 _rewardPerBlock,
    uint256 _startBlock,
    uint256 _endBlock,
    uint256 _poolLimitPerUser,
    uint256 _numberBlocksForUserLimit,
    address _vault,
    address _admin
  ) external onlyFactory {
    if (isInitialized) {
      revert AlreadyInitialized();
    }
    if (_stakedToken == _rewardToken && _vault == address(0)) {
      revert MustBeSet();
    }

    // Make this contract initialized
    isInitialized = true;

    stakedToken = _stakedToken;
    rewardToken = _rewardToken;
    rewardPerBlock = _rewardPerBlock;
    startBlock = _startBlock;
    endBlock = _endBlock;

    if (_poolLimitPerUser > 0) {
      userLimit = true;
      poolLimitPerUser = _poolLimitPerUser;
      numberBlocksForUserLimit = _numberBlocksForUserLimit;
    }

    uint256 decimalsRewardToken = uint256(rewardToken.decimals());
    if (decimalsRewardToken >= 30) {
      revert MustBeInferiorTo30Decimals();
    }

    PRECISION_FACTOR = uint256(10 ** (uint256(30) - decimalsRewardToken));

    // Set the lastRewardBlock as the startBlock
    lastRewardBlock = _startBlock;

    vault = BenNationVault(_vault);

    // Transfer ownership to the admin address who becomes owner of the contract
    transferOwnership(_admin);
  }

  /*
   * @notice Deposit staked tokens and collect reward tokens (if any)
   * @param _amount: amount to withdraw (in rewardToken)
   */
  function deposit(uint256 _amount) external nonReentrant {
    UserInfo storage user = userInfo[msg.sender];

    userLimit = hasUserLimit();

    if (userLimit && !((_amount + user.amount) <= poolLimitPerUser)) {
      revert DepositLimitReached();
    }

    _updatePool();

    if (user.amount > 0) {
      uint256 pending = (user.amount * accTokenPerShare) / PRECISION_FACTOR - user.rewardDebt;
      if (pending > 0) {
        _safeTransfer(pending);
      }
    }

    if (_amount > 0) {
      user.amount = user.amount + _amount;
      stakedToken.safeTransferFrom(msg.sender, address(this), _amount);
    }

    user.rewardDebt = (user.amount * accTokenPerShare) / PRECISION_FACTOR;

    emit Deposit(msg.sender, _amount);
  }

  /*
   * @notice Withdraw staked tokens and collect reward tokens
   * @param _amount: amount to withdraw (in rewardToken)
   */
  function withdraw(uint256 _amount) external nonReentrant {
    UserInfo storage user = userInfo[msg.sender];
    if (user.amount < _amount) {
      revert AmountToWithdrawTooHigh();
    }

    _updatePool();

    uint256 pending = (user.amount * accTokenPerShare) / PRECISION_FACTOR - user.rewardDebt;

    if (_amount > 0) {
      user.amount = user.amount - _amount;
      stakedToken.safeTransfer(msg.sender, _amount);
    }

    if (pending > 0) {
      _safeTransfer(pending);
    }

    user.rewardDebt = (user.amount * accTokenPerShare) / PRECISION_FACTOR;

    emit Withdraw(msg.sender, _amount);
  }

  /*
   * @notice Withdraw staked tokens without caring about rewards
   * @dev Needs to be for emergency.
   */
  function emergencyWithdraw() external nonReentrant {
    UserInfo storage user = userInfo[msg.sender];
    uint256 amountToTransfer = user.amount;
    user.amount = 0;
    user.rewardDebt = 0;

    if (amountToTransfer > 0) {
      stakedToken.safeTransfer(msg.sender, amountToTransfer);
    }

    emit EmergencyWithdraw(msg.sender, user.amount);
  }

  /*
   * @notice Stop rewards
   * @dev Only callable by owner. Needs to be for emergency.
   */
  function emergencyRewardWithdraw(uint256 _amount) external onlyOwner {
    _safeTransfer(_amount);
  }

  /**
   * @notice Allows the owner to recover tokens sent to the contract by mistake
   * @param _token: token address
   * @dev Callable by owner
   */
  function recoverToken(address _token) external onlyOwner {
    if (_token == address(stakedToken)) {
      revert CannotRecoverStakedToken();
    }
    if (_token == address(rewardToken)) {
      revert CannotRecoverRewardToken();
    }

    uint256 balance = IERC20Metadata(_token).balanceOf(address(this));
    if (balance == 0) {
      revert CannotRecoverZeroBalance();
    }

    IERC20Metadata(_token).safeTransfer(msg.sender, balance);

    emit TokenRecovery(_token, balance);
  }

  /*
   * @notice Stop rewards
   * @dev Only callable by owner
   */
  function stopReward() external onlyOwner {
    endBlock = block.number;
  }

  /*
   * @notice Update pool limit per user
   * @dev Only callable by owner.
   * @param _userLimit: whether the limit remains forced
   * @param _poolLimitPerUser: new pool limit per user
   */
  function updatePoolLimitPerUser(bool _userLimit, uint256 _poolLimitPerUser) external onlyOwner {
    if (!userLimit) {
      revert MustBeSet();
    }
    if (_userLimit) {
      if (_poolLimitPerUser <= poolLimitPerUser) {
        revert NewLimitMustBeHigher();
      }
      poolLimitPerUser = _poolLimitPerUser;
    } else {
      userLimit = _userLimit;
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
    if (block.number >= startBlock) {
      revert PoolHasStarted();
    }
    rewardPerBlock = _rewardPerBlock;
    emit NewRewardPerBlock(_rewardPerBlock);
  }

  /**
   * @notice It allows the admin to update start and end blocks
   * @dev This function is only callable by owner.
   * @param _startBlock: the new start block
   * @param _endBlock: the new end block
   */
  function updateStartAndEndBlocks(uint256 _startBlock, uint256 _endBlock) external onlyOwner {
    if (block.number >= startBlock) {
      revert PoolHasStarted();
    }
    if (_startBlock >= _endBlock) {
      revert NewStartHigherThanEndBlock();
    }
    if (block.number >= _startBlock) {
      revert NewStartBlockLowerThanCurrentBlock();
    }

    startBlock = _startBlock;
    endBlock = _endBlock;

    // Set the lastRewardBlock as the startBlock
    lastRewardBlock = startBlock;

    emit NewStartAndEndBlocks(_startBlock, _endBlock);
  }

  /*
   * @notice View function to see pending reward on frontend.
   * @param _user: user address
   * @return Pending reward for a given user
   */
  function pendingReward(address _user) external view returns (uint256) {
    UserInfo storage user = userInfo[_user];
    uint256 stakedTokenSupply = stakedToken.balanceOf(address(this));
    if (block.number > lastRewardBlock && stakedTokenSupply != 0) {
      uint256 multiplier = _getMultiplier(lastRewardBlock, block.number);
      uint256 reward = multiplier * rewardPerBlock;
      uint256 adjustedTokenPerShare = accTokenPerShare + (reward * PRECISION_FACTOR) / stakedTokenSupply;
      return (user.amount * adjustedTokenPerShare) / PRECISION_FACTOR - user.rewardDebt;
    } else {
      return (user.amount * accTokenPerShare) / PRECISION_FACTOR - user.rewardDebt;
    }
  }

  /*
   * @notice Update reward variables of the given pool to be up-to-date.
   */
  function _updatePool() internal {
    if (block.number <= lastRewardBlock) {
      return;
    }

    uint256 stakedTokenSupply = stakedToken.balanceOf(address(this));

    if (stakedTokenSupply == 0) {
      lastRewardBlock = block.number;
      return;
    }

    uint256 multiplier = _getMultiplier(lastRewardBlock, block.number);
    uint256 reward = multiplier * rewardPerBlock;
    accTokenPerShare = accTokenPerShare + (reward * PRECISION_FACTOR) / stakedTokenSupply;
    lastRewardBlock = block.number;
  }

  /*
   * @notice Transfer from this contract if it doesn't use a vault, otherwise transfer from vault
   */
  function _safeTransfer(uint256 _amount) internal {
    if (stakedToken == rewardToken) {
      vault.safeTransfer(rewardToken, msg.sender, _amount);
    } else {
      rewardToken.safeTransfer(msg.sender, _amount);
    }
  }

  /*
   * @notice Return reward multiplier over the given _from to _to block.
   * @param _from: block to start
   * @param _to: block to finish
   */
  function _getMultiplier(uint256 _from, uint256 _to) internal view returns (uint256) {
    if (_to <= endBlock) {
      return _to - _from;
    } else if (_from >= endBlock) {
      return 0;
    } else {
      return endBlock - _from;
    }
  }

  /*
   * @notice Return user limit is set or zero.
   */
  function hasUserLimit() public view returns (bool) {
    if (!userLimit || (block.number >= (startBlock + numberBlocksForUserLimit))) {
      return false;
    }

    return true;
  }
}