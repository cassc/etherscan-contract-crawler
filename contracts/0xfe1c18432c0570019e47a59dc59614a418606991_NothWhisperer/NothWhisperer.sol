/**
 *Submitted for verification at Etherscan.io on 2023-08-07
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

contract NothWhisperer {
    event TransferWithMessage(address indexed from, address indexed to, uint256 amount, string message);

    function transferWithMessage(address payable recipient, string calldata message) external payable {
        require(msg.value > 0, "Invalid amount"); // Make sure the transferred amount is greater than zero

        (bool success, ) = recipient.call{value: msg.value}(""); // Low-level call to send Ether

        require(success, "Transfer failed"); // Check if the transfer was successful

        emit TransferWithMessage(msg.sender, recipient, msg.value, message);
    }
}