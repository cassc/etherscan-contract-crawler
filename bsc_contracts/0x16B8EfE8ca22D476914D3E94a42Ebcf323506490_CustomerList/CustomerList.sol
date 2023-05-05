/**
 *Submitted for verification at BscScan.com on 2023-05-05
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract CustomerList {
address public owner;

struct Customer {
    bool blacklisted;
    mapping(string => uint256) productActivationTimes;
}

mapping(string => Customer) public customers;
mapping(string => bool) public customerExistence;
mapping(string => bool) public productExistence;

constructor() {
    owner = msg.sender;
}

modifier onlyOwner() {
    require(msg.sender == owner, "Only contract owner can perform this action.");
    _;
}

function addCustomer(string memory customerId) public onlyOwner {
    require(!customerExistence[customerId], "Customer already exists");
    customers[customerId].blacklisted = false;
    customerExistence[customerId] = true;
}

function addProduct(string memory productId) public onlyOwner {
    require(!productExistence[productId], "Product already exists");
    productExistence[productId] = true;
}

function addActivation(string memory customerId, string memory productId, uint256 activationTime) public onlyOwner {
    require(customerExistence[customerId], "Customer does not exist");
    require(productExistence[productId], "Product does not exist");
    customers[customerId].productActivationTimes[productId] = activationTime;
}

function updateCustomerProductExpiration(string memory customerId, string memory productId, uint256 newExpiration) public onlyOwner {
    require(customerExistence[customerId], "Customer does not exist");
    require(productExistence[productId], "Product does not exist");
    require(customers[customerId].productActivationTimes[productId] > 0, "Product not activated for customer");
    customers[customerId].productActivationTimes[productId] = newExpiration;
}

function blacklistCustomer(string memory customerId) public onlyOwner {
    require(customerExistence[customerId], "Customer does not exist");
    customers[customerId].blacklisted = true;
}

function unblacklistCustomer(string memory customerId) public onlyOwner {
    require(customerExistence[customerId], "Customer does not exist");
    customers[customerId].blacklisted = false;
}

function isBlacklisted(string memory customerId) public view returns(bool) {
    return customers[customerId].blacklisted;
}

function getProductActivationTime(string memory customerId, string memory productId) public view returns(uint256) {
    require(customerExistence[customerId], "Customer does not exist");
    require(productExistence[productId], "Product does not exist");
    require(customers[customerId].productActivationTimes[productId] > 0, "Product not activated for customer");
    return customers[customerId].productActivationTimes[productId];
}
}