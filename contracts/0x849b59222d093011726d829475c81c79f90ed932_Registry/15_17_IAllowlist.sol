// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

 /**
  * @dev Interface for the allowlist contract
  */
interface IAllowlist {
 /**
  * @dev Emitted when address trying to transfer is not on the allowlist
  */
  error NotAllowlisted();

 /**
  * @dev Checks whether `operator` is allowed. If operator is a contract
  * it will also check if the codehash is allowed.
  */
  function isAllowed(address operator) external view returns (bool);

 /**
  * @dev Checks whether `operator` is on the allowlist
  */
  function isAllowedContractAddress(address operator) external view returns (bool);

 /**
  * @dev Checks whether `contractAddress` codehash is on the allowlist
  */
  function isAllowedCodeHash(address contractAddress) external view returns (bool);
}