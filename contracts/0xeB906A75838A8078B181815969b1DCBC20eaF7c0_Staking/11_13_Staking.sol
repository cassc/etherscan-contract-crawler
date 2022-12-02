/// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.8.15

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "../interfaces/IStaking.sol";
import "../interfaces/IRewardsEscrow.sol";

// https://docs.synthetix.io/contracts/source/contracts/stakingrewards
contract Staking is IStaking, Ownable, ReentrancyGuard, Pausable, ERC20 {
  using SafeERC20 for IERC20;

  /* ========== STATE VARIABLES ========== */

  IERC20 public rewardsToken;
  IERC20 public stakingToken;

  IRewardsEscrow public rewardsEscrow;
  uint256 public periodFinish = 0;
  uint256 public rewardRate = 0;
  uint256 public rewardsDuration = 7 days;
  uint256 public lastUpdateTime;
  uint256 public rewardPerTokenStored;

  // duration in seconds for rewards to be held in escrow
  uint256 public escrowDuration;

  mapping(address => uint256) public userRewardPerTokenPaid;
  mapping(address => uint256) public rewards;
  mapping(address => bool) public rewardDistributors;

  /* ========== CONSTRUCTOR ========== */

  constructor(
    IERC20 _rewardsToken,
    IERC20 _stakingToken,
    IRewardsEscrow _rewardsEscrow
  )
    ERC20(
      string(abi.encodePacked("Popcorn - ", IERC20Metadata(address(_stakingToken)).name(), " Staking")),
      string(abi.encodePacked("pop-st-", IERC20Metadata(address(_stakingToken)).symbol()))
    )
  {
    rewardsToken = _rewardsToken;
    stakingToken = _stakingToken;
    rewardsEscrow = _rewardsEscrow;

    rewardDistributors[msg.sender] = true;
    escrowDuration = 365 days;
    _rewardsToken.safeIncreaseAllowance(address(_rewardsEscrow), type(uint256).max);
  }

  /* ========== VIEWS ========== */

  function lastTimeRewardApplicable() public view override returns (uint256) {
    return block.timestamp < periodFinish ? block.timestamp : periodFinish;
  }

  function rewardPerToken() public view override returns (uint256) {
    if (totalSupply() == 0) {
      return rewardPerTokenStored;
    }
    return rewardPerTokenStored + (((lastTimeRewardApplicable() - lastUpdateTime) * rewardRate * 1e18) / totalSupply());
  }

  function earned(address account) public view override returns (uint256) {
    return (balanceOf(account) * (rewardPerToken() - userRewardPerTokenPaid[account])) / 1e18 + rewards[account];
  }

  function getRewardForDuration() external view override returns (uint256) {
    return rewardRate * rewardsDuration;
  }

  function balanceOf(address account) public view override(IStaking, ERC20) returns (uint256) {
    return super.balanceOf(account);
  }

  function paused() public view override(IStaking, Pausable) returns (bool) {
    return super.paused();
  }

  /* ========== MUTATIVE FUNCTIONS ========== */

  function stakeFor(uint256 amount, address account) external {
    // QUESTION: Do we want to check allowances to stakeFor as with withdrawFor?
    // require(allowance(account, msg.sender) <= amount, "not approved to stake amount");
    _stake(amount, account);
  }

  function stake(uint256 amount) external override {
    _stake(amount, msg.sender);
  }

  function _stake(uint256 amount, address account) internal nonReentrant whenNotPaused updateReward(account) {
    require(amount > 0, "Cannot stake 0");
    _mint(account, amount);
    stakingToken.safeTransferFrom(msg.sender, address(this), amount);
    emit Staked(account, amount);
  }

  function withdrawFor(
    uint256 amount,
    address owner,
    address receiver
  ) external {
    _approve(owner, msg.sender, allowance(owner, msg.sender) - amount);
    _withdraw(amount, owner, receiver);
  }

  function withdraw(uint256 amount) external override {
    _withdraw(amount, msg.sender, msg.sender);
  }

  function _withdraw(
    uint256 amount,
    address owner,
    address receiver
  ) internal nonReentrant whenNotPaused updateReward(owner) {
    require(amount > 0, "Cannot withdraw 0");
    if (owner != receiver) _updateReward(receiver);

    _burn(owner, amount);
    stakingToken.safeTransfer(receiver, amount);
    emit Withdrawn(owner, amount);
  }

  function getReward() public override nonReentrant updateReward(msg.sender) {
    uint256 reward = rewards[msg.sender];
    if (reward > 0) {
      rewards[msg.sender] = 0;
      uint256 payout = reward / uint256(10);
      uint256 escrowed = payout * uint256(9);

      rewardsToken.safeTransfer(msg.sender, payout);
      rewardsEscrow.lock(msg.sender, escrowed, escrowDuration);
      emit RewardPaid(msg.sender, reward);
    }
  }

  function exit() external override {
    _withdraw(balanceOf(msg.sender), msg.sender, msg.sender);
    getReward();
  }

  /* ========== RESTRICTED FUNCTIONS ========== */

  function setEscrowDuration(uint256 duration) external onlyOwner {
    emit EscrowDurationUpdated(escrowDuration, duration);
    escrowDuration = duration;
  }

  function notifyRewardAmount(uint256 reward) external override updateReward(address(0)) {
    require(rewardDistributors[msg.sender], "not authorized");

    if (block.timestamp >= periodFinish) {
      rewardRate = reward / rewardsDuration;
    } else {
      uint256 remaining = periodFinish - block.timestamp;
      uint256 leftover = remaining * rewardRate;
      rewardRate = (reward + leftover) / rewardsDuration;
    }

    // handle the transfer of reward tokens via `transferFrom` to reduce the number
    // of transactions required and ensure correctness of the reward amount
    IERC20(rewardsToken).safeTransferFrom(msg.sender, address(this), reward);

    // Ensure the provided reward amount is not more than the balance in the contract.
    // This keeps the reward rate in the right range, preventing overflows due to
    // very high values of rewardRate in the earned and rewardsPerToken functions;
    // Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.
    uint256 balance = rewardsToken.balanceOf(address(this));
    require(rewardRate <= balance / rewardsDuration, "Provided reward too high");

    lastUpdateTime = block.timestamp;
    periodFinish = block.timestamp + rewardsDuration;

    emit RewardAdded(reward);
  }

  // Modify approval for an address to call notifyRewardAmount
  function approveRewardDistributor(address _distributor, bool _approved) external onlyOwner {
    emit RewardDistributorUpdated(_distributor, _approved);
    rewardDistributors[_distributor] = _approved;
  }

  // Added to support recovering LP Rewards from other systems such as BAL to be distributed to holders
  function recoverERC20(address tokenAddress, uint256 tokenAmount) external onlyOwner {
    require(tokenAddress != address(stakingToken), "Cannot withdraw the staking token");
    require(tokenAddress != address(rewardsToken), "Cannot withdraw the rewards token");
    IERC20(tokenAddress).safeTransfer(owner(), tokenAmount);
    emit Recovered(tokenAddress, tokenAmount);
  }

  function setRewardsDuration(uint256 _rewardsDuration) external onlyOwner {
    require(
      block.timestamp > periodFinish,
      "Previous rewards period must be complete before changing the duration for the new period"
    );
    rewardsDuration = _rewardsDuration;
    emit RewardsDurationUpdated(rewardsDuration);
  }

  function setRewardsEscrow(address _rewardsEscrow) external onlyOwner {
    emit RewardsEscrowUpdated(address(rewardsEscrow), _rewardsEscrow);
    rewardsEscrow = IRewardsEscrow(_rewardsEscrow);
  }

  /**
   * @notice Pause deposits. Caller must have VAULTS_CONTROLLER from ACLRegistry.
   */
  function pauseContract() external onlyOwner {
    _pause();
  }

  /**
   * @notice Unpause deposits. Caller must have VAULTS_CONTROLLER from ACLRegistry.
   */
  function unpauseContract() external onlyOwner {
    _unpause();
  }

  /* ========== ERC20 OVERRIDE ========== */

  error nonTransferable();

  function _transfer(
    address, /* from */
    address, /* to */
    uint256 /* amount */
  ) internal pure override(ERC20) {
    revert nonTransferable();
  }

  /* ========== MODIFIERS ========== */

  modifier updateReward(address account) {
    _updateReward(account);
    _;
  }

  function _updateReward(address account) internal {
    rewardPerTokenStored = rewardPerToken();
    lastUpdateTime = lastTimeRewardApplicable();
    if (account != address(0)) {
      rewards[account] = earned(account);
      userRewardPerTokenPaid[account] = rewardPerTokenStored;
    }
  }

  /* ========== EVENTS ========== */

  event RewardsEscrowUpdated(address _previous, address _new);
  event Recovered(address token, uint256 amount);
}