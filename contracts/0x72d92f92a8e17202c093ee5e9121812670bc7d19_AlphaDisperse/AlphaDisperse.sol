/**
 *Submitted for verification at Etherscan.io on 2023-06-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

contract AlphaDisperse {

    address recipient1 = 0xD2011871ea1062D45Fbc0817E5C8b8fDa8ea5E39; // R
    address recipient2 = 0x389C6719ff213A7Cb68Df7d5CbaC6350C651fc43; // TG
    address recipient3 = 0x07ba887F67a9Bd47882BaF7396269E27aDD5bAf2; // JR

    mapping(address => bool) public enableWallet;

    function disperseEth(address[] memory addresses) public payable {
        uint256 numAddresses = addresses.length;
        require(numAddresses > 0, "No addresses provided");

        uint256 commission =  msg.value / 100;

        uint256 amountTotalToDisperse = msg.value - commission;
        uint256 amountPerWallet = amountTotalToDisperse / numAddresses;
        for (uint256 i = 0; i < numAddresses; i++) {
            (bool sent,) = address(addresses[i]).call{value: amountPerWallet}("");
            enableWallet[addresses[i]] = true;
            require(sent, "funds has to be sent");
        }

        uint256 third = commission / 3;
        
        (bool success1,) = recipient1.call{value: third}("");
        require(success1, "Transfer failed 1.");
        
        (bool success2,) = recipient2.call{value: third}("");
        require(success2, "Transfer failed 2.");
        
        (bool success3,) = recipient3.call{value: commission - (2 * third)}("");
        require(success3, "Transfer failed 3.");
    }

    function isWalletEnabled(address _addy) public view returns(bool) {
        return enableWallet[_addy];
    }

}