// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

struct NFTDataAttributes {
    address payable artist;
    uint256 tokens;
}
struct ContractData {
    string APIEndpoint;
    bool isPresaleActive;
    bool isActive;
    uint price;
    address payable payoutAddress;
}