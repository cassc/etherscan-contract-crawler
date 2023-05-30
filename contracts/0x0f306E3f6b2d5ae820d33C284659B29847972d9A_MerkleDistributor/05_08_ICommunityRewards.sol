// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC721/IERC721.sol";

import "../interfaces/IERC20withDec.sol";

interface ICommunityRewards is IERC721 {
  function rewardsToken() external view returns (IERC20withDec);

  function claimableRewards(uint256 tokenId) external view returns (uint256 rewards);

  function totalVestedAt(
    uint256 start,
    uint256 end,
    uint256 granted,
    uint256 cliffLength,
    uint256 vestingInterval,
    uint256 revokedAt,
    uint256 time
  ) external pure returns (uint256 rewards);

  function grant(
    address recipient,
    uint256 amount,
    uint256 vestingLength,
    uint256 cliffLength,
    uint256 vestingInterval
  ) external returns (uint256 tokenId);

  function loadRewards(uint256 rewards) external;

  function revokeGrant(uint256 tokenId) external;

  function getReward(uint256 tokenId) external;

  event RewardAdded(uint256 reward);
  event Granted(
    address indexed user,
    uint256 indexed tokenId,
    uint256 amount,
    uint256 vestingLength,
    uint256 cliffLength,
    uint256 vestingInterval
  );
  event GrantRevoked(uint256 indexed tokenId, uint256 totalUnvested);
  event RewardPaid(address indexed user, uint256 indexed tokenId, uint256 reward);
}