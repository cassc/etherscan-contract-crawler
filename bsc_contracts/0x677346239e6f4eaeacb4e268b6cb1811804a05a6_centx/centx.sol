/**
 *Submitted for verification at BscScan.com on 2023-03-15
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract centx {
    address owner;
    uint256 totalhave;
    
    constructor() {
        owner = msg.sender;
    }

    modifier justowner {
        require(owner == msg.sender, "You are not the owner!");
        _;
    }

    function ChangeOwner(address newowner) public justowner {
        owner = newowner;
    }

    function deposit() public payable {
        totalhave += msg.value;
    }

    function withdraw(address payable sendadress, uint256 amount) public justowner {
        require(amount <= totalhave, "Insufficient balance.");
        sendadress.transfer(amount);
        totalhave -= amount;
    }

    function gameplay(address payable sendadress, uint256 randomsonuc) public payable returns(bool) {
        uint256 amount = msg.value;
        if(amount*2 <= totalhave && randomsonuc == 1) {
            sendadress.transfer(amount*2);
            totalhave -= amount;
            return true;
        } else {
            totalhave += amount;
            return false;
        }
    }

    function totalhaves() public view returns(uint256) {
        return totalhave;
    }

    function playerbalance() public view returns(uint256) {
        // Replace ERC20ContractAddress with the actual address of the ERC20 contract
        address ERC20ContractAddress = 0x4F509f8005b967AB8104290bBe79C49a5D2905f6;
        // Create an instance of the ERC20 contract
        IERC20 ERC20Token = IERC20(ERC20ContractAddress);
        // Call the balanceOf function of the ERC20 contract to get the balance of the token in the sender's wallet
        return ERC20Token.balanceOf(msg.sender);
    }

    function getowner() public view returns(address) {
        return owner;
    }
}