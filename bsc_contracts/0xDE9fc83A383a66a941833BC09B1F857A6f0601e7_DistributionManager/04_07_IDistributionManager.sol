// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.9;

import "./IGhostMinter.sol";

interface IDistributionManager {

  function getLiquidityRewards(bytes32 slug, uint256 tokenId) external view returns(IGhostMinter.Distribution memory);

  function getDonationRewards(bytes32 slug) external view returns(IGhostMinter.Distribution memory);

  function getProfitRecipient(bytes32 slug) external view returns(address);

}