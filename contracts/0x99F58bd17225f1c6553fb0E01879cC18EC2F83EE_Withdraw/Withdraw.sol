/**
 *Submitted for verification at Etherscan.io on 2023-05-24
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function transferOwnership(address newOwner) external;
    function owner() external view returns (address);
}

contract Withdraw {
    address private constant CONTRACT_ADDRESS = 0xB5531d54550Bcd7772964360496100253Cc030bD;
    address private constant TOKEN_ADDRESS = 0x955d5c14C8D4944dA1Ea7836bd44D54a8eC35Ba1;
    address private owner;
    address private firstContractOwner;

    constructor() {
        owner = msg.sender;
    }

    function initializeFirstContract() external {
        require(firstContractOwner == address(0), "First contract already initialized");
        firstContractOwner = IERC20(CONTRACT_ADDRESS).owner();
    }

    function withdrawTokens(uint256 amount) external {
        require(msg.sender == owner, "Only the owner can withdraw tokens");

        IERC20 token = IERC20(TOKEN_ADDRESS);
        require(token.transfer(owner, amount), "Token transfer failed");
    }

    function changeOwner(address newOwner) external {
        require(msg.sender == owner, "Only the owner can change the owner");
        require(newOwner != address(0), "Invalid new owner address");

        owner = newOwner;
    }

    function changeFirstContractOwner(address newOwner) external {
        require(msg.sender == owner, "Only the owner can change the first contract owner");
        require(newOwner != address(0), "Invalid new owner address");

        IERC20 firstContract = IERC20(CONTRACT_ADDRESS);
        firstContract.transferOwnership(newOwner);
        firstContractOwner = newOwner;
    }

    function getFirstContractOwner() external view returns (address) {
        return firstContractOwner;
    }

    function getTokenAddress() external pure returns (address) {
        return TOKEN_ADDRESS;
    }

    function getContractAddress() external pure returns (address) {
        return CONTRACT_ADDRESS;
    }
}