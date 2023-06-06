// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/**
 * @dev Required interface of an Registry compliant contract.
 */
interface IRegistry {
 /**
  * @dev Emitted when address trying to transfer is not allowed on the registry
  */
  error NotAllowed();

 /**
  * @dev Checks whether `operator` is valid on the registry; let the registry 
  * decide across both allow and blocklists.
  */
  function isAllowedOperator(address operator) external view returns (bool);

 /**
  * @dev Checks whether `operator` is allowed on the registry
  */
  function isAllowed(address operator) external view returns (bool);

 /**
  * @dev Checks whether `operator` is blocked on the registry
  */
  function isBlocked(address operator) external view returns (bool);
}