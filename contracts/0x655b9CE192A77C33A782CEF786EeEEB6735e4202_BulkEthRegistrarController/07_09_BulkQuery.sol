// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12; 

struct BulkQuery {
    string name;  
    uint256 duration; 
    address owner;
    address resolver;
    address addr;
}