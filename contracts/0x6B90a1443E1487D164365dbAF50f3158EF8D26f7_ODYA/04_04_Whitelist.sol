// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./Ownable.sol";

contract Whitelist is Ownable {
    mapping(address => bool) private whitelist;
    mapping(address => uint) private addressIdx;
    address[] private whiteArr;

    event WhitelistedAddressAdded(address addr);
    event WhitelistedAddressRemoved(address addr);

    constructor() {
        addAddressToWhitelist(msg.sender);
    }

    modifier onlyWhitelisted() {
        require(whitelist[msg.sender]);
        _;
    }

    function isWhitelist(address addr) public view returns (bool success) {
        return whitelist[addr];
    }

    function addAddressToWhitelist(address addr) onlyOwner public returns (bool success) {
        if (!whitelist[addr]) {
            whitelist[addr] = true;
            addressIdx[addr] = whiteArr.length;
            whiteArr.push(addr);

            emit WhitelistedAddressAdded(addr);
            success = true;
        }
    }

    function removeAddressFromWhitelist(address addr) onlyOwner public returns (bool success) {
        if (whitelist[addr]) {
            whitelist[addr] = false;
            uint deleteIdx = addressIdx[addr];
            address lastAddr = whiteArr[whiteArr.length - 1];
            addressIdx[lastAddr] = deleteIdx;
            delete addressIdx[addr];
            whiteArr[deleteIdx] = lastAddr;
            whiteArr.pop();

            emit WhitelistedAddressRemoved(addr);
            success = true;
        }
    }

    function getCountWhiteArr() public onlyOwner view returns (uint count) {
        count = whiteArr.length;
    }

    function getWhiteArrByIdx(uint idx) public onlyOwner view returns (address whiteAddress) {
        whiteAddress = whiteArr[idx];
    }

    function getWhiteArr() public onlyOwner view returns (address[] memory whiteArray) {
        whiteArray = whiteArr;
    }
}