// SPDX-License-Identifier: MIT

// copied from @rarible/royalties/contracts/RoyaltiesV2.sol
// to support the newest solidity version

pragma solidity ^0.8.9;
pragma abicoder v2;

interface ILalaRevenue {
  struct DistributionShare {
    address recipient;
    uint256 share;
  }

  function getDistribution(uint256 amount)
    external
    view
    returns (DistributionShare[] memory);
}