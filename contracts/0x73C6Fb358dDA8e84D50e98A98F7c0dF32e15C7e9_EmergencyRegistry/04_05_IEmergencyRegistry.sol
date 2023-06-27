// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title IEmergencyRegistry
 * @author BGD Labs
 * @notice interface containing the events and methods definitions of the EmergencyRegistry contract
 */
interface IEmergencyRegistry {
  /**
   * @notice emitted when there is a change of the emergency state of a network
   * @param chainId id of the network updated
   * @param emergencyNumber indicates the emergency number for network chainId
   */
  event NetworkEmergencyStateUpdated(uint256 indexed chainId, int256 emergencyNumber);

  /**
   * @notice method to get the current state of emergency for a network
   * @param chainId id of the network to check
   * @return number indicating the emergency counter of the chain
   */
  function getNetworkEmergencyCount(uint256 chainId) external view returns (int256);

  /**
   * @notice sets the state of emergency for determined networks
   * @param emergencyChains list of chains which will move to emergency mode
   */
  function setEmergency(uint256[] memory emergencyChains) external;
}