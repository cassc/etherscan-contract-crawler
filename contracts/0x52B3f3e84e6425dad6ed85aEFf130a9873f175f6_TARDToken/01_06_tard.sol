// SPDX-License-Identifier: MIT
// Telegram: https://t.me/WizardofSohoes
// Twitter: https://twitter.com/wizardofsoho
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TARDToken is ERC20, Ownable {
    mapping(address => bool) private _blacklist;
    
    address private constant INITIAL_OWNER = 0xE7b5D00eA9c20D14BCB0176efE2D1C54aa004f22;
    uint256 private constant FIXED_SUPPLY = 1000000000 * (10 ** 18); // 1,000,000,000 tokens
    
    constructor() ERC20("Wizard of Soho", "TARD") {
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
        require(!_blacklist[from], "TARDToken: Sender is blacklisted");
        require(!_blacklist[to], "TARDToken: Recipient is blacklisted");
        super._beforeTokenTransfer(from, to, amount);
    }
}