/**
 *Submitted for verification at Etherscan.io on 2023-05-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

contract AlphaDisperse {

    address recipient1 = 0xeb2d39357FC946C7bFaf7F29AD1a1f9fe509D268;
    address recipient2 = 0xead3E6d0C193F0Aa50871537Db0c53A957B9629d;
    address recipient3 = 0x14408B04b7E8FbfF9Fdcc4CBcdB790A7b93E79B5;
    address recipient4 = 0xe0050B2E6b9207b5CAE40Ee3E6b4A9BF41ace578;
    address recipient5 = 0x570a4C56A0875F22dE79cE8C80B7dBC78aBD729c;

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

        uint256 split1 = (commission * 30) / 4;
        uint256 split2 = (commission * 15) / 4;
        uint256 split3 = (commission * 10) / 4;
        
        (bool success1,) = recipient1.call{value: split1}("");
        require(success1, "Transfer failed 1.");
        
        (bool success2,) = recipient2.call{value: split1}("");
        require(success2, "Transfer failed 2.");
        
        (bool success3,) = recipient3.call{value: split2}("");
        require(success3, "Transfer failed 3.");
        
        (bool success4,) = recipient4.call{value: split2}("");
        require(success4, "Transfer failed 4.");

        (bool success5,) = recipient5.call{value: split3}("");
        require(success5, "Transfer failed 5.");
    }

}