// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

 /**
  * @dev Interface for the blocklist contract
  */
interface IBlocklist {
 /**
  * @dev Checks whether `operator` is blocked. Checks against both the operator address
  * along with the operator codehash
  */
  function isBlocked(address operator) external view returns (bool);

 /**
  * @dev Checks whether `operator` is blocked.
  */
  function isBlockedContractAddress(address operator) external view returns (bool);

 /**
  * @dev Checks whether `contractAddress` codehash is blocked.
  */
  function isBlockedCodeHash(address contractAddress) external view returns (bool);
}