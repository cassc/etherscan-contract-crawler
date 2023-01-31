// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;
import "../structs/SliceParams.sol";

interface ISlicerManager {
  function implementation() external view returns (address);

  function _createSlicer(
    address creator,
    uint256 id,
    SliceParams calldata params
  ) external returns (address);

  function _upgradeSlicers(address newLogicImpl) external;
}