pragma solidity ^0.8.0;

//FTX suck my live, come get all my ether. I want to leave blockchain forever
//Take the treasure , fcfs
//Read the smart contract yourself
//more treasure will come...

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract FkFtxTreasure is Ownable{
    
    uint private secret_num;
    bool public start;

    constructor(address newOwner){
        _transferOwnership(newOwner);
    }
    
    function bet(uint num) public payable{
        require(msg.sender == tx.origin, "human only");
        require(start == true, "not start");
        require(num > 0, "invalid num");
        require(msg.value >= 1 ether, "insufficient balance");
        if(secret_num == num){
            payable(msg.sender).transfer(address(this).balance);
            start = false;
        }
    }
    function setNumAndStart(uint newNum) public payable onlyOwner{
        //initial the number if the number not been set
        if(secret_num > 0 && start == false){
            secret_num = newNum;
        }
        start = true;
    }
    function stopGame() public payable onlyOwner {
        start = false;
        payable(msg.sender).transfer(address(this).balance);
    }
}