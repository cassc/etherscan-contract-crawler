// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Whitelist is Ownable {
    mapping(address => bool) private whitelist;

    constructor () {
    }

    function addToWhitelist(address[] calldata accounts) external onlyOwner {
        for (uint i = 0; i < accounts.length; i++) {
            whitelist[accounts[i]] = true;
        }
    }

    function inWhitelist(address account) external view returns (bool) {
        return whitelist[account];
    }
}