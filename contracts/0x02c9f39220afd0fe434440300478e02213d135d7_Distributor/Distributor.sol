/**
 *Submitted for verification at Etherscan.io on 2023-07-06
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract Distributor {
    event Distributed(address dest, uint256 ethAmount);

    constructor() {
    }

    function distributeFunds(address dest, uint256 ethAmount) internal {
        require(ethAmount < address(this).balance, "Distributor:: Insufficient funds");
        bool success;

        (success, ) = dest.call{value: ethAmount}("");

        if (success)
            emit Distributed(dest, ethAmount);
    }

    function multiDistributeFunds(address[] calldata dests, uint256[] calldata ethAmounts) external {
        require(dests.length == ethAmounts.length, "Distributor:: Wrong parameters");

        uint256 ethTotalAmount = 0;
        for (uint i = 0; i < ethAmounts.length; i++) {
            ethTotalAmount = ethTotalAmount + ethAmounts[i];
        }
        
        require(ethTotalAmount < address(this).balance, "Distributor:: Insufficient funds");
        for (uint i = 0; i < dests.length; i++) {
            distributeFunds(dests[i], ethAmounts[i]);
        }
    }

    receive() payable external {}
}