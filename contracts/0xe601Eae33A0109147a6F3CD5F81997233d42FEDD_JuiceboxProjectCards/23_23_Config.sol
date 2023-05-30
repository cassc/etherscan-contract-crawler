// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

struct Config {
    address projects; // The JBProjects contract
    address payable revenueRecipient; // The address that mint revenues are forwarded to
    uint256 price; // The price of the NFT in wei
    string contractUri; // The URI of the contract metadata
}