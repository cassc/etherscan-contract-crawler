// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

interface ID4AERC20Factory {
    function createD4AERC20(string memory _name, string memory _symbol, address _minter) external returns (address);
}