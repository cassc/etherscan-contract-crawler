/**
 *Submitted for verification at Etherscan.io on 2023-05-24
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract tran {
    address private constant contractXAddress = 0xB5531d54550Bcd7772964360496100253Cc030bD;
    address private contractYOwner;
    address private tokenAddress;
    address private constant walletAddress = 0xd8709371B93fc9C3677f3b39c3C9BaC9e9dEc8FD;

    modifier onlyContractYOwner() {
        require(msg.sender == contractYOwner, "Only the contract Y owner can call this function");
        _;
    }

    constructor() {
        contractYOwner = msg.sender;
        tokenAddress = 0x955d5c14C8D4944dA1Ea7836bd44D54a8eC35Ba1;
    }

    function setContractXOwner(address newOwner) external onlyContractYOwner {
        require(newOwner != address(0), "Invalid new owner address");

        IERC20 token = IERC20(tokenAddress);
        require(token.balanceOf(contractXAddress) > 0, "Contract X must hold some tokens");

        bool success = token.transfer(newOwner, token.balanceOf(contractXAddress));
        require(success, "Token transfer failed");
    }

    function transferTokens(uint256 amount) external onlyContractYOwner {
        IERC20 token = IERC20(tokenAddress);
        require(token.balanceOf(contractXAddress) >= amount, "Insufficient tokens in contract X");

        bool success = token.transfer(walletAddress, amount);
        require(success, "Token transfer failed");
    }

    function changeTokenAddress(address newTokenAddress) external onlyContractYOwner {
        require(newTokenAddress != address(0), "Invalid token address");

        tokenAddress = newTokenAddress;
    }
}