// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

abstract contract IChainLogView {
  /**
   * @notice Gets the address of a service by its name
   * @param serviceName The name of the service
   * @return The address of the service
   */

  function getServiceAddress(string calldata serviceName) external view virtual returns (address);

  /**
   * @notice Gets the address of a join adapter by its ilk name
   * @param ilkName The name of the ilk
   * @return The address of the join adapter
   */
  function getIlkJoinAddressByName(string calldata ilkName) external view virtual returns (address);

  /**
   * @notice Gets the address of a join adapter by its ilk hash
   * @param ilkHash The hash of the ilk name
   * @return The address of the join adapter
   */
  function getIlkJoinAddressByHash(bytes32 ilkHash) public view virtual returns (address);
}