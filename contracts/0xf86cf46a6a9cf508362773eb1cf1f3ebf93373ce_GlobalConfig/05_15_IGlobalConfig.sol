// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./IConfig.sol";

interface IGlobalConfig is IConfig {

  event SetKVEvent(bytes32 indexed key, string keyStr, bytes32 typeID, bytes data);

  function getKey(string memory keyStr) external pure returns(bytes32 key);
  
  function setKVs(bytes[] memory mds) external;

}