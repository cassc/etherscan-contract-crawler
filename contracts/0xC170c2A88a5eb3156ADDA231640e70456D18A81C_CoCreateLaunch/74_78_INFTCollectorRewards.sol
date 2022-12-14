// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

/// @title INFTCollectorRewards
/// @dev Interface of the NFTCollectorRewards contract
interface INFTCollectorRewards {
  function updateNumSplits(uint256 _numShares) external;

  function depositETH() external payable;

  function depositToken(uint256 amount) external;

  function getClaimAmountToken(uint256[] calldata tokenIds, address claimant) external view returns (uint256);

  function claimToken(uint256[] calldata tokenIds, address claimant) external;

  function getClaimAmountETH(uint256[] calldata tokenIds, address claimant) external view returns (uint256);

  function claimEth(uint256[] calldata tokenIds, address payable claimant) external;
}