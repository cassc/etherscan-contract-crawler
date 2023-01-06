// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;
import "./XAssetInterface.sol";

interface XAssetReadWriteInterface is XAssetInterface {

  function getRecordAtIndex(uint256 index) external view returns (AssetDetailRecord memory, uint64);

  function update(uint64 blockNumber, int192 balance, uint64 observationTimestamp) external;

}