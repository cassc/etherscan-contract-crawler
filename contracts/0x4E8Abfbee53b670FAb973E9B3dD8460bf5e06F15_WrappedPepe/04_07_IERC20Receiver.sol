// SPDX-License-Identifier: MIT
/**
 * Creator: Virtue Labs
 * Author: 0xYeety, CTO - Virtue Labs
 * Memetics: Church, CEO - Virtue Labs
**/
// (w)REEEEEEEEEEEEEEEEEEE

pragma solidity ^0.8.18;

/**
 * @dev Implementation of the IERC20Receiver interface
 *
 * This interface is meant to be included in contract
 * implementations that are meant to receive ERC20 tokens
**/
interface IERC20Receiver {
    /**
     * @notice Handle the receipt of ERC20 tokens
     * @dev The ERC20 smart contract calls this function on the recipient
     *** after a `transfer` or `transferFrom`. This function MAY throw
     *** to revert and reject the transfer. Return of other than the magic
     *** value MUST result in the transaction being reverted.
     *** Note: the contract address is always the message sender.
     * @dev This function is payable, as it is meant to enable arbitrary follow-on
     *** functionality, so it must be able to pass a message value
     * @param _operator: The address which called `transfer` or `transferFrom` function
     * @param _from: The address which previously owned the transferred amount
     * @param _amount: The token amount which is being transferred
     * @param _data: Arbitrary call data that may be passed in order to trigger
     *** follow-on functionality
     * @return `bytes4(keccak256("onERC20Received(address,address,uint256,bytes)"))` unless throwing
    **/
    function onERC20Received(
        address _operator,
        address _from,
        uint256 _amount,
        bytes memory _data
    ) external payable returns (bytes4);
}

/**************************************/