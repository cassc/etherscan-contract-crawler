// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IBondGovernor {
  struct Policy {
    uint256 controlVariable; // [ray]
    uint256 lastControlVariableUpdate; // [unix timestamp]
    uint256 targetControlVariable; // [ray]
    uint256 timeToTargetControlVariable; // [seconds]
    uint256 minimumPrice; // [wad]
  }

  function initializePolicy(
    address asset,
    uint256 controlVariable,
    uint256 minimumPrice
  ) external;

  function adjustPolicy(
    address asset,
    uint256 targetControlVariable,
    uint256 timeToTargetControlVariable,
    uint256 minimumPrice
  ) external;

  function updateControlVariable(address asset) external;

  function setFees(uint256 _fees) external;

  function setMinimumSize(uint256 _minimumSize) external;

  function setMaximumRatio(uint256 _maximumRatio) external;

  function getControlVariable(address asset)
    external
    view
    returns (uint256 controlVariable);

  function maximumBondSize() external view returns (uint256 maxBondSize);

  function getPolicy(address asset)
    external
    view
    returns (
      uint256 currentControlVariable,
      uint256 minPrice,
      uint256 minSize,
      uint256 maxBondSize,
      uint256 fees
    );

  event UpdatedFees(uint256 fees);
  event UpdatedMinimumSize(uint256 fees);
  event UpdatedMaximumRatio(uint256 fees);
  event CreatedPolicy(
    address indexed asset,
    uint256 controlVariable,
    uint256 minPrice
  );
  event UpdatedPolicy(
    address indexed asset,
    uint256 targetControlVariable,
    uint256 minPrice,
    uint256 timeToTargetControlVariable
  );
}