// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

/**
 * @title ERC777Receiver interface
 * @dev Interface for any contract that wants to support `transferAndCall` or `transferFromAndCall`
 * from ERC777 token contracts.
 */
interface IERC777Receiver {
    /**
     * @notice Handle the receipt of ERC777 tokens
     * @dev Any ERC777 smart contract calls this function on the recipient
     * after a `transfer` or a `transferFrom`. This function MAY throw to revert and reject the
     * transfer. Return of other than the magic value MUST result in the
     * transaction being reverted.
     * Note: the token contract address is always the message sender.
     * @param operator address The address which called `transferAndCall` or `transferFromAndCall` function
     * @param from address The address which are token transferred from
     * @param to address The address which are token transferred to
     * @param amount uint256 The amount of tokens transferred
     * @param data bytes Additional data with no specified format
     * @param operatorData bytes Additional data from the operator with no specified format
     */
    function tokensReceived(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata data,
        bytes calldata operatorData
    ) external;
}