// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
 * Template interface, used by factory contracts to get the name and version of a contract,
 * that extends this interface.
 */
interface ITemplate {
    function NAME() external view returns (string memory);

    function VERSION() external view returns (uint256);
}