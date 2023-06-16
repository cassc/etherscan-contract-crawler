/**
 *Submitted for verification at Etherscan.io on 2023-06-15
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;


contract BatchTransfer {

    address public admin;

    constructor() {
        admin = msg.sender;
    }

    receive() external payable {
    }

    function transferAdmin(address newAdmin) public {
        require(newAdmin != address(0), "empty address");
        admin = newAdmin;
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function batchSend (address[] calldata to , uint256[] calldata amount) public payable {

        require(msg.sender == admin, "only admin can send transfer");
        uint256 total = 0;
        for (uint i = 0; i < amount.length; i++) {
            total += amount[i];
        }
        require(address(this).balance >= total, "balance not enough");
        for (uint i = 0; i < to.length; i++) {
            (bool success,) = to[i].call{value: amount[i]}("");
            require(success, "failed to send");
        }
    }

}