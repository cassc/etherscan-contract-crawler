// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

/**
 * @dev Required interface of an ISCC Hub compliant contract.
 */
interface IISCCHub {
  function announce(string calldata iscc, string calldata url, string calldata message) external;
}