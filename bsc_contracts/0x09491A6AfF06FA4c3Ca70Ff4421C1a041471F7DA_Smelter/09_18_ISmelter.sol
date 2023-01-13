//SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.17;

interface ISmelterEmitter {
  /// @dev burn erc721 to redeem erc20
  event Redeem(address indexed redeemer, uint256 indexed tokenId, uint256 indexed amount);
  /// @dev set max token id
  event MaxTokenIdSet(uint256 newMaxTokenId);
  /// @dev set reward amount
  event rewardAmountSet(uint256);

  /// @dev limit nft transfer to specific function
  error InvalidTransfer();
  /// @dev invalid tokenId to get reward
  error InvalidRewardTokenId();
}

interface ISmelter is ISmelterEmitter {
  function cast(uint256 tokenId) external;

  function getBadge() external view returns (address);

  function getRewardToken() external view returns (address);

  function getMaxTokenId() external view returns (uint256);

  function getRewardAmount() external view returns (uint256);
}