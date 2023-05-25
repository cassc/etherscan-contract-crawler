// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';

contract passaddresslist is Ownable {
    mapping (uint256 => address) public mintList;
    uint256 public totalAdressQuantity;
    uint256 private mintMaxAmount = 100;

    constructor() {}

    function addAdress(address to) public onlyOwner{
        require(totalAdressQuantity <= mintMaxAmount);
        mintList[totalAdressQuantity] = to;
        totalAdressQuantity ++;
    }

    function getAddress(uint256 key) public view returns (address) {
        return mintList[key];
    }

    function getQuantity() public view returns(uint256) {
        return totalAdressQuantity;
    }
}