// SPDX-License-Identifier: MIT
pragma solidity >=0.6.8;

import './IZTreasuryV2Metadata.sol';
import './IZTreasuryV2ProtocolParameters.sol';

interface IZTreasuryV2 is IZTreasuryV2ProtocolParameters, IZTreasuryV2Metadata {
  event EarningsDistributed(
    uint256 maintainerRewards, 
    uint256 governanceRewards, 
    uint256 totalEarningsDistributed
  );

  function lastEarningsDistribution() external returns (uint256);
  function totalEarningsDistributed() external returns (uint256);
  function distributeEarnings() external;
}