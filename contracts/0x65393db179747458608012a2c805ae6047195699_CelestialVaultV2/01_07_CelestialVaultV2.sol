// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";



/// @title Celestial Vault
contract CelestialVaultV2 is Ownable, Pausable {
  using EnumerableSet for EnumerableSet.UintSet;

  /* -------------------------------------------------------------------------- */
  /*                                Farming State                               */
  /* -------------------------------------------------------------------------- */

  /// @notice Rewards emitted per day staked.
  uint256 public rate;

  /// @notice Rewards of token 2 emitted per day staked.
  uint256 public rate2;

  /// @notice Endtime of token rewards.
  uint256 public endTime;

  /// @notice Endtime of token 2 rewards.
  uint256 public endTime2;

  /// @notice Staking token contract address.
  ICKEY public stakingToken;

  /// @notice Rewards token contract address.
  IFBX public rewardToken;

  /// @notice WRLD token contract address.
  IWRLD public rewardToken2;

  /// @notice Set of staked token ids by address.
  mapping(address => EnumerableSet.UintSet) internal _depositedIds;

  /// @notice Mapping of timestamps from each staked token id.
  // mapping(address => mapping(uint256 => uint256)) internal _depositedBlocks;
  mapping(address => mapping(uint256 => uint256)) public _depositedBlocks;

  /// @notice Mapping of tokenIds to their rate modifier
  mapping(uint256 => uint256) public _rateModifiers;

  bool public emergencyWithdrawEnabled;

  constructor(
    address newStakingToken,
    address newRewardToken,
    address newRewardToken2,
    uint256 newRate,
    uint256 newRate2
  ) {
    stakingToken = ICKEY(newStakingToken);
    rewardToken = IFBX(newRewardToken);
    rewardToken2 = IWRLD(newRewardToken2);
    rate = newRate;
    rate2 = newRate2;
    _pause();
  }

  /* -------------------------------------------------------------------------- */
  /*                                Farming Logic                               */
  /* -------------------------------------------------------------------------- */

  /// @notice Deposit tokens into the vault.
  /// @param tokenIds Array of token tokenIds to be deposited.
  function deposit(uint256[] memory tokenIds) external whenNotPaused {
    for (uint256 i = 0; i < tokenIds.length; i++) {
      // Add the new deposit to the mapping
      _depositedIds[msg.sender].add(tokenIds[i]);
      _depositedBlocks[msg.sender][tokenIds[i]] = block.timestamp;

      // Transfer the deposited token to this contract
      stakingToken.transferFrom(msg.sender, address(this), tokenIds[i]);
    }
  }

  /// @notice Withdraw tokens and claim their pending rewards.
  /// @param tokenIds Array of staked token ids.
  function withdraw(uint256[] memory tokenIds) external whenNotPaused {
    uint256 totalRewards;
    uint256 totalRewards2;
    for (uint256 i = 0; i < tokenIds.length; i++) {
      require(_depositedIds[msg.sender].contains(tokenIds[i]), "Query for a token you don't own");
      totalRewards += _earned(_depositedBlocks[msg.sender][tokenIds[i]]);
      totalRewards2 += _earned2(_depositedBlocks[msg.sender][tokenIds[i]], tokenIds[i]);

      _depositedIds[msg.sender].remove(tokenIds[i]);
      delete _depositedBlocks[msg.sender][tokenIds[i]];

      stakingToken.safeTransferFrom(address(this), msg.sender, tokenIds[i]);
    }
    rewardToken.mint(msg.sender, totalRewards);
    rewardToken2.transfer(msg.sender, totalRewards2);
  }

  /// @notice Claim pending token rewards.
  function claim() external whenNotPaused {
    uint256 totalRewards;
    uint256 totalRewards2;
    for (uint256 i = 0; i < _depositedIds[msg.sender].length(); i++) {
      // Mint the new tokens and update last checkpoint
      uint256 tokenId = _depositedIds[msg.sender].at(i);
      totalRewards += _earned(_depositedBlocks[msg.sender][tokenId]);
      totalRewards2 += _earned2(_depositedBlocks[msg.sender][tokenId], tokenId);
      _depositedBlocks[msg.sender][tokenId] = block.timestamp;
    }
    rewardToken.mint(msg.sender, totalRewards);
    rewardToken2.transfer(msg.sender, totalRewards2);
  }

  /// @notice Calculate total rewards for given account.
  /// @param account Holder address.
  function earned(address account) external view returns (uint256[] memory) {
    uint256 length = _depositedIds[account].length();
    uint256[] memory rewards = new uint256[](length);

    for (uint256 i = 0; i < length; i++) {
      uint256 tokenId = _depositedIds[account].at(i);
      rewards[i] = _earned(_depositedBlocks[account][tokenId]);
    }
    return rewards;
  }

  /// @notice Calculate total WRLD token rewards for given account.
  /// @param account Holder address.
  function earned2(address account) external view returns (uint256[] memory) {
    uint256 length = _depositedIds[account].length();
    uint256[] memory rewards = new uint256[](length);

    for (uint256 i = 0; i < length; i++) {
      uint256 tokenId = _depositedIds[account].at(i);
      rewards[i] = _earned2(_depositedBlocks[account][tokenId], tokenId);
    }
    return rewards;
  }

  /// @notice Internally calculates rewards for given token.
  /// @param timestamp Deposit timestamp.
  function _earned(uint256 timestamp) internal view returns (uint256) {
    if (timestamp == 0) return 0;
    uint256 end;
    if (endTime == 0){ // endtime not set
      end = block.timestamp;
    }else{
      end = Math.min(block.timestamp, endTime);
    }
    if(timestamp > end){
      return 0;
    }
    return ((end - timestamp) * rate) / 1 days;
  }

  /// @notice Internally calculates WRLD rewards for given token.
  /// @param timestamp Deposit timestamp.
  function _earned2(uint256 timestamp, uint256 tokenId) internal view returns (uint256) {
    if (timestamp == 0) return 0;
    uint256 rateForTokenId = rate2 + _rateModifiers[tokenId];
    uint256 end;
    if (endTime2 == 0){ // endtime not set
      end = block.timestamp;
    }else{
      end = Math.min(block.timestamp, endTime2);
    }
    if(timestamp > end){
      return 0;
    }
    return ((end - timestamp) * rateForTokenId) / 1 days;
  }

  /// @notice Retrieve token ids deposited by account.
  /// @param account Token owner address.
  function depositsOf(address account) external view returns (uint256[] memory) {
    uint256 length = _depositedIds[account].length();
    uint256[] memory ids = new uint256[](length);

    for (uint256 i = 0; i < length; i++) ids[i] = _depositedIds[account].at(i);
    return ids;
  }

  function emergencyWithdraw(uint256[] memory tokenIds) external whenNotPaused{
    require(emergencyWithdrawEnabled, "Emergency withdraw not enabled");
    for(uint256 i = 0; i < tokenIds.length; i++){
      require(_depositedIds[msg.sender].contains(tokenIds[i]), "Query for a token you don't own");
      _depositedIds[msg.sender].remove(tokenIds[i]);
      delete _depositedBlocks[msg.sender][tokenIds[i]];
      stakingToken.safeTransferFrom(address(this), msg.sender, tokenIds[i]);
    }
  }

  /* -------------------------------------------------------------------------- */
  /*                                 Owner Logic                                */
  /* -------------------------------------------------------------------------- */

  /// @notice Set the new token rewards rate.
  /// @param newRate Emission rate in wei.
  function setRate(uint256 newRate) external onlyOwner {
    rate = newRate;
  }

  /// @notice Set the new token rewards rate.
  /// @param newRate2 Emission rate in wei.
  function setRate2(uint256 newRate2) external onlyOwner {
    rate2 = newRate2;
  }

  /// @notice Set the new token rewards end time.
  /// @param newEndTime End time of token 1 yield
  function setEndTime(uint256 newEndTime) external onlyOwner {
    endTime = newEndTime;
  }

  /// @notice Set the new token rewards end time.
  /// @param newEndTime2 End time of token 2 yield
  function setEndTime2(uint256 newEndTime2) external onlyOwner {
    endTime2 = newEndTime2;
  }

  /// @notice set rate modifier for given token Ids.
  /// @param tokenIds token Ids to set rate modifier for.
  /// @param rateModifier value of rate modifier
  function setRateModifier(uint256[] memory tokenIds, uint256 rateModifier) external onlyOwner {
    for (uint256 i = 0; i < tokenIds.length; i++) {
      _rateModifiers[tokenIds[i]] = rateModifier;
    }
  }

  /// @notice Set the new staking token contract address.
  /// @param newStakingToken Staking token address.
  function setStakingToken(address newStakingToken) external onlyOwner {
    stakingToken = ICKEY(newStakingToken);
  }

  /// @notice Set the new reward token contract address.
  /// @param newRewardToken Rewards token address.
  function setRewardToken(address newRewardToken) external onlyOwner {
    rewardToken = IFBX(newRewardToken);
  }

  /// @notice Set the new reward token contract address.
  /// @param newRewardToken2 Rewards token address.
  function setRewardToken2(address newRewardToken2) external onlyOwner {
    rewardToken2 = IWRLD(newRewardToken2);
  }

  /// @notice Pause the contract.
  function pause() external onlyOwner {
    _pause();
  }

  /// @notice Unpause the contract.
  function unpause() external onlyOwner {
    _unpause();
  }

  /// @notice Withdraw `amount` of `token` to the sender.
  function withdrawERC20(IERC20 token, uint256 amount) external onlyOwner {
    token.transfer(msg.sender, amount);
  }

  /// @notice enable emergency withdraw
  function setEmergencyWithdrawEnabled(bool newEmergencyWithdrawEnabled) external onlyOwner{
    emergencyWithdrawEnabled  = newEmergencyWithdrawEnabled;
  }
}

interface ICKEY {
  function transferFrom(
    address from,
    address to,
    uint256 id
  ) external;

  function safeTransferFrom(
    address from,
    address to,
    uint256 id
  ) external;
}

interface IFBX {
  function mint(address to, uint256 amount) external;

  function burn(address from, uint256 amount) external;
}

interface IWRLD {
  function transfer(address to, uint256 amount) external;
}