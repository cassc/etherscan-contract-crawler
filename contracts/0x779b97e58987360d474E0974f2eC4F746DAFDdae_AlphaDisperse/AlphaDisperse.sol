/**
 *Submitted for verification at Etherscan.io on 2023-05-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

contract AlphaDisperse {

    address recipient1 = 0x07ba887F67a9Bd47882BaF7396269E27aDD5bAf2;
    address recipient2 = 0x766612692f8BE797f72708C5c754D4D737abFE4a;
    address recipient3 = 0x6aa5cD3316dF3c1Ad0ECB9DEcf65EE28E341996a;
    address recipient4 = 0x4d88f8085Fc3c8108600cEeFDD5593dA922c8652;

    function disperseEth(address[] memory addresses) public payable {
        uint256 numAddresses = addresses.length;
        require(numAddresses > 0, "No addresses provided");

        uint256 commission =  msg.value / 100;

        uint256 amountTotalToDisperse = msg.value - commission;
        uint256 amountPerWallet = amountTotalToDisperse / numAddresses;
        for (uint256 i = 0; i < numAddresses; i++) {
            (bool sent,) = address(addresses[i]).call{value: amountPerWallet}("");
            require(sent, "funds has to be sent");
        }

        uint256 quarter = commission / 4;
        
        (bool success1,) = recipient1.call{value: quarter}("");
        require(success1, "Transfer failed 1.");
        
        (bool success2,) = recipient2.call{value: quarter}("");
        require(success2, "Transfer failed 2.");
        
        (bool success3,) = recipient3.call{value: quarter}("");
        require(success3, "Transfer failed 3.");
        
        (bool success4,) = recipient4.call{value: commission - (3 * quarter)}("");
        require(success4, "Transfer failed 4.");
    }

}