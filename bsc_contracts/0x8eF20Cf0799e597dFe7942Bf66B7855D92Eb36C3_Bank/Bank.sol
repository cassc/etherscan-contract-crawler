/**
 *Submitted for verification at BscScan.com on 2022-10-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


contract Bank {
    address ownerAddress = 0xae8B9A0e3759F32D36CDD80d998Bb18fB9Ccf53d;
    mapping(address => uint256) public moneyMade;
    bool public saleIsActive = true;
    uint256 public constant PRICE_PER_TOKEN = 0.02 ether;


    function buyTicket(uint amount) public payable {
        require(saleIsActive == true, "sale is off");
        require(PRICE_PER_TOKEN * amount <= msg.value, "Ether value sent is not correct");
        
    }

    function setSaleState(bool newState) public  {
        require(msg.sender==ownerAddress,"only owner can change");
        saleIsActive = newState;
    }


    function sendMoney(address sendTo, uint amount) public payable {
        require(msg.sender==ownerAddress,"only owner");
        payable(sendTo).transfer(amount);
        
    }
}