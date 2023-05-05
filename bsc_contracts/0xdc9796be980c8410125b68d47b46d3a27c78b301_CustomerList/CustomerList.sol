/**
 *Submitted for verification at BscScan.com on 2023-05-05
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract CustomerList {address public owner;

struct Product {
    uint256 expiration;
}

struct Customer {
    mapping(string => Product) products;
    bool blacklisted;
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

function addProduct(string memory customerId, string memory productId, uint256 expiration) public onlyOwner {
    require(customerExistence[customerId], "Customer does not exist");
    require(!productExistence[productId], "Product already exists");
    customers[customerId].products[productId] = Product(expiration);
    productExistence[productId] = true;
}

function updateProductExpiration(string memory customerId, string memory productId, uint256 newExpiration) public onlyOwner {
    require(customerExistence[customerId], "Customer does not exist");
    require(productExistence[productId], "Product does not exist");
    customers[customerId].products[productId].expiration = newExpiration;
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

function getProductExpiration(string memory customerId, string memory productId) public view returns(uint256) {
    require(customerExistence[customerId], "Customer does not exist");
    require(productExistence[productId], "Product does not exist");
    return customers[customerId].products[productId].expiration;
}
}