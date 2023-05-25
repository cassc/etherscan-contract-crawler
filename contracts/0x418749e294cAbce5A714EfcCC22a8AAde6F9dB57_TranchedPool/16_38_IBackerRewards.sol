// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

interface IBackerRewards {
  function allocateRewards(uint256 _interestPaymentAmount) external;

  function setPoolTokenAccRewardsPerPrincipalDollarAtMint(address poolAddress, uint256 tokenId) external;
}