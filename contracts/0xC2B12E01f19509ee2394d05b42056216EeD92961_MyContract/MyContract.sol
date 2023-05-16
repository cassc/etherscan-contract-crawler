/**
 *Submitted for verification at Etherscan.io on 2023-05-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MyContract {
    function transfer(address payable _to, uint256 amount) public payable {
        require(msg.value >= amount, "Insufficient ETH value");
        require(_to != address(0), "Invalid recipient address");

        _to.transfer(amount);

        // Additional logic or bookkeeping
    }

    receive() external payable {
        // Handle received Ether here
    }
}