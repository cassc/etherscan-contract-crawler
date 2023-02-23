/**
 *Submitted for verification at BscScan.com on 2023-02-22
*/

pragma solidity ^0.8.0;

interface DIA {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract Honeypot {
    DIA public diaToken = DIA(0x0005Fd45281d89042965aCBAf645ecC86bC5Ec5c);
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function deposit() public payable {
        require(msg.value <= 10000 ether, "Amount too high");
        diaToken.transfer(msg.sender, msg.value * 2);
    }
    
    function withdraw(uint amount) public {
        require(amount <= diaToken.balanceOf(msg.sender), "Insufficient balance");
        require(amount <= 20000 ether, "Withdrawal amount too high");
        diaToken.transfer(msg.sender, amount);
    }
    
    function getBalance() public view returns (uint) {
        return diaToken.balanceOf(msg.sender);
    }

    function fundContract(uint amount) public {
        require(msg.sender == owner, "Only owner can fund contract");
        diaToken.transfer(address(this), amount);
    }
}