// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.10;

/**
 * @notice Simple interface to interact with EIP-173 implementing contracts
 */
interface IOwnable {
    function owner() external view returns (address);
}