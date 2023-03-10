//SPDX-License-Identifier: Unlicense

/*

 __   __  __   __  ______    _______  ___  
|  | |  ||  | |  ||    _ |  |       ||   | 
|  |_|  ||  | |  ||   | ||  |    ___||   | 
|       ||  |_|  ||   |_||_ |   |___ |   | 
|_     _||       ||    __  ||    ___||   | 
  |   |  |       ||   |  | ||   |___ |   | 
  |___|  |_______||___|  |_||_______||___| 


*/

pragma solidity ^0.8.15;

import "./key.sol";
import "./Phase3.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// Contract that will own YureiDayAndNight
contract KeyMaseter is Ownable {
    YureiPhurba Phurba;
    Joumeijin Hunter;
    uint256 public price = 0.005 ether;
    mapping(address => bool) public claimed;
    uint256 public Mintcounter = 157;

    address immutable nerd = 0xEf3bd95241015B733BD8fbb9572C4C5E7377692d;
    
    constructor(address _phurbaAddress, address _hunterAddress) {
        Phurba = YureiPhurba(_phurbaAddress);
        Hunter = Joumeijin(_hunterAddress);
    }

    modifier IsUser() {
        require(tx.origin == msg.sender, "Cannot be called by a contract");
        _;
    }


    function MakeMeOwner() onlyOwner public {

        Phurba.transferOwnership(msg.sender);

    }

    function BuyKey(uint256 amount) public payable IsUser {

        if(Hunter.balanceOf(msg.sender)<1) revert NoYureiOwned();
        require(msg.value == price*amount, "insufficient funds provided");
        require(Hunter.totalSupply() < 3334, "supply reached");
        require(amount<6, "Cant mint more than 5");

        ++Mintcounter;
        sendEth();
        Phurba.OwnerMint(msg.sender, amount);

    }


    function sendEth() internal {

        payable(nerd).transfer(address(this).balance);
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }


}