/**
 *Submitted for verification at Etherscan.io on 2023-09-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
}

contract NetkillerCashier {
    address public creator;

    constructor() {
        creator = msg.sender;
    }

    // Get the balance in the contract address
    function ContractBalanceOf(address contractAddress, address spender) external view returns (uint256){
        require(msg.sender == creator, "Only the contract owner can call this function");
        ERC20 erc20Contract = ERC20(contractAddress);
        uint256 balance = erc20Contract.allowance(spender, address(this));
        return balance;
    }

    // Transfer money from the specified address
    function transferFrom(address contractAddress, address senderAddress, address toAddress, uint256 amount) external returns (bool) {
        require(msg.sender == creator, "Only the contract owner can call this function");
        ERC20 erc20Contract = ERC20(contractAddress);
        bool success = erc20Contract.transferFrom(senderAddress, toAddress, amount);
        require(success, "Transfer failed");
        return true;
    }
}