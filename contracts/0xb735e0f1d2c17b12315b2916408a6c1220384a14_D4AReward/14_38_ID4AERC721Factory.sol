// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

interface ID4AERC721Factory {
    function createD4AERC721(string memory _name, string memory _symbol) external returns (address);
}