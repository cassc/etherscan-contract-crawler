// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.3;

interface IOndo {
  enum InvestorType {
    CoinlistTranche1,
    CoinlistTranche2,
    SeedTranche
  }

  // ----------- State changing api -----------

  /// @notice Called by timelock contract to initialize locked balance of coinlist/seed investor
  function updateTrancheBalance(
    address beneficiary,
    uint256 rawAmount,
    InvestorType tranche
  ) external;

  // ----------- Getters -----------

  /// @notice Gets the TOTAL amount of Ondo available for an address
  function getFreedBalance(address account) external view returns (uint96);

  /// @notice Gets the initial locked balance and unlocked Ondo for an address
  function getVestedBalance(address account)
    external
    view
    returns (uint96, uint96);
}