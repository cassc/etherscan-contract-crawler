// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Timezone, Calendar} from "./base/Calendar.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";

contract MoonMoonzRewarder is Initializable, Ownable, Pausable {
  using EnumerableSet for EnumerableSet.UintSet;

  /* -------------------------------------------------------------------------- */
  /*                                  Variables                                 */
  /* -------------------------------------------------------------------------- */

  IStakingToken public stakingToken;

  IRewardToken public rewardToken;

  mapping(address => EnumerableSet.UintSet) internal _depositedIds;

  mapping(uint256 => uint256) internal _depositedTimestamps;

  /* -------------------------------------------------------------------------- */
  /*                                 Constructor                                */
  /* -------------------------------------------------------------------------- */

  constructor(address _stakingToken, address _rewardToken) {
    stakingToken = IStakingToken(_stakingToken);
    rewardToken = IRewardToken(_rewardToken);
  }

  /* -------------------------------------------------------------------------- */
  /*                                   Rewards                                  */
  /* -------------------------------------------------------------------------- */

  function deposit(uint256[] calldata tokenIds) external whenNotPaused {
    for (uint256 i; i < tokenIds.length; i++) {
      // Add the new deposit to the mapping
      _depositedIds[msg.sender].add(tokenIds[i]);
      _depositedTimestamps[tokenIds[i]] = block.timestamp;

      // Transfer the deposited token to this contract
      stakingToken.transferFrom(msg.sender, address(this), tokenIds[i]);
    }
  }

  function withdraw(uint256[] calldata tokenIds) external whenNotPaused {
    uint256 totalRewards;
    for (uint256 i; i < tokenIds.length; i++) {
      require(_depositedIds[msg.sender].contains(tokenIds[i]), "Query for a token you don't own");
      Timezone timezone = stakingToken.timezoneOf(tokenIds[i]);
      require(timezone == Timezone.UNIVERSAL || Calendar.night(timezone), "Still day");

      totalRewards += _earned(_depositedTimestamps[tokenIds[i]], timezone);
      _depositedIds[msg.sender].remove(tokenIds[i]);
      delete _depositedTimestamps[tokenIds[i]];

      stakingToken.safeTransferFrom(address(this), msg.sender, tokenIds[i]);
    }

    rewardToken.mint(msg.sender, totalRewards);
  }

  function claim() external whenNotPaused {
    for (uint256 i; i < _depositedIds[msg.sender].length(); i++) {
      // Mint the new tokens and update last checkpoint
      uint256 tokenId = _depositedIds[msg.sender].at(i);

      Timezone timezone = stakingToken.timezoneOf(tokenId);
      require(timezone == Timezone.UNIVERSAL || Calendar.night(timezone), "Still day");

      rewardToken.mint(msg.sender, _earned(_depositedTimestamps[tokenId], timezone));

      _depositedTimestamps[tokenId] = block.timestamp;
    }
  }

  function earned(address account) external view returns (uint256[] memory rewards) {
    uint256 length = _depositedIds[account].length();
    rewards = new uint256[](length);

    for (uint256 i; i < length; i++) {
      uint256 tokenId = _depositedIds[account].at(i);
      rewards[i] = _earned(_depositedTimestamps[tokenId], stakingToken.timezoneOf(tokenId));
    }
  }

  function _earned(uint256 timestamp, Timezone timezone) internal view returns (uint256) {
    if (timestamp == 0) return 0;
    uint256 rewards = ((block.timestamp - timestamp) * rewardToken.rate()) / 1 days;
    return timezone == Timezone.UNIVERSAL ? rewards * 2 : rewards;
  }

  function depositsOf(address account) external view returns (uint256[] memory ids) {
    uint256 length = _depositedIds[account].length();
    ids = new uint256[](length);
    for (uint256 i; i < length; i++) ids[i] = _depositedIds[account].at(i);
  }

  /* -------------------------------------------------------------------------- */
  /*                                 Maintenance                                */
  /* -------------------------------------------------------------------------- */

  function setStakingToken(address newStakingToken) external onlyOwner {
    stakingToken = IStakingToken(newStakingToken);
  }

  function setRewardToken(address newRewardToken) external onlyOwner {
    rewardToken = IRewardToken(newRewardToken);
  }

  function setPaused() external onlyOwner {
    if (paused()) _unpause();
    else _pause();
  }
}

/* -------------------------------------------------------------------------- */
/*                                 Interfaces                                 */
/* -------------------------------------------------------------------------- */

interface IStakingToken {
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) external;

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) external;

  function timezoneOf(uint256 tokenId) external view returns (Timezone);
}

interface IRewardToken {
  function mint(address to, uint256 amount) external;

  function burn(address from, uint256 amount) external;

  function rate() external view returns (uint256);
}