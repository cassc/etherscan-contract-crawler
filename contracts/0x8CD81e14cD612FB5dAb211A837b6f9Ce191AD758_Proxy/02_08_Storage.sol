// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/[email protected]/access/Ownable.sol";

contract Storage is Ownable {
    mapping(address => bool) whitelist;

    function grantAccess(address addr) public onlyOwner {
        require(whitelist[addr] == false, "[WSTORAGE] address already whitelisted");
        whitelist[addr] = true;
    }

    function revokeAccess(address addr) public onlyOwner {
        require(whitelist[addr] == true, "[WSTORAGE] address not in whitelist");
        whitelist[addr] = false;
    }

    function checkAccess(address from) public view returns (bool) {
        return whitelist[from];
    }

    fallback() external payable {
        revert('[WSTORAGE] Invalid method name');
    }

    receive() external payable {
        revert('[WSTORAGE] ETH transfers forbidden');
    }
}