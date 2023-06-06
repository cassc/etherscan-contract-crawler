// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.10;

/**
 * @dev Interface of to mint ERC20 tokens.
 */
interface IMinter {
    function mint(address to, uint256 value) external;
}