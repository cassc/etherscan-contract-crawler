// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

struct OracleFacetStorage {
  int256 storedLatestPrice;
  uint256 lastTimestamp;
  uint256 workingTimestamp;
}

struct RoundData {
  uint80 roundId;
  int256 answer;
  uint256 startedAt;
  uint256 updatedAt;
  uint80 answeredInRound;
}

struct CuicaFacetStorage {
  mapping(uint80 => RoundData) roundInfo;
  uint80 lastRound;
  address connext;
}

contract AppStorage {
  bytes32 constant REDSTONE_STORAGE_POSITION = keccak256("redstone.storage");
  bytes32 constant PYTH_STORAGE_POSITION = keccak256("pyth.storage");
  bytes32 constant CHAINLINK_STORAGE_POSITION = keccak256("chainlink.storage");
  bytes32 constant CUICA_STORAGE_POSITION = keccak256("cuica.storage");

  function accessOracleStorage(bytes32 position)
    internal
    pure
    returns (OracleFacetStorage storage s)
  {
    assembly {
      s.slot := position
    }
  }

  function accessCuicaStorage() internal pure returns (CuicaFacetStorage storage s) {
    bytes32 position = CUICA_STORAGE_POSITION;
    assembly {
      s.slot := position
    }
  }
}