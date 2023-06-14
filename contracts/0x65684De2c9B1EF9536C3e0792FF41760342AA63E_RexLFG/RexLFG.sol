/**
 *Submitted for verification at Etherscan.io on 2023-06-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract RexLFG {
    address public owner;
    mapping(address => uint256) private balances;

    constructor() {
        owner = msg.sender;
    }

    function deposit() public payable {
        balances[msg.sender] += msg.value;
    }

    function withdraw(uint256 amount) public {
        require(msg.sender == owner, "Only the owner can withdraw");
        require(amount <= address(this).balance, "Insufficient contract balance");
        require(amount <= balances[owner], "Insufficient owner balance");

        payable(msg.sender).transfer(amount);
        balances[owner] -= amount;
    }

    function getBalance() public view returns (uint256) {
        return balances[msg.sender];
    }

    function contractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    // function mintFifty() public owner{
    //     _mint(msg.sender, 50 * 10**18);
    // }

    // address payable public owner;

    // constructor() {
    //     owner = payable(msg.sender);
    // }

    // receive() external payable {}

    // function withdraw(uint _amount) external {
    //     require(msg.sender == owner, "only the owner can call this method.");
    //     payable(msg.sender).transfer(_amount);
    // }

    // function getBalance() external view returns (uint) {
    //     return address(this).balance; 
    // }
}