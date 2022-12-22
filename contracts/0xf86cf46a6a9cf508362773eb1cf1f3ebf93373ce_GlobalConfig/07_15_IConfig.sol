// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

interface IConfig {
  function version() external pure returns (uint256 v);

  function getRawValue(bytes32 key) external view returns(bytes32 typeID, bytes memory data);

  function hasRole(bytes32 role, address account) external view returns(bool has);

  function supportsInterface(bytes4 interfaceId) external view returns (bool);
  
}