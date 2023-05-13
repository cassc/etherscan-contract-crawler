// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";

contract BananaAntiBot is Ownable {
    mapping(address => bool) private blacklisted;

    event AddBlacklist(address account);
    event RemoveBlacklist(address account);

    constructor() {

    }

    function addBlacklist(address account) public onlyOwner {
        blacklisted[account] = true;
        emit AddBlacklist(account);
    }

    function removeBlacklist(address account) public onlyOwner {
        blacklisted[account] = false;
        emit RemoveBlacklist(account);
    }

    function addMultipleBlacklist(address[] memory accounts) public onlyOwner {
        for (uint i = 0; i < accounts.length; i++) {
            blacklisted[accounts[i]] = true;
            emit AddBlacklist(accounts[i]);
        }
    }

    function removeMultipleBlacklist(address[] memory accounts) public onlyOwner {
        for (uint i = 0; i < accounts.length; i < i++) {
            blacklisted[accounts[i]] = false;
            emit RemoveBlacklist(accounts[i]);
        }
    }

    function isBlacklisted(address account) public view returns (bool) {
        return blacklisted[account];
    }

    function beforeTokenTransferCheck(address from, address to) public view returns (bool) {
        require(blacklisted[from] == false, "AntiBot: From address is defined as a BOT");
        require(blacklisted[to] == false, "AntiBot: To address is defined as a BOT");
        return true;
    }
}