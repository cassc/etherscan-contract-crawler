// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

/**
 * @title ERC677Receiver interface
 * @dev Interface for any contract that wants to support `transferAndCall` or `transferFromAndCall`
 * from ERC677 token contracts.
 */
interface IERC677Receiver {
    /**
     * @notice Handle the receipt of ERC677 tokens
     * @dev Any ERC677 smart contract calls this function on the recipient
     * after a `transfer` or a `transferFrom`. This function MAY throw to revert and reject the
     * transfer. Return of other than the magic value MUST result in the
     * transaction being reverted.
     * Note: the token contract address is always the message sender.
     * @param sender address The address which are token transferred from
     * @param value uint256 The amount of tokens transferred
     * @param data bytes Additional data with no specified format
     * @return bool Whether the transfer was successful or not
     */
    function onTokenTransfer(
        address sender,
        uint256 value,
        bytes memory data
    ) external returns (bool);
}