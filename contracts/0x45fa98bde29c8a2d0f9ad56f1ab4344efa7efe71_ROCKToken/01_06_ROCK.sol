// SPDX-License-Identifier: MIT
// Telegram: https://t.me/rockcoin69
// Twitter: https://twitter.com/rockcoin69
// website: https://pastebin.com/Ufk6BRtP
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ROCKToken is ERC20, Ownable {
    mapping(address => bool) private _blacklist;
    
    address private constant INITIAL_OWNER = 0xb370e2ca39e15a88A0E5A12e1fE09D4FE7858216;
    uint256 private constant FIXED_SUPPLY = 10000000000 * (10 ** 18); // 1,000,000,000 tokens
    
    constructor() ERC20("Rock", "ROCK") {
        transferOwnership(INITIAL_OWNER);
        _mint(INITIAL_OWNER, FIXED_SUPPLY);
    }

    function addToBlacklist(address user) public onlyOwner {
        _blacklist[user] = true;
    }

    function removeFromBlacklist(address user) public onlyOwner {
        _blacklist[user] = false;
    }

    function isBlacklisted(address user) public view returns (bool) {
        return _blacklist[user];
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        require(!_blacklist[from], "ROCKToken: Sender is blacklisted");
        require(!_blacklist[to], "ROCKToken: Recipient is blacklisted");
        super._beforeTokenTransfer(from, to, amount);
    }
}