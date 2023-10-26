// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title IGnosisChainAdapter
 * @author BGD Labs
 * @notice interface containing the method definitions used in the Gnosis Chain bridge adapter
 */
interface IGnosisChainAdapter {
  /**
   * @notice method to get the Gnosis Arbitrary Message Bridge address
   * @return address of the Gnosis Arbitrary Message Bridge
   */
  function BRIDGE() external view returns (address);

  /**
   * @notice method called by the Arbitrary Message Bridge on Gnosis Chain with the bridged message
   * @param message bytes containing the bridged information
   */
  function receiveMessage(bytes calldata message) external;

  /**
   * @notice method to know if a destination chain is supported
   * @return flag indicating if the destination chain is supported
   */
  function isDestinationChainIdSupported(uint256 chainId) external pure returns (bool);
}