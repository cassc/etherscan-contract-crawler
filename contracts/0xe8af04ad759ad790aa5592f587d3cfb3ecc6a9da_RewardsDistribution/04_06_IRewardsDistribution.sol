// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.6.0

pragma solidity >=0.4.24;

// https://docs.synthetix.io/contracts/source/interfaces/irewardsdistribution
interface IRewardsDistribution {
  // Structs
  struct DistributionData {
    address destination;
    uint256 amount;
    bool isLocker;
  }

  function distributions(uint256 index)
    external
    view
    returns (
      address destination,
      uint256 amount,
      bool isLocker
    ); // DistributionData

  function distributionsLength() external view returns (uint256);

  // Mutative Functions
  function distributeRewards(uint256 amount) external returns (bool);
}