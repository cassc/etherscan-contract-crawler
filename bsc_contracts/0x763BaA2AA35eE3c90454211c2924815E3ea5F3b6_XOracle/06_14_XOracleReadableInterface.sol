// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;
import "./XAssetInterface.sol";

interface XOracleReadableInterface is XAssetInterface {

  function getRecordsAtIndex(uint256 _index) external view returns (BatchAssetRecord memory);

}