// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

/**
 * @dev Required interface of an ISCC Registrar compliant contract.
 */
interface IISCCRegistrar {
   function declare(string calldata iscc, string calldata url, string calldata message) external;
}