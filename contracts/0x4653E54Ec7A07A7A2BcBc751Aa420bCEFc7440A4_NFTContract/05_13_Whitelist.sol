//"SPDX-License-Identifier: UNLICENSED"

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Whitelist is Ownable {
    mapping(address => bool) public whitelist;

    function addAddressToWhitelist(address addr) onlyOwner public {
            whitelist[addr] = true;
    }

    function addAddressesToWhitelist(address[] calldata addrs) onlyOwner public {
        for (uint256 i = 0; i < addrs.length; i++) {
            addAddressToWhitelist(addrs[i]);
        }
    }
}