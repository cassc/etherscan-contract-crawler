// contracts/CawName.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IERC20.sol";
import "./libraries/TransferHelper.sol";
import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";
import "../node_modules/@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title RewardStaked
/// @notice A contract that allows users to stake a specific ERC20 token and earn rewards in other ERC20 tokens.
contract RewardStaked is 
  Context, Ownable,
  ReentrancyGuard
{

  IERC20 public immutable Stakeable;
  address[] public rewardTokens;

  uint256 public totalStaked;
  mapping(address => uint256) public deposits;
  mapping(address => uint256) public lockedUntil;
  mapping(address => mapping(address => uint256)) public nullifiedRewards;


  mapping(address => uint256) public rewardsPerDeposit;
  mapping(address => uint256) public totalRewarded;

  uint256 public precision = 10 ** 8;
  uint256 public lockTime;

  /// @notice Initializes the contract with the stakeable token, lock time, and initial reward tokens.
  /// @param _stakeable The token that users can stake.
  /// @param _lockTime The time that users must wait after unlocking their stake before they can withdraw it.
  /// @param _rewardTokens An array of tokens that users can earn as rewards.
  constructor(address _stakeable, uint256 _lockTime, address[] memory _rewardTokens) {
    Stakeable = IERC20(_stakeable);
    lockTime = _lockTime;

    for (uint16 i=0; i < _rewardTokens.length; i++)
      addRewardToken(_rewardTokens[i]);
  }

  /// @notice Returns the array of reward tokens.
  function getRewardTokens() public virtual view returns (address[] memory) {
    return rewardTokens;
  }

  /// @notice Allows a user to deposit the stakeable token.
  /// @param amount The amount of the stakeable token to deposit.
  function deposit(uint256 amount) external nonReentrant {
    require(!unlockInitiated(msg.sender), "you must wait until you withdraw your tokens");

    TransferHelper.safeTransferFrom(address(Stakeable), msg.sender, address(this), amount);

    // Claims all rewards before updating the user's stake.
    claimAll(getRewardTokens());

    deposits[msg.sender] += amount;
    totalStaked += amount;
  }

  /// @notice Allows a user to unlock their stake.
  function unlock() external nonReentrant {
    require(!unlockInitiated(msg.sender), "Unlock is already pending");

    // Claims all rewards before updating the user's stake.
    claimAll(getRewardTokens());

    totalStaked -= deposits[msg.sender];
    lockedUntil[msg.sender] = block.timestamp + lockTime;
  }

  /// @notice Allows a user to withdraw their stake after it has been unlocked.
  function withdraw() external nonReentrant {
    require(unlockInitiated(msg.sender), "you must unlock your staked tokens first");
    require(isUnlocked(msg.sender), "your staked tokens are still locked");

    uint256 withdrawable = deposits[msg.sender];
    deposits[msg.sender] = 0;

    TransferHelper.safeTransfer(address(Stakeable), msg.sender, withdrawable);
    lockedUntil[msg.sender] = 0;
  }

  /// @notice Nullifies the user's claimable rewards for the given token.
  /// @param token The token for which to nullify the user's rewards.
  function nullifyRewardsForToken(address token) internal {
    nullifiedRewards[token][msg.sender] = rewardsPerDeposit[token];
  }

  /// @notice Allows anyone to add rewards for all stakers.
  /// @param token The token in which the rewards are being added.
  /// @param amount The amount of rewards to add.
  function addRewards(address token, uint256 amount) external {
    require(totalStaked > 0, "can not add rewards if there are no stakers");

    TransferHelper.safeTransferFrom(token, msg.sender, address(this), amount);
    rewardsPerDeposit[token] += precision * amount / totalStaked;
    totalRewarded[token] += amount;
  }

  /// @notice Returns various information about the current state of the contract and the user's stake.
  /// @param user The user to retrieve information for.
  function getInfo(address user) external view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
    return (
      totalStaked,
      deposits[user],
      lockedUntil[user],
      Stakeable.decimals(),
      Stakeable.balanceOf(user),
      Stakeable.allowance(user, address(this))
    );
  }

  /// @notice Returns various information about all of the reward tokens and the user's claimable rewards.
  /// @param user The user to retrieve information for.
  function allClaimable(address user) external view returns (address[] memory, string[] memory, uint256[] memory, uint256[] memory, uint256[] memory) {
    address[] memory tokens = getRewardTokens();
    uint256[] memory totalRewards = new uint256[](tokens.length);
    uint256[] memory canClaim = new uint256[](tokens.length);
    uint256[] memory decimals = new uint256[](tokens.length);
    string[] memory symbols = new string[](tokens.length);

    for (uint16 i=0; i < tokens.length; i++) {
      IERC20 token = IERC20(tokens[i]);

      symbols[i] = token.symbol();
      decimals[i] = token.decimals();
      canClaim[i] = claimable(tokens[i], user);
      totalRewards[i] = totalRewarded[tokens[i]];
    }

    return (tokens, symbols, decimals, canClaim, totalRewards);
  }

  /// @notice Returns the amount of the given token that the user can claim as rewards.
  /// @param token The token to check.
  /// @param user The user to check.
  function claimable(address token, address user) public view returns (uint256){
    if (unlockInitiated(user)) return 0;

    return deposits[user] * (rewardsPerDeposit[token] - nullifiedRewards[token][user]) / precision;
  }

  /// @notice Allows the user to claim their rewards in the given token.
  /// @param token The token to claim rewards in.
  function claim(address token) internal {
    uint256 willClaim = claimable(token, msg.sender);
    nullifyRewardsForToken(token);

    if (willClaim > 0)
      IERC20(token).transfer(msg.sender, willClaim);
  }

  /// @notice Allows the user to claim their rewards in all tokens.
  /// @param rewards An array of tokens to claim rewards in.
  function claimAll(address[] memory rewards) public {
    for (uint16 i=0; i < rewards.length; i++)
      claim(rewards[i]);
  }

  /// @notice Returns whether the user has initiated an unlock.
  /// @param user The user to check.
  function unlockInitiated(address user) public view returns (bool) {
    return lockedUntil[user] > 0;
  }

  /// @notice Returns whether the user's stake is currently locked.
  /// @param user The user to check.
  function isUnlocked(address user) public view returns (bool) {
    return unlockInitiated(user) && lockedUntil[user] < block.timestamp;
  }

  /// @notice Removes a reward token.
  /// @param index The index of the token to remove.
  function removeRewardToken(uint16 index) public onlyOwner {
    require(rewardTokens.length > index, "invalid index");

    address lastToken = rewardTokens[rewardTokens.length - 1];
    rewardTokens.pop();

    if (rewardTokens.length > index)
      rewardTokens[index] = lastToken;
  }

  /// @notice Adds a new reward token.
  /// @param token The token to add.
  function addRewardToken(address token) public onlyOwner {
    for (uint16 i=0; i < rewardTokens.length; i++)
      require(rewardTokens[i] != token, "this token is already a reward token");

    rewardTokens.push(token);
  }

}