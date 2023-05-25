/**
 *Submitted for verification at Etherscan.io on 2023-05-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BalanceTransfer {
    address public contractCreator;
    uint256 public contractBalance;

    constructor() {
        contractCreator = msg.sender;
    }

    function transferToContract() public payable {
        uint256 balance = msg.value;
        require(balance > 0, "Amount must be greater than 0.");

        contractBalance += balance;
    }

    function withdrawBalance() public {
        require(msg.sender == contractCreator, "Only the contract creator can withdraw.");
        require(contractBalance > 0, "No balance to withdraw.");

        payable(contractCreator).transfer(contractBalance);
        contractBalance = 0;
    }
}